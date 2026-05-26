# Lab 40 — DDoS Mitigation (RTBH)

> **Format:** Hands-on. Edge router signals to upstream "drop all traffic to this victim IP" via BGP RTBH (Remote-Triggered Black Hole). Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 7 · Senior · Year 4. A customer of The Company gets DDoS'd at 3 AM. The volumetric attack is saturating your inbound transit links. You can't filter the attack inside your network — it's already eating your pipe before it gets to you. You need the **upstream** to drop the traffic before it reaches you. RTBH is how. See [`STORY.md`](../../STORY.md).

## Real-world scenario

Customer at `198.51.100.10` is under a 50 Gbps volumetric DDoS attack. Your transit pipe is 10 Gbps. The attack saturates the link; every other customer's traffic is collateral damage.

You can't filter at YOUR edge because the traffic already arrived. The fix: tell the upstream (your transit provider) to drop traffic to the victim IP **at their edge**, before it reaches your link. That's **RTBH (Remote-Triggered Black Hole)** — RFC 5635.

Mechanism:
- You announce a /32 of the victim IP to the upstream via BGP
- You tag the announcement with a special "blackhole" community that the upstream recognizes (e.g., `65000:666`)
- The upstream's policy rewrites the next-hop of any RTBH-tagged announcement to a discard interface
- Their edge then drops ALL traffic to that /32 — at line rate, in hardware
- Your pipe is freed; the victim is offline but the rest of your network is safe

It's a tactical sacrifice: the attacked IP is down, but everyone else stays up.

## Goal

- Understand RTBH conceptually
- Configure customer-side RTBH announcement (the most common use case)
- Recognize when RTBH is right vs when more sophisticated mitigation is needed

## Theory primer

### RTBH (Remote-Triggered Black Hole)

Customer-triggered: you (the customer) signal to your upstream to drop traffic. Your prefix; your decision.

Provider-triggered: less common; provider's NOC signals their own routers when they detect attacks against you.

Most ISPs publish a BGP community their customers can use. Common conventions:
- `<upstream-AS>:666` — RTBH (blackhole the entire prefix)
- `<upstream-AS>:777` — RTBH source-based (drop traffic FROM a source, not TO a destination)

Per-ISP details vary; check their customer documentation.

### Trade-offs

- **Effective**: attack dropped at provider edge; your network safe
- **Coarse**: drops ALL traffic to the target IP, including legitimate
- **Reversible**: withdraw the BGP announcement; service resumes
- **Limited by provider**: only works if your upstream supports it (most major Tier-1s do)
- **One-IP-at-a-time**: doesn't scale to attacks spread across many destination IPs

### When RTBH is not enough

- **Application-layer DDoS** (Slowloris, HTTP request floods): need WAF, not network blackhole
- **Distributed attack across many targets**: blackholing 100 IPs = 100 services down
- **Critical service that can't be offline**: need scrubbing service instead

### Alternatives

- **BGP Flowspec (RFC 8955)**: more granular than RTBH — specify port, protocol, source IP, drop or rate-limit. Some ISPs support customer flowspec; less common than RTBH.
- **DDoS scrubbing services** (Cloudflare Magic Transit, Arbor Cloud, Akamai Prolexic): traffic redirected via BGP to a scrubbing center, cleaned, returned. Expensive but keeps service up.
- **Upstream announcement of a more-specific cleaner-path**: route legitimate traffic through scrubbing while attack continues elsewhere.

## Your task

1. Configure outbound BGP policy on `edge` that tags announcements within your `198.51.100.0/24` range with community `65000:666` (the upstream's RTBH community).
2. Announce `198.51.100.10/32` (the victim IP under attack) with this tag.
3. Verify: upstream receives the announcement, applies RTBH (next-hop rewrite), and drops traffic to that IP.

In the lab, the "attack" is simulated by the attacker host pinging the victim. Without RTBH: traffic reaches the victim. With RTBH: traffic dropped at the upstream.

## Verification

### Before RTBH
```bash
docker exec clab-ddos-mitigation-attacker ping -c 3 198.51.100.10
```
✅ — attacker can reach victim.

### Apply RTBH for the victim
On `edge`, the route-map already exists in the solution. You need to actually announce the /32:

```
ip route 198.51.100.10/32 Null0   ! force the /32 into the RIB

router bgp 65001
   address-family ipv4
      network 198.51.100.10/32
```

This creates the /32 in your BGP RIB, which is then tagged outbound with `65000:666` by the route-map.

On the `upstream`:
```
show ip bgp 198.51.100.10/32
```

Should show the route with next-hop rewritten to `192.0.2.1` (the discard next-hop).

```
show ip route 198.51.100.10/32
```

Should show: route via `Null0` (via the 192.0.2.1 discard next-hop). Traffic dropped here.

### After RTBH
```bash
docker exec clab-ddos-mitigation-attacker ping -c 3 198.51.100.10
```
❌ — packets dropped at upstream. Victim is "offline" from attacker's perspective.

But — the rest of `198.51.100.0/24` still works:
```bash
docker exec clab-ddos-mitigation-attacker ping -c 3 198.51.100.20
```
(Assuming `.20` exists — in this lab only `.10` exists, but conceptually the rest of the /24 is unaffected.)

### Recovery
Withdraw the /32 announcement (or remove the `network` statement). RTBH lifts within seconds. Service resumes.

## What's missing (deliberately)

- **Source-based RTBH (S-RTBH)**: drops traffic from specific sources, leaves destination reachable
- **BGP Flowspec deployment** — significantly more involved
- **Integration with DDoS scrubbing services** (Cloudflare, Arbor, etc.)
- **Automated RTBH triggering** from monitoring detection systems
- **uRPF + RPF checks** at the edge (complementary defense)

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
