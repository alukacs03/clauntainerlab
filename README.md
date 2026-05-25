# Containerlab Labs

A personal networking learning journey using [containerlab](https://containerlab.dev), Arista cEOS, and Claude as a study companion.

## What this project is

The goal is to learn networking concepts — VLANs, routing, redundancy, switching internals — on systems that look and feel like the real thing, not on toy abstractions. Containerlab gives us multi-node topologies of actual NOS images (primarily **Arista cEOS** here) running as containers, so the CLI, config style, and behavior match what you'd encounter on real production gear.

Each lab is built as a **hands-on exercise**, not a demo: the starter configs only get the devices booting, and the learner builds the actual configuration themselves, guided by a theory primer and a task spec in the lab README. A reference solution is provided in `solutions/` for after you've tried — peek when stuck, compare when done.

Claude (Claude Code, specifically) is used throughout to design the labs, explain concepts in the READMEs, and help debug when something doesn't behave as expected.

## Setup

Labs run on a dedicated VM on a Proxmox server. See [`docs/vm-setup.md`](docs/vm-setup.md) for VM provisioning, Docker + containerlab installation, and the manual Arista cEOS image import procedure.

## Lab Index

| # | Lab | Topic | Status | Reviewed |
|---|-----|-------|--------|----------|
| 01 | [vlan-basics](labs/01-vlan-basics) | Access ports, trunks, 802.1Q tagging | Ready | ✅ |
| 02 | [inter-vlan-svi](labs/02-inter-vlan-svi) | Inter-VLAN routing with SVIs | Ready | — |
| 03 | [trunk-deep-dive](labs/03-trunk-deep-dive) | Native VLAN, allowed-list hygiene, VLAN hopping | Ready | — |
| 04 | [stp-rstp](labs/04-stp-rstp) | Root election, port roles, RSTP convergence | Ready | — |
| 05 | [stp-protections](labs/05-stp-protections) | PortFast, BPDU Guard, Root Guard | Ready | — |
| 06 | [port-security-storm-control](labs/06-port-security-storm-control) | MAC limits, sticky learning, broadcast/multicast storm control | Ready | — |
| 07 | [l2-security-trifecta](labs/07-l2-security-trifecta) | DHCP snooping + DAI + IP Source Guard | Ready | — |
| 08 | [management-vrf](labs/08-management-vrf) | Logical separation of mgmt from data via VRF | Ready | — |
| 09 | [aaa-tacacs](labs/09-aaa-tacacs) | Per-user login, command authz, accounting via TACACS+ | Ready | — |
| 10 | [logging-ntp-baseline](labs/10-logging-ntp-baseline) | Remote syslog, NTP, banner, idle timeouts, baseline hardening | Ready | — |
| 11 | [oob-management](labs/11-oob-management) | Physically separate OOB management network | Ready | — |
| 12 | [lacp](labs/12-lacp) | Bundling parallel links into one logical via LACP | Ready | — |
| 13 | [vrrp](labs/13-vrrp) | Active/standby gateway redundancy | Ready | — |
| 14 | [mlag](labs/14-mlag) | Active/active L2 across two switches, no SPOF | Ready | — |
| 15 | [anycast-gateway](labs/15-anycast-gateway) | Active/active L3 with VARP on top of MLAG | Ready | — |

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

### Chapter 2 — L2 in production

| # | Lab | What it adds |
|---|-----|--------------|
| ~~04~~ | ~~STP / RSTP~~ | Loop avoidance, root election, port states |
| ~~05~~ | ~~STP protections~~ | BPDU guard, root guard, loop guard, bridge assurance |
| ~~06~~ | ~~Port security & storm control~~ | MAC limits, sticky MACs, broadcast/multicast/unicast storms, errdisable recovery |
| ~~07~~ | ~~L2 security trifecta~~ | DHCP snooping + Dynamic ARP Inspection + IP Source Guard |

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
| 16 | Static routing | Static routes, floating statics, route preference, AD |
| 17 | OSPF basics | Single-area OSPF, neighbor discovery, LSDB |
| 18 | OSPF design | Multi-area, LSA types, DR/BDR, ABR/ASBR roles |
| 19 | BFD | Sub-second failure detection for routing protocols |

### Chapter 6 — BGP (the long chapter)

BGP gets its own chapter because it's the protocol you'll spend the most operational time with — both inside the fabric (iBGP for EVPN) and at the edge (eBGP with upstreams). Business and technical sides covered together.

| # | Lab | What it adds |
|---|-----|--------------|
| 20 | BGP fundamentals | eBGP between two ASes; sessions, updates, RIB vs FIB |
| 21 | iBGP inside an AS | Full mesh problem, route reflectors, confederations |
| 22 | BGP path selection | The 13-step decision process, attributes (LP, AS path, MED, weight, origin) |
| 23 | BGP route policy | prefix-lists, route-maps, communities — the operational toolkit |
| 24 | BGP at the internet edge | Transit vs peering, multi-homing, AS-prepend, MED games, default-route handling |
| 25 | BGP — the business angle | ASN ownership (LIR, RIPE), IRR/RPKI, prefix announcement hygiene, customer/peer/transit communities, peering economics |
| 26 | BGP operations | Convergence tuning, dampening, graceful restart, troubleshooting playbook |

### Chapter 7 — Modern DC fabric

| # | Lab | What it adds |
|---|-----|--------------|
| 27 | Spine-leaf topology | Routed underlay, ECMP, leaf/spine roles, capacity planning |
| 28 | BGP unnumbered underlay | Link-local addressing, simpler peering, the modern default |
| 29 | VXLAN data plane | Frame encapsulation, VTEPs, VNI, MTU implications |
| 30 | EVPN control plane intro | BGP EVPN address family, Type 2 (MAC/IP) and Type 3 (multicast) routes |
| 31 | EVPN symmetric IRB | Type 5 routes, L3 overlay, multi-tenant routing |
| 32 | Anycast gateway in EVPN | Distributed L3 gateway across all leaves |
| 33 | Multi-site DCI | Stretched subnet across two physical sites via EVPN multi-site or DCI gateway patterns |

### Chapter 8 — Edge / WAN

| # | Lab | What it adds |
|---|-----|--------------|
| 34 | eBGP upstream peering | Operational eBGP config, prefix filtering, max-prefix protection |
| 35 | NAT in the DC | 1:1 NAT, PAT, NAT44 vs NAT64, when (and when not) to NAT |
| 36 | IPv6 deployment | Dual-stack, prefix delegation, NDP/RA, IPv6-only with NAT64/DNS64 |
| 37 | Control-plane protection & DDoS basics | CoPP, mgmt-plane ACL, RTBH, BGP flowspec intro |

### Chapter 9 — Operations & day-2

| # | Lab | What it adds |
|---|-----|--------------|
| 38 | Streaming telemetry | gNMI/OpenConfig, structured syslog, log shipping patterns |
| 39 | Configuration as code | Git-driven config workflow, validation, rollback strategies |
| 40 | Failure scenario playbook | Deliberate breaks + recovery: link, switch, gateway, BGP session, EVPN |
| 41 | Capacity & MTU planning | Bandwidth headroom, jumbo frames in a VXLAN fabric, oversubscription |

### Closing chapter — Reference design

| # | Item | What it is |
|---|------|------------|
| RD | Sample dual-site DC reference design | An architecture document (not a lab) that ties everything together: two physical sites, MLAG'd leaves, BGP-EVPN underlay, VXLAN-stretched subnets, redundant edge, AAA, mgmt VRF, telemetry. Diagrams + design rationale. The artifact someone reads to understand the entire DC. |

## Concepts

Standalone deep-dives on questions that come up while doing the labs:

- [L3 Switch vs. Router](docs/concepts/l3-switch-vs-router.md) — when does an L3 switch stop being a switch and become a router?

## Repo Conventions

See [`CLAUDE.md`](CLAUDE.md) for the directory layout, the hands-on lab format, and the rules Claude follows when adding new labs.
