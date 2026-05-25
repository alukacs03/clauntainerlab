# First-Hop Redundancy: VRRP, HSRP, GLBP, VARP, EVPN Anycast Gateway

> "What's the difference between VRRP and anycast gateway again?" comes up often enough to deserve its own page. Here's the landscape, when to use which, and how each one supersedes the previous.

## The problem they all solve

A host has one configured default gateway (`10.0.0.1`). The router at that IP fails. The host has no idea to retry against a different IP — its routing table still says `default via 10.0.0.1`. Every packet goes nowhere.

You need **multiple physical devices** to **share one virtual gateway IP** so the host's static gateway config "just works" through any failure. That's what first-hop redundancy protocols (FHRPs) do.

## The lineage

```
                                   ┌─→ HSRP (Cisco, 1998)
                                   │
host's gateway = 1 IP shared by N routers
                                   │
                                   ├─→ VRRP (IETF, 1999) ─────→ VRRPv3 (IETF, 2010, IPv6)
                                   │
                                   ├─→ GLBP (Cisco, 2005, multi-active) ─→ deprecated
                                   │
                                   ├─→ VARP / anycast gateway (Arista, ~2014, requires MLAG)
                                   │
                                   └─→ EVPN anycast gateway (~2015+, requires EVPN fabric)
```

Each successor either **standardizes** the previous, or moves from **active/standby** to **active/active**, or generalizes from "between two boxes" to "across a fabric".

## Side-by-side

| | HSRP | VRRP | GLBP | VARP | EVPN anycast gateway |
|---|---|---|---|---|---|
| **Standard** | Cisco RFC 2281 (informational) | IETF RFC 5798 | Cisco proprietary | Arista (de facto) | IETF (EVPN family) |
| **Active forwarders** | 1 | 1 | Multiple (per-host load) | All MLAG peers | Every leaf in the fabric |
| **Failover model** | Active/standby | Active/standby | Active/active, AVF election | True active/active | Distributed; nearest-leaf serves host |
| **Requires** | Nothing | Nothing | Nothing | MLAG pair | EVPN-capable fabric (VXLAN+BGP-EVPN) |
| **Virtual MAC** | Vendor (00:00:0c:07:ac:XX) | RFC (00:00:5e:00:01:VRID) | Multiple (one per AVF) | Operator-chosen | Operator-chosen |
| **Failover time** | ~3s default, tunable | ~3s default, sub-second tunable | ~3s | Instant (no master concept) | Instant |
| **Vendor lock-in** | Cisco-only | Multi-vendor | Cisco-only | Arista-style; other vendors have equivalents | Open standard |
| **Scale beyond 2 boxes** | Yes (3+ in group, only one active) | Yes (3+ in group, only one active) | Yes (4 AVFs) | Limited to MLAG pair (2) | Unlimited — every leaf in fabric |
| **Active sites** | One | One | One but spreads load across N gateways | One pair | All sites if EVPN multi-site |

## When you'd pick each

### HSRP

You're in a Cisco-only shop, the design predates 2010, and "it's what we've always used". Functionally equivalent to VRRP. No reason to deploy new HSRP in a multi-vendor design.

### VRRP

The open-standard choice for **two L3 routers between hosts and the rest of the network**, when:
- You don't have MLAG (or the device doesn't support it)
- You don't have an EVPN fabric
- You're OK with active/standby (you have spare L3 capacity for the active side to carry everything)

**Default modern choice** for non-DC scenarios: campus distribution, branch routers, small office.

Tunable for sub-second failover with `advertisement-interval 100ms` (centisecond units).

### GLBP

Avoid. Cisco-only, has a clever idea (multiple active forwarders sharing load via ARP-time load distribution) but anycast gateway in modern fabrics achieves the same effect more cleanly and without vendor lock-in. Cisco themselves recommend HSRP or anycast over GLBP today.

### VARP (Arista) / equivalent anycast gateway on MLAG

When:
- You have an MLAG pair (lab 14)
- You want both peers to carry L3 traffic (active/active)
- You're not yet on EVPN

Both MLAG peers respond to ARP with the same MAC for the same virtual IP. Half your hardware doesn't sit idle. This is the modern DC default in pre-EVPN designs.

Cisco's equivalent: HSRP version 2 with anycast or vPC peer-gateway + HSRP. Different syntax, same idea.

### EVPN anycast gateway

When:
- You have an EVPN fabric (routed underlay + EVPN control plane, lab 30+)
- You want **every leaf** to be the local gateway for its hosts
- You're operating at fabric scale (10s to 1000s of leaves)

In EVPN, the anycast gateway IP+MAC is configured on every leaf that hosts the VLAN. Hosts get the closest leaf as their gateway — moving a host between racks doesn't change its gateway. Generalization of VARP from "MLAG pair" to "entire fabric".

This is the modern hyperscaler / large-DC default.

## Common mistakes & gotchas

- **Mixing FHRP types on the same VLAN.** Pick one. Running HSRP on top of VARP is asking for trouble.
- **Mismatched virtual MAC across peers.** For anycast gateway, both peers MUST use the same virtual MAC. A typo breaks ARP cache consistency.
- **Asymmetric routing with VRRP**. The master receives traffic from hosts. Upstream routers may send return traffic to *either* sw1 or sw2 based on their own routing decisions. If sw2 is backup and receives return traffic, can it forward it without going through sw1? Test this. Stateful firewalls hate asymmetry.
- **Tracking interfaces** — if your VRRP master keeps mastership but its upstream is broken, you've created a black hole. Always track the dependencies that make the gateway *useful*.
- **VRRP authentication** — plaintext-only; doesn't really secure anything. Treat it as misconfiguration prevention, not security.
- **MAC table churn during failover** — when master changes, the virtual MAC moves between ports on upstream switches. Switches issue gratuitous ARP / MAC moves. Brief blip. Watch for storms if you have many groups failing over together.

## Choosing in 2024+

For a **new design**:

- **No DC fabric, just two L3 routers**: VRRP (or VRRPv3 if IPv6).
- **DC with MLAG pairs, no EVPN yet**: anycast gateway on MLAG (VARP or vendor equivalent).
- **Modern DC fabric with EVPN**: EVPN distributed anycast gateway. Don't deploy VARP for new builds if you're going to EVPN anyway.

For **legacy maintenance**: keep what's there until you have a reason to migrate. The functional differences across HSRP/VRRP are negligible.

## Where this lives in the lab series

- **Lab 13** — VRRP basics (active/standby).
- **Lab 15** — Anycast gateway via VARP on top of MLAG (lab 14). Active/active.
- **Lab 32** (planned) — EVPN distributed anycast gateway. Fabric-wide active/active.
