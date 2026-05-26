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
| 02 | [inter-vlan-svi](labs/02-inter-vlan-svi) | Inter-VLAN routing with SVIs | Ready | ✅ |
| 03 | [trunk-deep-dive](labs/03-trunk-deep-dive) | Native VLAN, allowed-list hygiene, VLAN hopping | Ready | ✅ |
| 03b | [lldp-and-discovery](labs/03b-lldp-and-discovery) | LLDP — "what's on the other end of this cable?" daily reflex | Ready | ✅ |
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
| 34 | [ebgp-upstream-at-scale](labs/34-ebgp-upstream-at-scale) | IXP route server peering, bogon + max-prefix protection, community tagging | Ready | — |
| 35 | [nat-in-dc](labs/35-nat-in-dc) | PAT (overload) + 1:1 static NAT at the edge | Ready | — |
| 36 | [cgnat](labs/36-cgnat) | Carrier-grade NAT (NAT444) over RFC 6598 shared space | Ready | — |
| 37 | [ipv6-dual-stack](labs/37-ipv6-dual-stack) | Dual-stack with OSPFv3 + SLAAC | Ready | — |
| 38 | [ipv6-only-nat64](labs/38-ipv6-only-nat64) | IPv6-only customer access with NAT64/DNS64 (conceptual) | Ready | — |
| 39 | [service-anycast](labs/39-service-anycast) | Multi-site service via BGP anycast — the 1.1.1.1 / 8.8.8.8 pattern | Ready | — |
| 40 | [ddos-mitigation](labs/40-ddos-mitigation) | RTBH via BGP community signaling to upstream | Ready | — |
| 41 | [control-plane-protection](labs/41-control-plane-protection) | Mgmt-plane ACLs + CoPP to harden the device itself | Ready | — |
| 42 | [qos-fundamentals](labs/42-qos-fundamentals) | DSCP marking, priority queueing, voice vs bulk | Ready | — |
| 43 | [voip-networking](labs/43-voip-networking) | Voice access port, RTP/SIP marking, common pitfalls | Ready | — |
| 44 | [load-balancing-patterns](labs/44-load-balancing-patterns) | BGP + ECMP across backends (FRR on Linux servers) | Ready | — |
| 45 | [vpn-on-mikrotik](labs/45-vpn-on-mikrotik) | WireGuard + IPsec site-to-site (MikroTik) | Ready | — |
| 46 | [iscsi-fundamentals](labs/46-iscsi-fundamentals) | Storage VLAN, jumbo MTU, multipath topology | Ready | — |
| 47 | [lossless-ethernet-dcb](labs/47-lossless-ethernet-dcb) | DCB / PFC / ETS pattern (cEOS limited; production config) | Ready | — |
| 48 | [storage-qos-isolation](labs/48-storage-qos-isolation) | Per-tenant policer + DSCP + queue allocation | Ready | — |
| 49 | [streaming-telemetry](labs/49-streaming-telemetry) | gNMI subscriptions; push vs poll | Ready | — |
| 50 | [gnmic-prom-grafana](labs/50-gnmic-prom-grafana) | Full observability stack in containerlab | Ready | — |
| 51 | [netconf-restconf](labs/51-netconf-restconf) | NETCONF/SSH + eAPI for programmatic config | Ready | — |
| 52 | [ansible-nornir](labs/52-ansible-nornir) | Idempotent baseline playbook across N devices | Ready | — |
| 53 | [network-cicd](labs/53-network-cicd) | Lint→validate→stage→prod pipeline + smoke tests | Ready | — |
| 55 | [backup-and-dr](labs/55-backup-and-dr) | Automated config backup + recovery procedure | Ready | — |
| 56 | [hitless-upgrade](labs/56-hitless-upgrade) | Rolling EOS upgrade across an MLAG/ESI pair | Ready | — |
| 57 | [span-capture](labs/57-span-capture) | Port mirroring + scapy/iperf3 traffic generation | Ready | — |
| 58 | [failure-playbook](labs/58-failure-playbook) | Chaos-experiments + scripted response | Ready | — |
| 59 | [capacity-mtu-planning](labs/59-capacity-mtu-planning) | Oversubscription math + end-to-end MTU budget | Ready | — |

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
| ~~34~~ | ~~eBGP upstream peering at scale~~ | IXP route server pattern, bogon + OWN-PREFIX filtering, max-prefix, community tagging |
| ~~35~~ | ~~NAT in the DC~~ | PAT (overload) + 1:1 static NAT, ACL-driven source NAT, NAT44 patterns |
| ~~36~~ | ~~CGNAT (Carrier-Grade NAT)~~ | NAT444, RFC 6598 (100.64.0.0/10), port allocation, logging for compliance |
| ~~37~~ | ~~IPv6 fundamentals + dual-stack~~ | NDP/RA, SLAAC, OSPFv3 alongside OSPFv2, dual-stack rollout |
| ~~38~~ | ~~IPv6-only deployment~~ | NAT64/DNS64 conceptual (cEOS lacks native NAT64; Jool pointer) |
| ~~39~~ | ~~Service Anycast~~ | Same IP at multiple sites via BGP — the pattern behind 1.1.1.1, 8.8.8.8 |
| ~~40~~ | ~~DDoS mitigation~~ | RTBH via BGP community to upstream; next-hop rewrite to Null0 |
| ~~41~~ | ~~Control-plane protection~~ | Mgmt-plane ACLs + CoPP ACL on control-plane |

### Chapter 9 — Application & Traffic Management

The labs in chapters 1-8 cover *transport*. This chapter covers what runs *on* the transport for the customer.

| # | Lab | What it adds |
|---|-----|--------------|
| ~~42~~ | ~~QoS fundamentals~~ | DSCP marking, classification, queuing, shaping vs policing |
| ~~43~~ | ~~VoIP networking~~ | RTP/SIP marking, voice access port, latency/jitter budgets |
| ~~44~~ | ~~Load balancing patterns~~ | BGP+ECMP across backends (FRR-on-Linux pattern) |
| ~~45~~ | ~~VPN technologies on MikroTik~~ | WireGuard + IPsec site-to-site, partner-connectivity pattern |
| ~~46~~ | ~~Storage networking: iSCSI fundamentals~~ | Storage VLAN, jumbo MTU, multipath topology |
| ~~47~~ | ~~Lossless ethernet: DCB / PFC / ETS~~ | Per-class PAUSE, bandwidth guarantees, DCBX (cEOS limited) |
| ~~48~~ | ~~Storage QoS and isolation~~ | Per-tenant policer + DSCP marking + egress allocation |

### Chapter 10 — Operations & Day-2

| # | Lab | What it adds |
|---|-----|--------------|
| ~~49~~ | ~~Streaming telemetry~~ | gNMI/OpenConfig subscribe; push vs poll |
| ~~50~~ | ~~gnmic + Prometheus + Grafana stack~~ | Full observability stack inside containerlab |
| ~~51~~ | ~~NETCONF / RESTCONF foundations~~ | YANG, NETCONF over SSH, eAPI on Arista |
| ~~52~~ | ~~Ansible & Nornir for network automation~~ | Idempotent baseline playbook + Nornir equivalent |
| ~~53~~ | ~~Network CI/CD pipeline~~ | Lint → validate → stage-deploy → stage-test → prod-deploy → smoke |
| 54 | _Source of truth & IPAM (NetBox)_ — **deferred** | Removed from the curriculum; needs a deeper treatment (likely its own chapter). See [`TODO.md`](TODO.md). |
| ~~55~~ | ~~Network device backup & disaster recovery~~ | Daily backup to git + ZTP-driven replacement procedure |
| ~~56~~ | ~~Hitless upgrade / rolling EOS upgrade~~ | MLAG-pair drain/upgrade/undrain dance; reload-fast |
| ~~57~~ | ~~Production packet capture: SPAN + traffic generation~~ | Port mirroring + scapy/iperf3 |
| ~~58~~ | ~~Failure scenario playbook~~ | Chaos-experiments + scripted on-call response |
| ~~59~~ | ~~Capacity & MTU planning~~ | Oversubscription math + end-to-end MTU budget |

### Closing chapter — Reference design

| # | Item | What it is |
|---|------|------------|
| ~~RD~~ | [~~Sample dual-site DC reference design~~](docs/reference-design/dual-site-dc.md) | Architecture document (not a lab) that ties the curriculum into one cohesive design. |

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
- [Ticket hygiene as an IC](docs/practice/ticket-hygiene-as-an-ic.md) — how to actually work tickets well: lifecycle, comment hygiene, closing properly, and how tickets relate to MOPs/runbooks/ADRs/postmortems.
- [Pushing back constructively](docs/practice/pushing-back-constructively.md) — when to disagree with a senior or lead, how to structure the push-back (acknowledge → concern → evidence → alternative → update criteria), and "disagree and commit" when it doesn't go your way.
- [Change communication](docs/practice/change-communication.md) — stakeholder identification, tier-based comms, channel selection, timing cadence; pairs with the MOP doc. The discipline that prevents "we did the change but nobody told the dev team and Monday morning was chaos."
- [TLS & certificates for network engineers](docs/practice/tls-and-certificates.md) — modern protocols (NETCONF, gNMI, RadSec, syslog-TLS) all require certs. Cert chain anatomy, internal CA setup, renewal automation, common gotchas, the 8-9 openssl commands you'll use forever.
- [The network from an attacker's perspective](docs/practice/attacker-perspective.md) — defender's mental model of the attack lifecycle. Recon, initial access, L2/L3 attacks, mgmt-plane attacks, exfil, impact — and which labs/docs in this curriculum defend against each phase.

**Planned additions** (not yet written, listed for visibility):
- **TWAMP / SLA measurement** — how to measure latency/jitter/loss against customer SLAs; one-way (OWAMP) vs two-way (TWAMP) protocols; running it operationally.
- **License management & EOS lifecycle** — license expiry traps, what you lose when a license lapses, EOS version EOL planning. Not glamorous; bites people regularly.

By Phase 4-5 of [`STORY.md`](STORY.md), these stop being optional.

## Repo Conventions

See [`CLAUDE.md`](CLAUDE.md) for the directory layout, the hands-on lab format, and the rules Claude follows when adding new labs.
