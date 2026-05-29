# Reference Design — Dual-Site DC for The Company

> **What this is.** Not a lab. An architecture document — the kind that gets read on day one by a new engineer to understand the entire network. It assumes you've completed the labs and wants to show how the pieces compose into one cohesive design. Diagrams + design rationale + cross-references back to the labs that taught the components.
>
> **What it isn't.** A vendor-specific reference architecture. The choices here are typical mid-size cloud provider choices ca. 2024-2026: Arista EOS (or equivalent) leaves and spines, EVPN-VXLAN fabric, BGP everywhere, dual sites.

## Goals

The fabric needs to support:

- **Multi-tenant L2 + L3 services** with strong isolation
- **Stretched subnets** between two physical sites (one customer service IP, anywhere)
- **Redundant edge** with multi-homing to two transit ISPs, IXP peering
- **Hosted services** including VPS, managed Kubernetes, managed storage, VoIP
- **Public IPv4 + IPv6** at customer edge, RFC 6598 CGN for residential broadband
- **DDoS posture** with RTBH and upstream scrubbing integration
- **Observability** end-to-end (streaming telemetry, central logging)
- **Automation** end-to-end (NetBox as the intended source of truth, CI/CD pipeline) — note: the hands-on NetBox lab is deferred (it was lab 54, since removed), so treat this source-of-truth layer as **design-only** for now (see [`TODO.md`](../../TODO.md))

Non-goals (deliberately):
- Hyperscaler-tier scale (we're operating in the hundreds of devices, not thousands)
- AI/ML cluster networking (different beast; could be added as a separate POD design)
- Carrier-grade routing for transit-of-last-resort (we are a regional provider, not a Tier-1)

## High-Level Topology

```
       ┌──────────────────────────┐                 ┌──────────────────────────┐
       │     Internet / IXP       │                 │       Site B (DR/Active) │
       │  (transit + peering)     │                 │                          │
       └────────┬─────┬───────────┘                 │   ┌────┐ ┌────┐         │
                │     │                              │   │spine│ │spine│        │
       ┌────────┴┐   ┌┴────────┐                    │   └─┬──┘ └──┬─┘        │
       │  edge-a │   │  edge-b │  (active/active)   │     │ ECMP  │           │
       └────┬────┘   └────┬────┘                    │  ┌──┴──┐ ┌──┴──┐        │
            │             │                          │  │leaf │ │leaf │ ...    │
            │   Site A    │                          │  └──┬──┘ └──┬──┘        │
       ┌────┴─────────────┴────┐                    │     │       │            │
       │     border-leaves     │                    └─────┼───────┼────────────┘
       │  (RTBH origin, ACLs)  │                          │       │
       └────────┬──────────────┘                          │       │
                │ EVPN-Multisite via DCI                 │       │
        ┌───┐ ┌─┴─┐ ┌───┐                                 │       │
        │spine│ │spine│ (EVPN BGP fabric)                 │       │
        └─┬─┘  └─┬─┘                                       │       │
          │ ECMP │                                          │       │
       ┌──┴──┐┌──┴──┐ ┌─────┐ ...                          │       │
       │leaf ││leaf │ │leaf │                              │       │
       └─┬───┘└─┬───┘ └──┬──┘                              │       │
         │      │        │                                  │       │
       hosts (VMs / bare-metal / storage / VoIP / customer edge devices)
```

## Layered View

### Layer 0 — Physical & Cabling

- **Spine ↔ Leaf**: 100G or 400G optical (depending on tier). Each leaf has 2-4 uplinks (one per spine).
- **Leaf ↔ Host**: 10G or 25G. Each host uses 2 NICs to 2 separate leaves (EVPN-MH ESI, lab 33b).
- **DCI (Site-A ↔ Site-B)**: dark fiber if available, otherwise dedicated wavelength (DWDM) from a transit provider. 100G+ depending on east-west demand.
- **OOB management network**: physically separate switches and cabling, dedicated VLAN, console servers (lab 11).
- **Cable database**: source-of-truth system (NetBox or equivalent) tracks every cable. Dedicated curriculum chapter on this is deferred — see `TODO.md`. Cleaning, MTU, optic types: see [`docs/practice/physical-layer.md`](../practice/physical-layer.md).

### Layer 1 — IGP & Underlay

- **Single L3 underlay** routed via OSPF (lab 17/18) OR IS-IS (lab 19b). Choice is taste; we use OSPF for operational familiarity.
- **BFD on all routed links** (lab 19) for sub-second failure detection.
- **Loopbacks** advertised by every node for BGP nexthop reachability.
- **Inter-fabric** unnumbered BGP (lab 28) on transit links if scale demands.

### Layer 2 — Overlay (EVPN-VXLAN)

- **eBGP-EVPN fabric** — every leaf and spine runs its own private ASN (per-device, not a single shared AS). The EVPN address-family is carried over the *same* eBGP sessions as the underlay (lab 27/30). Spines are **not** route reflectors and **not** VTEPs: they relay EVPN routes between leaves with `neighbor … next-hop-unchanged` so the originating leaf's VTEP IP survives as the next-hop. (The classic alternative — iBGP-EVPN with the spines as route reflectors over an IGP underlay, the lab 21 pattern — is noted under "What's deliberately NOT in this reference"; the labs deliberately chose eBGP-EVPN.)
- **VXLAN data plane** (lab 29) for tenant traffic.
- **EVPN Type 2 routes** for MAC/IP learning (lab 30).
- **EVPN Type 5 routes** for L3 services (lab 31), with VRFs per tenant.
- **Anycast gateway** on every leaf for the local subnets (lab 32).
- **EVPN multi-homing** via ESI replaces MLAG (lab 33b) — no peer-link, cleaner failure modes.
- **Stretched subnets** via EVPN multi-site (lab 33) across DCI.

### Layer 3 — Internet Edge

- **Border-leaves** in each site: dedicated leaves that handle:
  - Two transit ISP eBGP sessions (lab 24)
  - One or more IXP peering sessions with route server (lab 34)
  - RPKI ROV inbound (lab 26)
  - BGP route-policy framework (lab 23): bogons, OWN-PREFIX filter, max-prefix
  - Outbound RTBH (lab 40) signaling for DDoS response
  - Per-customer floating-static last-resort for transit-failure cases
- **NAT layer** on edge for private-IP customers (lab 35), CGNAT for residential (lab 36).
- **IPv6** dual-stack everywhere; native IPv6 to customers (lab 37). For IPv6-only customer segments reaching IPv4-only services, **NAT64/DNS64 runs on a dedicated translator** (Jool/Tayga on Linux, or a vendor NAT64 appliance) — it is **not** an EOS data-plane feature, and cEOS has no NAT64 implementation (lab 38 is conceptual on cEOS).

### Layer 4 — Services

- **Anycast services** (DNS, hosted services) via lab 39 pattern.
- **Customer load balancing** via either L4 ECMP (lab 44) or third-party LB.
- **VoIP** with QoS (lab 42, 43).
- **Storage networking** as a dedicated VLAN + jumbo MTU (lab 46); PFC/ETS on production-tier (lab 47).
- **Per-tenant storage QoS** (lab 48).

### Layer 5 — Security

- **L2 hardening**: STP protections (lab 05), port security, DHCP snooping + DAI + IPSG (lab 06, 07).
- **Mgmt-plane**: separate VRF (lab 08), TACACS+ AAA (lab 09), syslog + NTP baseline (lab 10), OOB (lab 11).
- **L3 edge**: mgmt-plane ACL + CoPP (lab 41).
- **Edge filtering**: per-tenant rate-limit (policer pattern from lab 48); per-tenant ACLs and prefix filtering built from the route-policy/ACL constructs in lab 23 (route-policy) and lab 41 (mgmt-plane ACL).
- **DDoS posture**: RTBH (lab 40), upstream scrubbing integration.
- **Customer perimeter**: optional VPN (lab 45) for partner connections.

### Layer 6 — Observability

- **Streaming telemetry** via gNMI (lab 49) on every device.
- **Collector + TSDB + viz**: gnmic + Prometheus + Grafana (lab 50).
- **Central syslog** (lab 10) with alert-tier classifications.
- **Net-flow / sFlow** for traffic analysis (mentioned in lab 57).
- **SPAN/mirror** available on every fabric switch for ad-hoc capture (lab 57).
- **Alerting tiers** per [`docs/practice/monitoring-and-alerting.md`](../practice/monitoring-and-alerting.md).

### Layer 7 — Operations

- **Source of truth**: NetBox (or equivalent IPAM/CMDB). Sites, racks, devices, interfaces, IPs, VLANs, VRFs, cables, circuits. _**No hands-on lab yet — design-only.** The dedicated curriculum chapter is deferred (it was lab 54, since removed); see [`TODO.md`](../../TODO.md). Until it lands, NetBox is an architectural intent here, not a taught/validated component, even though the Address Plan above assumes such a system manages allocations._
- **Config management**: Ansible drives configs from the source-of-truth (lab 52).
- **CI/CD**: every change goes through a pipeline (lab 53). Lint → validate → stage-deploy → stage-test → prod-deploy (manual gate) → smoke-test.
- **Backup & DR**: daily backup to git (lab 55); ZTP-driven replacement procedure.
- **Hitless upgrades**: rolling per-pair upgrade procedure (lab 56).
- **Incident response**: documented runbooks (lab 58 + [`docs/practice/runbooks.md`](../practice/runbooks.md)); blameless postmortems per [`docs/practice/incident-response.md`](../practice/incident-response.md).
- **Capacity planning**: quarterly review using lab 59's methodology.
- **Change communication**: stakeholder-tiered comms per [`docs/practice/change-communication.md`](../practice/change-communication.md).

## Address Plan

```
10.0.0.0/8        — Internal (RFC 1918)
  10.0.0.0/16      — Underlay (point-to-point /30s and loopbacks)
  10.10.0.0/16     — Customer/tenant L3 (VXLAN-routed, anycast gateway)
  10.50.0.0/16     — Storage VLANs (per-tenant, /24 each)
  10.99.0.0/16     — Management (mgmt VRF, OOB)

100.64.0.0/10     — RFC 6598 CGN shared address space

198.51.100.0/24   — Public IPv4 (example only; one /24 out of our RIR-assigned /22)
                    Subdivided into customer-facing /29s, /28s

2001:db8:1::/48   — Public IPv6 customer allocations (example)
2001:db8:f::/48   — Infrastructure (loopbacks, link-local)
```

> Both /48s are carved from the `2001:db8::/32` documentation prefix (RFC 3849) and are example-only; real deployments use RIR-assigned space. IPv6 text follows RFC 5952 (lowercase hex, no leading zeros).

## ASN Layout

eBGP-EVPN means **one private ASN per device** — there is no single shared spine AS. The labs build it like this (lab 27 README, lab 30/33 solutions), and the ranges below keep spines and leaves in non-overlapping bands so they never collide:

```
65100, 65200    — Spines, one ASN per spine (Site A: 65100 / 65200; lab 27/30/33)
65001-65099     — Leaves, one private ASN per leaf (eBGP underlay; lab 27, 28)
                  (e.g. leaf1 = 65001, leaf2 = 65002, …)
64512-64999     — Reserved per-tenant private AS (RFC 6996 private range)

[Public AS for transit/peering] — assigned by RIR (lab 25)
```

> Note: this is the **per-device** eBGP-EVPN scheme the labs actually use. Don't reuse a single number for "all spines" — that's the iBGP-RR model (lab 21), which this fabric does not adopt. Also keep these internal private ASNs distinct from any AS number that appears in *example community values* elsewhere in the curriculum (e.g. lab 40's RTBH community `65000:666`, where `65000` stands in for the **upstream provider's** AS, not The Company's).

## Tenant Service Tiers

| Tier | Bandwidth | Storage QoS | Network SLA | Multi-site |
|---|---|---|---|---|
| Bronze | up to 1 Gbps | best-effort | 99.9% | site-A only |
| Silver | up to 10 Gbps | premium QoS | 99.95% | optional Site-B replica |
| Gold | up to 25 Gbps | guaranteed IOPS | 99.99% | stretched DCI |

QoS tier maps to:
- DSCP marking class (lab 48)
- Storage VLAN PFC enablement (lab 47)
- BGP community on egress routing decisions
- Monitoring/alerting tier

## Failure Modes & Blast Radius

| Failure | Customer Impact | Recovery |
|---|---|---|
| Single leaf uplink | None (ECMP) | Cable/optic replacement |
| Single spine | Reduced capacity (50%) | Hardware replacement |
| Whole leaf | Tenants on that leaf only | Lab 55 procedure |
| Whole spine | Reduced capacity; multi-leaf reconvergence | Hardware replacement |
| Single transit ISP | Path failure; alternate ISP carries | Auto-failover via BGP |
| Border-leaf | Edge capacity halved | Hardware replacement |
| Whole site (Site A loss) | Gold survives via stretched DCI on Site B; Silver down unless it opted into a Site-B replica; Bronze (site-A-only) down entirely. Aggregate capacity reduced ~50%. | DCI/active-active failover for Gold; Silver replicas promoted where configured; Bronze recovered by rebuild at the surviving site (manual or automated) |
| DCI link | Stretched subnets fragmented | Backup path or service downgrade |

Each row corresponds to a section in the failure playbook (lab 58).

## What's deliberately NOT in this reference

- **iBGP-EVPN with spines as route reflectors over an IGP underlay** (the lab 21 pattern). It's the most common alternative to eBGP-EVPN and a perfectly valid design — but the labs deliberately chose the eBGP-EVPN model (per-device ASNs, spine `next-hop-unchanged` relay; see Layer 2), so this reference follows that. If you ever migrate to iBGP-RR, that's a whole-layer change worthy of an ADR.
- **Specific vendor models** (we describe the role, not the SKU). NetBox tracks actuals.
- **Pricing** (the architecture is independent of which vendor wins the RFP)
- **Detailed capacity numbers** (workload-specific; comes from lab 59 analysis per project)
- **Migration plan** (a separate per-project doc; uses the MOP template)

## How to read this

For a new engineer (Year 1): skim the High-Level Topology, get comfortable with the layered view, find which labs taught each piece. Don't try to memorize.

For an architect (Year 3+): use as a starting point. Adapt to your scale, your vendor, your customer base. The pattern is more durable than the specifics.

For management: this document, with the failure-mode table, is the artifact that explains "what we have and what protects us."

## Maintenance

This document is updated when:
- A major design decision is made (record the why; consider an ADR per [`docs/practice/adr.md`](../practice/adr.md))
- A whole layer changes (e.g., we move from OSPF to IS-IS)
- A new chapter of labs lands that extends the design

It is **not** updated for routine config changes — NetBox tracks those.
