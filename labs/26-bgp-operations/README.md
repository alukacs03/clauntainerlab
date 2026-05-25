# Lab 26 — BGP Operations

> **Format:** Hands-on. Two routers, one eBGP session. Layer on the operational hardening every production session should have: authentication, TTL security, BFD-driven fast convergence, maximum-routes, graceful restart. Reference answer in [`solutions/`](solutions/).

## Real-world scenario

You inherited a BGP-running network. Three issues uncovered in the first audit:

- **No password on BGP sessions.** Anyone on a transit link could inject a TCP RST or attempt session hijack. Not exploited yet — but no defense either.
- **No maximum-prefix limit.** Last year a peer accidentally announced ~800,000 prefixes for 4 minutes due to a route-map bug. Your edge router's RIB ballooned, control-plane CPU pegged, BFD timeouts started misfiring, customers noticed.
- **Sessions take 90 seconds to recover** when a link is broken. Default BGP hold timer is 180s; even with hello tuning, it's 30+s. Voice traffic notices.

Plus you want every router to **survive a control-plane restart** without dropping its existing routes for the 90 seconds it takes BGP to re-establish — that's **graceful restart**.

This lab applies the modern operational hardening profile: a config block you should add to every BGP-speaking router from day one.

## Goal

By the end you should be able to answer:

- What does `neighbor X password` actually do?
- What's **TTL security**, and why is it the cheap defense against off-link spoofing?
- How does **BFD-driven session fall-over** speed up BGP convergence?
- What's **`maximum-routes`** and when does it save you?
- What's **graceful restart**, and what's the difference between **GR Restarter** and **Helper**?
- What's the BGP operator's daily-show-command checklist?

## Topology

```mermaid
graph LR
    h1[h1] --> sw1[sw1<br/>AS 65001] ==eBGP== sw2[sw2<br/>AS 65002] --> h2[h2]
```

Two routers, eBGP, two host LANs. The same hardening principles apply on iBGP too — practice here, deploy everywhere.

## Theory primer

### Password authentication

```
neighbor 192.168.12.2 password 0 <shared-secret>
```

Adds an **MD5 signature** to every TCP packet of the BGP session. Both peers must agree on the password. Without it, anyone who can route a TCP packet to port 179 of your router could inject session-disruption packets (RSTs, malformed segments).

Limitations:
- MD5 is weak against modern attackers (collisions, key-recovery in some scenarios).
- Modern replacement: **TCP-AO (RFC 5925)** with SHA-256 or similar. Use if your platform supports it.

Even MD5 is way better than nothing. Always set it on every BGP session.

### TTL security (GTSM — Generalized TTL Security Mechanism)

```
neighbor 192.168.12.2 ttl maximum-hops 1
```

For a directly-connected eBGP session, the peer is exactly 1 hop away. BGP-OPEN packets sent over multiple hops by an attacker arrive with TTL < 255 (because the attacker doesn't get to set the initial TTL exactly). TTL security drops any packet whose TTL doesn't match the expected hop count.

For directly-connected eBGP: `maximum-hops 1` (only accept packets with TTL = 255, meaning the sender was 1 hop away).

For multi-hop eBGP (e.g., between loopbacks): `maximum-hops <N>` where N is the actual hop count.

For iBGP between loopbacks: same idea with the appropriate N.

Cheap, automatic, blocks a class of off-link attacks. Always on.

### BFD-driven fall-over

```
neighbor 192.168.12.2 fall-over bfd
```

When BFD declares the underlying link dead (lab 19 — ~900ms with default tuning), BGP **immediately** tears down the session instead of waiting for the BGP hold timer (default 180s, ≥30s even with tuning). Combined with BFD's sub-second detection, BGP reconvergence becomes sub-2-seconds end-to-end.

Requires BFD to be configured (`bfd interval ... min-rx ... multiplier ...`). Both peers must have BFD configured for the session to come up at BFD-protected speeds.

### maximum-routes

```
neighbor 192.168.12.2 maximum-routes 50
```

If the peer announces more than 50 routes, the session drops. Default behavior: peer is shut, manual reset required (some platforms auto-recover after a timer).

Why this matters: a misbehaving neighbor (or a misconfigured route-map on their side) might announce far more prefixes than expected. Without a cap, your RIB balloons, CPU spikes, BFD misfires, customers notice.

Set per-neighbor based on **expected** prefix count + headroom (e.g., 50% more). For customers: agree on their announced count and cap there. For peers: based on registered IRR data. For transits: full-table size (~1M today) plus generous headroom.

A common subtlety: some platforms have a "warning" mode that just logs above a threshold without dropping the session. Use it for production transparency.

### Graceful restart

A modern router has its BGP process and its FIB in different software components. When the BGP process restarts (software bug, config commit reload, etc.), the FIB can stay populated even while BGP re-establishes — packets keep flowing.

For this to work between neighbors, BOTH sides must support and signal **graceful restart capability** during session OPEN. When a peer goes through a restart:

- **Restarter** — the router going through restart. Tells peer "I'm restarting, please hold on to my routes for X seconds (restart-time)."
- **Helper** — the peer. Keeps the routes marked "stale" but still in the FIB. If the restarter comes back within `stalepath-time`, routes are re-validated. If not, they're flushed.

Result: data plane keeps working even during control plane restarts. Critical for hitless software upgrades.

```
router bgp 65001
   graceful-restart restart-time 120
   graceful-restart stalepath-time 360

   address-family ipv4
      neighbor X graceful-restart
```

### Operational reflex commands

When something's wrong, run these in order. They get you 80% of the way to the answer.

```
show ip bgp summary                ! quick state of every session
show ip bgp neighbors X            ! detailed session info
show ip bgp                        ! RIB
show ip route bgp                  ! best paths
show ip bgp 1.0.0.0/24             ! specific route
show ip bgp neighbors X advertised-routes
show ip bgp neighbors X received-routes
show bfd peers                     ! if BFD is in play
show ip bgp regexp 64512           ! routes whose AS-path matches
show logging | include BGP         ! recent events
```

For changes:

```
clear ip bgp X soft in/out         ! re-apply policy without dropping TCP
clear ip bgp X                     ! hard reset (drops TCP) — avoid in production
clear bgp ipv4 unicast X soft in   ! some platforms
```

## Your task

On both sw1 and sw2:

1. Configure global BFD (`bfd interval 300 min-rx 300 multiplier 3`).
2. On the BGP neighbor:
   - `password 0 LabSharedSecret123` (must match on both sides).
   - `ttl maximum-hops 1` (directly connected eBGP).
   - `fall-over bfd`.
   - `maximum-routes 50`.
3. Under `router bgp`: graceful-restart with restart-time 120, stalepath-time 360.
4. Under `address-family ipv4`: `neighbor X graceful-restart`.
5. Verify everything is in effect.

## Hints

```
bfd interval <ms> min-rx <ms> multiplier <n>

router bgp <asn>
   graceful-restart restart-time <s>
   graceful-restart stalepath-time <s>
   neighbor X password 0 <secret>
   neighbor X ttl maximum-hops <n>
   neighbor X fall-over bfd
   neighbor X maximum-routes <n>
   address-family ipv4
      neighbor X graceful-restart
```

## Deploy

```bash
cd ~/containerlab/labs/26-bgp-operations
sudo containerlab deploy
```

## Verification

### 1. BFD session up

```bash
docker exec -it clab-bgp-operations-sw1 Cli
show bfd peers
```

Should show one BFD session, state `Up`.

### 2. BGP session uses BFD

```
show ip bgp neighbors 192.168.12.2 | include "fall over"
```

Should mention "BFD" as the fall-over mechanism.

### 3. Password is set (mismatch demo)

On sw1, change the password to something different:

```
configure terminal
  router bgp 65001
    neighbor 192.168.12.2 password 0 WrongPassword
```

Within seconds the session drops. Logs show MD5 failure. Restore the matching password.

### 4. TTL security

Try to send a BGP OPEN from a router 2 hops away (we don't have that topology, but you can verify the config is in place):

```
show ip bgp neighbors 192.168.12.2 | include TTL
```

Should show `Hops: 1`.

### 5. maximum-routes — induce the limit

On sw2 temporarily, advertise more than 50 prefixes. Easy: add a bunch of static null0 routes and `network` them:

```
configure terminal
  ip route 100.0.0.0/24 Null0
  ip route 100.0.1.0/24 Null0
  ! ... add many ...
```

Or use a script. Once sw2 announces > 50 to sw1, sw1 shuts the session. Log line: `BGP-4-MAXROUTES-LIMIT-REACHED`. To re-enable: lower the count, or `clear ip bgp <peer>`.

### 6. Convergence speed

With sustained ping between h1 and h2:

```bash
docker exec clab-bgp-operations-h1 ping 10.2.0.10
```

In another terminal, simulate a link issue without dropping the interface — apply a deny-all ACL temporarily:

```
configure terminal
  ip access-list standard BLACKHOLE
    deny any
  interface Ethernet2
    ip access-group BLACKHOLE in
```

With BFD + fall-over bfd: ping pause should be ~1s. Without (default BGP hold timer 180s, advert 60s): would be 30–90s. BFD makes BGP nearly as fast as the underlying link state.

Remove the ACL.

### 7. Graceful restart capability

```
show ip bgp neighbors 192.168.12.2 | include capability
```

Should mention `graceful restart`. Capability is negotiated at OPEN time.

To actually test GR, restart the BGP process on sw1 (some platforms allow `clear ip bgp process`). The FIB should keep routes alive while the session re-establishes.

### 8. Operational reflex — full playbook

Run each in order:

```
show ip bgp summary
show ip bgp neighbors 192.168.12.2
show ip bgp
show ip bgp 10.2.0.0/24
show ip bgp neighbors 192.168.12.2 received-routes
show ip bgp neighbors 192.168.12.2 advertised-routes
show bfd peers
show logging | include BGP
```

Get muscle memory for this sequence. In real outage, this is the first 60 seconds of every BGP-related incident.

## Peek at solution

- [`solutions/sw1.cfg`](solutions/sw1.cfg), [`solutions/sw2.cfg`](solutions/sw2.cfg)

## Concepts cheat-sheet

- **password** — MD5 (or TCP-AO) on BGP TCP. Always set.
- **TTL security** — drop BGP packets with unexpected TTL. Defense against off-link injection.
- **fall-over bfd** — tear down session when BFD declares neighbor dead. Sub-second convergence.
- **maximum-routes** — cap how many prefixes a neighbor can announce. Protects against runaway leaks.
- **Graceful restart** — keep FIB during BGP process restart. Hitless software upgrades.
- **Operational reflex** — daily `show ip bgp summary`; first 60s of every incident.

## Production hardening checklist

Every BGP-speaking router should have:

- ✅ Per-neighbor password / TCP-AO
- ✅ TTL security (`ttl maximum-hops`)
- ✅ BFD on the underlying link + `fall-over bfd`
- ✅ `maximum-routes` per neighbor, sized appropriately
- ✅ Graceful restart configured + activated per AF
- ✅ Inbound + outbound route-maps (labs 23, 24, 25)
- ✅ Neighbor `description` filled in
- ✅ `update-source` to a loopback for iBGP
- ✅ `send-community` explicitly enabled where needed
- ✅ Sourced from management VRF if running in OOB / mgmt VRF context

## What's missing (deliberately)

- **TCP-AO (RFC 5925)** — modern replacement for MD5; platform support varies. Use when available.
- **BGP dampening** — rarely recommended now (too coarse). Mention only.
- **Route-server / RPKI-validator-driven policy** — touched in lab 25; would need real validator setup for a hands-on demo.
- **Cumulus/FRR specifics** — same concepts, different syntax.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
