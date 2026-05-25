# Lab 16 — Static Routing & Floating Statics

> **Format:** Hands-on. Two L3 switches with primary and backup paths. Your job: configure static routes plus a floating static to drive failover. Reference answer in [`solutions/`](solutions/).

## Real-world scenario

You have two L3 switches connected by two cables — one is a fast direct link (your normal path), the other is a slower backup (maybe through a different patch panel, or a longer fiber run). You want the network to use the fast link normally and only fall back to the slow link if the fast one breaks.

Static routing is the simplest way to express this: configure a primary static route via the fast next-hop, then a **floating static** with a higher administrative distance via the backup next-hop. The floating route sits dormant in the config; it only enters the FIB when the primary route's next-hop becomes unreachable.

You'll encounter this exact pattern when:
- The primary path is a dynamic routing protocol and you want a static last-resort.
- You have two ISP uplinks and a static default via the secondary.
- You're building a deterministic backup path you don't want dynamic protocols to second-guess.

## Goal

By the end you should be able to answer:

- What's **administrative distance (AD)**, and how does the router pick between routes from different sources?
- What is a **floating static**, and how does it interact with the routing table?
- Why does the route disappear from the FIB when the next-hop becomes unreachable, but not when the next-hop is still reachable but the *path beyond* is broken?
- When do you NOT want a static route — i.e., when does dynamic routing earn its keep?

## Topology

```mermaid
graph LR
    h1[h1<br/>10.10.10.10] --> sw1
    sw1 ==Et2 primary==.192.168.12.0/30== sw2
    sw1 -.Et3 backup..192.168.13.0/30.- sw2
    sw2 --> h2[h2<br/>10.20.20.10]
```

Two L3 switches, two parallel /30 transit links, two host LANs at the edges.

## Theory primer

### Administrative distance

When multiple routing sources offer the same destination, **AD breaks the tie**. Lower AD wins.

| Source | Default AD |
|---|---|
| Connected | 0 |
| Static | 1 |
| eBGP | 20 |
| OSPF | 110 |
| iBGP | 200 |

A static route with default AD 1 beats OSPF (AD 110) for the same prefix. By bumping a static route's AD above the dynamic protocol's, you make it a **fallback** — only used if the protocol's route disappears.

AD is **per route source**, not per route. Within one source (e.g. OSPF), metric breaks ties.

### Floating statics

A "floating static" is just a static route with a deliberately raised AD. Two static routes to the same prefix:

```
ip route 10.20.20.0/24 192.168.12.2          ! default AD 1
ip route 10.20.20.0/24 192.168.13.2 200      ! AD 200, "floats" above
```

Only the AD-1 route is installed in the FIB while its next-hop is reachable. If 192.168.12.2 stops being reachable (next-hop ARP failure, interface down), the route is removed; the AD-200 route gets installed.

### "Next-hop reachable" — what counts

A static route stays installed as long as the **next-hop is reachable on a directly connected interface**. Specifically:

- If the next-hop IP is in a connected subnet whose interface is up, ARP succeeds, route stays.
- If the interface goes down (admin or physical), connected route disappears, next-hop becomes unreachable, static is removed.
- If the interface stays up but the device beyond it (e.g., sw2 reboots silently without the link going down — rare in modern Ethernet but possible on virtual links) — ARP eventually fails, the next-hop's ARP entry ages out, static is removed.

What static routing does NOT detect:
- The path BEYOND the next-hop is broken (next-hop is up but it can't reach the destination).
- Loops or black-holes downstream.

For these, you need **dynamic protocols + reachability checks** (BFD in lab 19) or **IP SLA tracking**.

### Equal-cost multipath with statics

Two static routes with the same AD AND same metric to the same prefix → ECMP. Traffic is hashed across both. We don't use ECMP here (we want active/standby), but it's a one-line difference:

```
ip route 10.20.20.0/24 192.168.12.2       ! primary
ip route 10.20.20.0/24 192.168.13.2       ! same AD/metric → ECMP, not failover
```

If you want failover, use floating; if you want load-spreading, use equal-AD.

### When to use static vs dynamic

**Static** is great when:
- The path is unlikely to change (point-to-point links, stub branches).
- You want deterministic behavior.
- You want to override or last-resort a dynamic protocol.

**Dynamic** earns its keep when:
- Multiple paths exist and they can change.
- You have many devices (manual maintenance doesn't scale).
- You need to react to failures across the topology, not just adjacent links.

For a single pair of switches with predictable wiring, statics are fine. For 30+ devices, OSPF/BGP saves your life.

## Your task

On sw1 and sw2:

1. Add a static route to the *other* switch's host subnet via the primary next-hop (Et2 transit IP).
2. Add a floating static to the same destination via the backup next-hop (Et3 transit IP), AD 200.
3. Verify traffic uses the primary path.
4. Shut the primary interface. Verify failover to backup.
5. Restore. Verify primary comes back as preferred.

## Hints

```
ip route <destination> <next-hop>             ! default AD 1
ip route <destination> <next-hop> <AD>        ! custom AD (floating if > 1)
```

Verification:

```
show ip route
show ip route 10.20.20.0/24
show ip route static
```

## Deploy

```bash
cd ~/containerlab/labs/16-static-routing
sudo containerlab deploy
```

## Verification

### 1. Confirm baseline failure (before static)

```bash
docker exec clab-static-routing-h1 ping -c 2 10.20.20.10
```

❌ No route. sw1 has no idea how to reach 10.20.20.0/24.

### 2. Add the primary static, retest

After applying the AD-1 static on both sides:

```bash
docker exec clab-static-routing-h1 ping -c 3 10.20.20.10
```

✅. On sw1:

```bash
docker exec -it clab-static-routing-sw1 Cli
show ip route 10.20.20.0/24
```

You should see the route via 192.168.12.2 (primary), AD 1.

### 3. Add the floating static, retest

```
ip route 10.20.20.0/24 192.168.13.2 200
```

```
show ip route 10.20.20.0/24
```

Only the AD-1 (primary) route is shown — the floating route is in the config but not installed in the FIB because the primary is healthy.

### 4. Failover demo

Sustained ping:

```bash
docker exec clab-static-routing-h1 ping 10.20.20.10
```

Shut the primary on sw1:

```
configure terminal
  interface Ethernet2
    shutdown
```

Ping pauses ~1 sec then resumes. On sw1:

```
show ip route 10.20.20.0/24
```

Now via 192.168.13.2, AD 200. The floating route became active.

Restore:

```
configure terminal
  interface Ethernet2
    no shutdown
```

After ~2 sec, the primary route returns, takes priority again.

### 5. The "next-hop UP but path BROKEN" failure mode

Static routing's blind spot. Bring up Et2 but break a downstream link:

```bash
docker exec -it clab-static-routing-sw2 Cli
configure terminal
  interface Ethernet1
    shutdown
```

(This kills h2's segment, but sw1's static route to 10.20.20.0/24 stays installed because the next-hop 192.168.12.2 is still reachable.)

Ping fails. Static routing has no idea — it sees a healthy next-hop. This is what BFD (lab 19) + dynamic protocols + IP SLA track-and-decrement-priority patterns solve.

Restore:

```
interface Ethernet1
  no shutdown
```

## Peek at solution

- [`solutions/sw1.cfg`](solutions/sw1.cfg), [`solutions/sw2.cfg`](solutions/sw2.cfg)

## Concepts cheat-sheet

- **Administrative Distance (AD)** — preference between route sources; lower wins. Static = 1, OSPF = 110, iBGP = 200, eBGP = 20.
- **Floating static** — static route with deliberately raised AD. Stays out of the FIB until the lower-AD route disappears.
- **Next-hop reachability** — static route is installed only while its next-hop IP is reachable on a directly connected interface. Doesn't detect failures beyond the next-hop.
- **ECMP** — equal AD + equal metric → multiple paths active in the FIB, traffic hashed across.
- **`ip route` is the universal command** across most platforms. Syntax differs slightly between vendors.

## Operational tips

- **Always document your static routes** in the config with descriptions/comments. Three months later you won't remember why `ip route 0.0.0.0/0 1.2.3.4 200` exists.
- **Avoid static routes for prefixes that also come from dynamic protocols** unless you have a clear reason (e.g. last-resort). Otherwise debugging is "which one is winning today?"
- **Watch the next-hop interface** — pointing a static at an interface (`ip route 10.0.0.0/24 Ethernet1`) instead of an IP behaves differently for ARP — usually want IP for routed paths.
- **Floating statics over dynamic protocols** — set AD above the protocol's. For OSPF, ≥110. For iBGP, ≥200. For "above everything", ≥255 (effectively "never use unless I tell you").
- **Don't use AD 255** for floating statics — at 255 the route is treated as "unreachable forever" and will never enter the FIB.

## What's missing (deliberately)

- **`ip sla` tracking** — measure reachability of remote IPs and modify route eligibility; covered in BGP/multihoming labs.
- **Recursive routes** — `ip route 10.0.0.0/8 1.1.1.1` where `1.1.1.1` itself is reachable via another route. Works, but adds debugging complexity. Use carefully.
- **VRF-aware statics** — `ip route vrf MGMT ...`. Same syntax with VRF specifier.
- **IPv6 statics** — `ipv6 route ...`. Same concept.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
