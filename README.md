# Containerlab Labs

A personal networking learning journey using [containerlab](https://containerlab.dev), Arista cEOS, and Claude as a study companion.

## What this project is

The goal is to learn networking concepts — VLANs, routing, redundancy, switching internals — on systems that look and feel like the real thing, not on toy abstractions. Containerlab gives us multi-node topologies of actual NOS images (primarily **Arista cEOS** here) running as containers, so the CLI, config style, and behavior match what you'd encounter on real production gear.

Each lab is built as a **hands-on exercise**, not a demo: the starter configs only get the devices booting, and the learner builds the actual configuration themselves, guided by a theory primer and a task spec in the lab README. A reference solution is provided in `solutions/` for after you've tried — peek when stuck, compare when done.

The whole curriculum is a single **continuous story**: you're a fresh-grad junior engineer at a small hosting company on day one, and by the end of the labs you've grown into a senior DC architect at a regional cloud provider. Each lab is a chapter in that arc. See **[`STORY.md`](STORY.md)** for the full narrative — read it once for context, then dive into the labs.

Claude (Claude Code, specifically) is used throughout to design the labs, explain concepts in the READMEs, and help debug when something doesn't behave as expected.

## Setup

Labs run on a dedicated VM on a Proxmox server. See [`docs/vm-setup.md`](docs/vm-setup.md) for VM provisioning, Docker + containerlab installation, and the manual Arista cEOS image import procedure.

## Lab Index

| # | Lab | Topic | Status | Reviewed |
|---|-----|-------|--------|----------|
| 01 | [vlan-basics](labs/01-vlan-basics) | Access ports, trunks, 802.1Q tagging | Ready | ✅ |
| 02 | [inter-vlan-svi](labs/02-inter-vlan-svi) | Inter-VLAN routing with SVIs | Ready | — |
| 03 | [trunk-deep-dive](labs/03-trunk-deep-dive) | Native VLAN, allowed-list hygiene, VLAN hopping | Ready | — |
| 03b | [lldp-and-discovery](labs/03b-lldp-and-discovery) | LLDP — "what's on the other end of this cable?" daily reflex | Ready | — |
| 04 | [stp-rstp](labs/04-stp-rstp) | Root election, port roles, RSTP convergence | Ready | — |
| 05 | [stp-protections](labs/05-stp-protections) | PortFast, BPDU Guard, Root Guard | Ready | — |
| 06 | [port-security-storm-control](labs/06-port-security-storm-control) | MAC limits, sticky learning, broadcast/multicast storm control | Ready | — |
| 07 | [l2-security-trifecta](labs/07-l2-security-trifecta) | DHCP snooping + DAI + IP Source Guard | Ready | — |
| 07b | [qinq-tunneling](labs/07b-qinq-tunneling) | QinQ / 802.1ad — customer VLAN structure tunneled inside provider S-VLAN | Ready | — |
| 08 | [management-vrf](labs/08-management-vrf) | Logical separation of mgmt from data via VRF | Ready | — |
| 09 | [aaa-tacacs](labs/09-aaa-tacacs) | Per-user login, command authz, accounting via TACACS+ | Ready | — |
| 10 | [logging-ntp-baseline](labs/10-logging-ntp-baseline) | Remote syslog, NTP, banner, idle timeouts, baseline hardening | Ready | — |
| 11 | [oob-management](labs/11-oob-management) | Physically separate OOB management network | Ready | — |
| 12 | [lacp](labs/12-lacp) | Bundling parallel links into one logical via LACP | Ready | — |
| 13 | [vrrp](labs/13-vrrp) | Active/standby gateway redundancy | Ready | — |
| 14 | [mlag](labs/14-mlag) | Active/active L2 across two switches, no SPOF | Ready | — |
| 15 | [anycast-gateway](labs/15-anycast-gateway) | Active/active L3 with VARP on top of MLAG | Ready | — |
| 16 | [static-routing](labs/16-static-routing) | Static routes, AD, floating statics, ECMP | Ready | — |
| 17 | [ospf-basics](labs/17-ospf-basics) | Single-area OSPF, neighbor formation, LSDB | Ready | — |
| 18 | [ospf-design](labs/18-ospf-design) | Multi-area OSPF, ABR/ASBR, LSA types, stub areas | Ready | — |
| 19 | [bfd](labs/19-bfd) | Sub-second failure detection for routing protocols | Ready | — |
| 19b | [isis-underlay](labs/19b-isis-underlay) | IS-IS as alternative IGP — what hyperscalers run instead of OSPF | Ready | — |
| 20 | [bgp-fundamentals](labs/20-bgp-fundamentals) | eBGP between two ASes, "hello world" of BGP | Ready | — |
| 21 | [ibgp-route-reflectors](labs/21-ibgp-route-reflectors) | iBGP scaling via route reflectors, RR clients, IGP underneath | Ready | — |
| 22 | [bgp-path-selection](labs/22-bgp-path-selection) | local-pref, AS-path prepend, MED, the 13-step decision process | Ready | — |
| 23 | [bgp-route-policy](labs/23-bgp-route-policy) | prefix-lists, route-maps, communities, bogon filtering | Ready | — |
| 24 | [bgp-internet-edge](labs/24-bgp-internet-edge) | Multi-homing pattern, default-only inbound, floating static | Ready | — |
| 25 | [bgp-business](labs/25-bgp-business) | Customer/Peer/Transit, Gao-Rexford policy, BGP leak prevention | Ready | — |
| 26 | [bgp-operations](labs/26-bgp-operations) | Auth, TTL security, BFD fall-over, max-routes, graceful restart | Ready | — |
| 27 | [spine-leaf](labs/27-spine-leaf) | Clos topology with eBGP underlay, ECMP across spines | Ready | — |
| 28 | [bgp-unnumbered](labs/28-bgp-unnumbered) | Link-local BGP peering, RFC 5549, no IP plumbing | Ready | — |
| 29 | [vxlan-data-plane](labs/29-vxlan-data-plane) | Static VXLAN tunnels, VTEP, VNI, head-end replication | Ready | — |
| 30 | [evpn-intro](labs/30-evpn-intro) | EVPN control plane, Type 2/3 routes, auto-discovery | Ready | — |
| 31 | [evpn-type5](labs/31-evpn-type5) | EVPN Type 5, tenant VRF, symmetric IRB, L3 overlay | Ready | — |
| 32 | [evpn-anycast-gateway](labs/32-evpn-anycast-gateway) | Anycast gateway across every leaf in the fabric | Ready | — |
| 33 | [evpn-multisite](labs/33-evpn-multisite) | Stretched subnet across two DCs via DCI EVPN | Ready | — |
| 33b | [evpn-multihoming](labs/33b-evpn-multihoming) | EVPN-MH via Ethernet Segment (ESI) — the modern MLAG replacement | Ready | — |

**Reviewed** = lab has been deployed end-to-end and the README/configs were verified to behave as described. A `Ready` lab is content-complete but unvalidated until reviewed.

## Running a Lab

On the VM, after `git pull`:

```bash
cd labs/NN-name
sudo containerlab deploy
# ... explore, configure, break things ...
sudo containerlab destroy --cleanup
```

Each lab's README explains its goal, topology, theory, task, hints, and verification steps.

## Roadmap

Planned labs, organized into chapters. Order may shift as real-world topics pull each other in. Strikethrough = done (see Lab Index above).

Every lab is grounded in a **real production scenario** — not abstract "ping A from B" exercises. The closing chapter is an architecture document that ties the whole curriculum into a sample dual-site DC reference design, so the entire body of work serves as a self-contained onboarding resource for understanding a production DC network.

### Chapter 1 — L2 fundamentals

| # | Lab | What it adds |
|---|-----|--------------|
| ~~01~~ | ~~VLAN basics~~ | Access ports, trunks, 802.1Q tagging |
| ~~02~~ | ~~Inter-VLAN routing (SVI)~~ | L3 switch role, virtual VLAN interfaces |
| ~~03~~ | ~~Trunk deep-dive~~ | Native VLAN, allowed VLANs, DTP, VLAN pruning; latent bugs & VLAN hopping risk |
| ~~03b~~ | ~~LLDP & operational link discovery~~ | Daily-driver operational tool. LLDP frame anatomy, `show lldp neighbors` reflexes, simulated mis-cabling discovery. |

### Chapter 2 — L2 in production

| # | Lab | What it adds |
|---|-----|--------------|
| ~~04~~ | ~~STP / RSTP~~ | Loop avoidance, root election, port states |
| ~~05~~ | ~~STP protections~~ | BPDU guard, root guard, loop guard, bridge assurance |
| ~~06~~ | ~~Port security & storm control~~ | MAC limits, sticky MACs, broadcast/multicast/unicast storms, errdisable recovery |
| ~~07~~ | ~~L2 security trifecta~~ | DHCP snooping + Dynamic ARP Inspection + IP Source Guard |
| ~~07b~~ | ~~QinQ / 802.1ad tunneling~~ | Customer VLAN structure tunneled inside provider S-VLAN; double-tagged frames, MTU implications, TPID. |

### Chapter 3 — Production hygiene basics

| # | Lab | What it adds |
|---|-----|--------------|
| ~~08~~ | ~~Management VRF~~ | Separating control-plane from data-plane reachability; no more "I lost my switch when I changed a route" |
| ~~09~~ | ~~AAA — TACACS+~~ | Per-user logins, command authorization, local fallback, mgmt-plane ACLs |
| ~~10~~ | ~~Logging, time, baseline hardening~~ | Syslog patterns, NTP, secure-by-default config templates |
| ~~11~~ | ~~Out-of-band management network~~ | Console servers, dedicated mgmt VLAN, isolation from data path |

### Chapter 4 — Redundancy

| # | Lab | What it adds |
|---|-----|--------------|
| ~~12~~ | ~~LACP~~ | Multi-cable bundle to one switch |
| ~~13~~ | ~~VRRP~~ | Gateway failover (active/standby) |
| ~~14~~ | ~~MLAG~~ | LACP bundle terminated on two switches; peer-link, peer-keepalive, orphan ports, split-brain |
| ~~15~~ | ~~Anycast gateway / VARP~~ | Both MLAG peers serve the same gateway IP simultaneously — active/active L3 |

### Chapter 5 — Dynamic routing (IGP)

| # | Lab | What it adds |
|---|-----|--------------|
| ~~16~~ | ~~Static routing~~ | Static routes, floating statics, route preference, AD |
| ~~17~~ | ~~OSPF basics~~ | Single-area OSPF, neighbor discovery, LSDB |
| ~~18~~ | ~~OSPF design~~ | Multi-area, LSA types, DR/BDR, ABR/ASBR roles |
| ~~19~~ | ~~BFD~~ | Sub-second failure detection for routing protocols |
| ~~19b~~ | ~~IS-IS as alternative underlay~~ | NET addressing, L2-only DC pattern, LSPs/TLVs vs OSPF LSAs, when to choose IS-IS over OSPF. |

### Chapter 6 — BGP (the long chapter)

BGP gets its own chapter because it's the protocol you'll spend the most operational time with — both inside the fabric (iBGP for EVPN) and at the edge (eBGP with upstreams). Business and technical sides covered together.

| # | Lab | What it adds |
|---|-----|--------------|
| ~~20~~ | ~~BGP fundamentals~~ | eBGP between two ASes; sessions, updates, RIB vs FIB |
| ~~21~~ | ~~iBGP inside an AS~~ | Full mesh problem, route reflectors, confederations |
| ~~22~~ | ~~BGP path selection~~ | The 13-step decision process, attributes (LP, AS path, MED, weight, origin) |
| ~~23~~ | ~~BGP route policy~~ | prefix-lists, route-maps, communities — the operational toolkit |
| ~~24~~ | ~~BGP at the internet edge~~ | Transit vs peering, multi-homing, AS-prepend, MED games, default-route handling |
| ~~25~~ | ~~BGP — the business angle~~ | ASN ownership (LIR, RIPE), IRR/RPKI, prefix announcement hygiene, customer/peer/transit communities, peering economics |
| ~~26~~ | ~~BGP operations~~ | Convergence tuning, dampening, graceful restart, troubleshooting playbook |

### Chapter 7 — Modern DC fabric

| # | Lab | What it adds |
|---|-----|--------------|
| ~~27~~ | ~~Spine-leaf topology~~ | Routed underlay, ECMP, leaf/spine roles, capacity planning |
| ~~28~~ | ~~BGP unnumbered underlay~~ | Link-local addressing, simpler peering, the modern default |
| ~~29~~ | ~~VXLAN data plane~~ | Frame encapsulation, VTEPs, VNI, MTU implications |
| ~~30~~ | ~~EVPN control plane intro~~ | BGP EVPN address family, Type 2 (MAC/IP) and Type 3 (multicast) routes |
| ~~31~~ | ~~EVPN symmetric IRB~~ | Type 5 routes, L3 overlay, multi-tenant routing |
| ~~32~~ | ~~Anycast gateway in EVPN~~ | Distributed L3 gateway across all leaves |
| ~~33~~ | ~~Multi-site DCI~~ | Stretched subnet across two physical sites via EVPN multi-site or DCI gateway patterns |
| ~~33b~~ | ~~EVPN Multi-Homing (ESI)~~ | EVPN-native replacement for MLAG. Shared ESI + LACP system-id, Type 1/4 routes, DF election, no peer-link. |

### Chapter 8 — Internet Edge & Public-facing

| # | Lab | What it adds |
|---|-----|--------------|
| 34 | eBGP upstream peering | Operational eBGP config, prefix filtering, max-prefix protection at scale |
| 35 | NAT in the DC | 1:1 NAT, PAT/source NAT, NAT44 patterns, when (and when not) to NAT |
| 36 | **CGNAT (Carrier-Grade NAT)** | NAT444, port allocation strategies, logging for compliance, RFC 6598 (100.64.0.0/10) shared space |
| 37 | IPv6 fundamentals + dual-stack | NDP/RA, SLAAC vs DHCPv6, dual-stack rollout patterns, BGP for IPv6 |
| 38 | **IPv6-only deployment** | NAT64/DNS64 for IPv4-only services, prefix delegation, IPv6-only customer access |
| 39 | **Service Anycast** | Same IP at multiple sites via BGP — the pattern behind 1.1.1.1, 8.8.8.8, anycast DNS. Multi-site service deployment via BGP advertisement |
| 40 | **DDoS mitigation** | RTBH (Remote-Triggered Black Hole), BGP Flowspec (RFC 5575), upstream scrubbing integration, the operator playbook for "we're under attack" |
| 41 | Control-plane protection | CoPP, mgmt-plane ACLs, hardware vs software-punt protections |

### Chapter 9 — Application & Traffic Management

The labs in chapters 1-8 cover *transport*. This chapter covers what runs *on* the transport for the customer.

| # | Lab | What it adds |
|---|-----|--------------|
| 42 | **QoS fundamentals** | DSCP marking, classification, queuing disciplines, shaping vs policing, end-to-end QoS in a fabric |
| 43 | **VoIP networking** | Latency / jitter / packet-loss budgets for voice, RTP, prioritization patterns, voice VLANs, common pitfalls (one-way audio, codec mismatch); how a customer's bad WiFi is your support ticket |
| 44 | **Load balancing patterns** | BGP-as-LB, ECMP-based LB at the network layer, anycast LB, integration with L7 LBs (HAProxy/Envoy/F5); when network handles LB vs when app/LB layer does |
| 45 | **VPN technologies on MikroTik** | IPsec site-to-site, WireGuard, GRE, L2TP/IPsec for partner connectivity and customer-facing VPN service. Uses MikroTik RouterOS (CHR) since that's the typical platform for this in mid-size shops |
| 46 | **Storage networking: iSCSI fundamentals** | iSCSI initiators/targets, typical topology, separating storage from data VLAN, why storage networking is its own discipline |
| 47 | **Lossless ethernet: DCB / PFC / ETS** | The protocols that make iSCSI and RoCE actually work at scale: Priority Flow Control, Enhanced Transmission Selection, DCBX. The "why is the storage VM slow" answer most people don't know. |
| 48 | **Storage QoS and isolation** | Per-tenant storage IOPS limits at the network layer, traffic class prioritization for storage backplane, "noisy neighbor" mitigation. |

### Chapter 10 — Operations & Day-2

| # | Lab | What it adds |
|---|-----|--------------|
| 49 | Streaming telemetry | gNMI/OpenConfig subscriptions, structured syslog, log shipping patterns, time-series storage |
| 50 | **gnmic + Prometheus + Grafana stack** | Hands-on: deploy the full monitoring stack inside containerlab (Prometheus, Grafana, gnmic as collector). Pre-built dashboards for BGP sessions, interface counters, EVPN routes. The "I can actually see what my fabric is doing" lab. |
| 51 | NETCONF / RESTCONF foundations | Programmatic device config protocol; YANG models; the building block for everything below |
| 52 | **Ansible & Nornir for network automation** | Inventory, modules, idempotent config, the network automation toolbox |
| 53 | **Network CI/CD pipeline** | Git-driven config workflow, linting (`batfish`, custom), staging validation, automated rollback |
| 54 | **Source of truth & IPAM (NetBox)** | IPAM, VRF assignments, circuit tracking, the canonical "what should this device be configured as" database |
| 55 | **Network device backup & disaster recovery** | "A switch died overnight, walk through the full procedure": config backup automation, ZTP for a replacement, restoring state, validation. Builds on lab 54 (NetBox as source of truth). |
| 56 | **Hitless upgrade / rolling EOS upgrade** | Upgrading the fabric without outage: drain/undrain, MLAG and EVPN-MH pair upgrade dance, graceful restart, "reload fast", validation between steps. Senior+ operational skill. |
| 57 | **Production packet capture: SPAN/mirror + traffic generation** | How to get packet capture from production without putting CPU pressure on the switch (mirror/SPAN ports, TAP aggregator concepts). Companion: generating test traffic (iperf3, scapy) for validation. |
| 58 | Failure scenario playbook | Deliberate breaks + recovery: link, switch, gateway, BGP session, EVPN. The on-call training material |
| 59 | Capacity & MTU planning | Quantitative bandwidth modeling, jumbo frames in VXLAN, oversubscription ratios, capacity-vs-cost economics |

### Closing chapter — Reference design

| # | Item | What it is |
|---|------|------------|
| RD | Sample dual-site DC reference design | An architecture document (not a lab) that ties everything together: two physical sites, EVPN-MH leaves, BGP-EVPN underlay, VXLAN-stretched subnets, redundant edge with DDoS handling, anycast services, AAA, mgmt VRF, telemetry, IPAM-driven config. Diagrams + design rationale. The artifact someone reads to understand the entire DC. |

## Concepts

Standalone deep-dives on questions that come up while doing the labs:

- [L3 Switch vs. Router](docs/concepts/l3-switch-vs-router.md) — when does an L3 switch stop being a switch and become a router?
- [Spanning Tree variants](docs/concepts/stp-variants.md) — STP, RSTP, MSTP, PVST+, RPVST+ — what each adds and when you'll encounter them.
- [VRF deep-dive](docs/concepts/vrf-deep-dive.md) — what a VRF is, RD/RT, route leaking, VRF-Lite vs MPLS L3VPN vs EVPN VRFs.
- [First-hop redundancy comparison](docs/concepts/first-hop-redundancy-comparison.md) — VRRP, HSRP, GLBP, VARP, EVPN anycast gateway — when to pick which.
- [L2 security binding table](docs/concepts/l2-security-binding-table.md) — the single table that DHCP snooping, DAI, and IPSG all share.

## Professional Practice

Labs teach the technical moves. The senior+ skill set is everything around the labs — how you plan a change, run an incident, document a decision, write a procedure a junior can follow at 3 AM. Standalone guides + ready-to-use templates:

- [Migration planning (MOPs)](docs/practice/migration-planning.md) — how to write a change plan that saves you at 3 AM. [Template](docs/practice/templates/mop-template.md).
- [Incident response & blameless postmortems](docs/practice/incident-response.md) — IC role, severities, status update discipline, postmortem template. [Postmortem template](docs/practice/templates/postmortem-template.md).
- [Architecture Decision Records (ADRs)](docs/practice/adr.md) — capture *why* you chose what you chose, so future-you remembers. [ADR template](docs/practice/templates/adr-template.md).
- [Runbooks](docs/practice/runbooks.md) — turn known incidents into checklists juniors can execute. [Runbook template](docs/practice/templates/runbook-template.md).
- [Monitoring & alerting — what to actually monitor](docs/practice/monitoring-and-alerting.md) — the metrics juniors miss (control-plane CPU, error deltas, TCAM fill), three alert tiers, "every alert needs a runbook link."
- [tcpdump fluency](docs/practice/tcpdump-fluency.md) — career-multiplier skill. Filter recipes for BGP, OSPF, VXLAN, VLANs, BFD, ARP, MTU debugging.
- [Linux networking quick reference](docs/practice/linux-networking-quickref.md) — iproute2 toolkit, VRFs and namespaces on Linux, `ethtool`, sockets. Modern network gear runs Linux underneath.
- [The physical layer — optics, cables, MTU](docs/practice/physical-layer.md) — SR vs LR, DAC vs AOC, fiber cleaning, MTU planning, the L1 debug workflow that saves you hours.
- [AI-assisted network engineering](docs/practice/ai-assisted-engineering.md) — using Claude/Copilot/Cursor responsibly. What AI is good at, where it gets you bitten, sanitization rules, team policy.
- [Career growth — what "senior" actually means](docs/practice/career-growth.md) — the level-to-level transitions, IC vs management, compound-interest skills, what's measured vs what matters.

**Planned additions** (not yet written, listed for visibility):
- **TWAMP / SLA measurement** — how to measure latency/jitter/loss against customer SLAs; one-way (OWAMP) vs two-way (TWAMP) protocols; running it operationally.
- **License management & EOS lifecycle** — license expiry traps, what you lose when a license lapses, EOS version EOL planning. Not glamorous; bites people regularly.

By Phase 4-5 of [`STORY.md`](STORY.md), these stop being optional.

## Repo Conventions

See [`CLAUDE.md`](CLAUDE.md) for the directory layout, the hands-on lab format, and the rules Claude follows when adding new labs.
