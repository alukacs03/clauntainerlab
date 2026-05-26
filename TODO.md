# TODO — Future work parked for later

A short list of things we discussed and want to revisit. Not blocking; not active. Picked up after the current curriculum loops close.

---

## Xen + OVS + FRR EVPN — host-based VTEP for customer private networks

**Context**: most hosting providers offer "private networking" (per-customer L2/L3 overlay across DCs). The mechanism is host-based VTEPs on hypervisors. For a Xen-based shop:
- Dom0 runs Open vSwitch instead of the classic Linux bridge.
- Each customer's VMs get tagged into a per-tenant VNI.
- Dom0 is the VTEP; FRR (or an SDN controller) carries EVPN.
- Same fabric concepts as labs 27-33, but with the VTEP moved from the ToR onto the hypervisor.

**What we'd build**: a Chapter 9 lab — 2 Xen-ish "hypervisors" (Linux + OVS + FRR), 2 ToRs, a spine, customer VMs as nested containers or just net-namespaces. Walk through:
- vm-on-OVS-bridge plumbing
- per-tenant VNI/RT
- EVPN Type 2 advertisement from a software VTEP
- cross-DC stretched private network end-to-end

**Pick this up when**: the learner has finished Phase 6 (labs 30-33). At that point the mechanism is mostly familiar — the new piece is just "the VTEP runs on a Linux box, not an Arista switch."

**Conversation reference**: discussed in detail; the example walkthrough has the full architecture sketched. Pulling that into a lab when ready.

---

## Chapters 7-10 + closing reference design

Still planned, not yet written. Story callouts in `STORY.md` and full roadmap in `README.md` reflect the planned scope:
- **Ch 7 (Internet Edge & Public-facing)** — 8 labs: eBGP at scale, NAT, CGNAT, IPv6 fundamentals + dual-stack, IPv6-only with NAT64/DNS64, Service Anycast, DDoS mitigation (RTBH + Flowspec), control-plane protection.
- **Ch 8 (Application & Traffic Management)** — 4 labs: QoS fundamentals, VoIP networking, load balancing patterns, VPN technologies on MikroTik (IPsec/WireGuard/GRE/L2TP/IPsec).
- **Ch 9 (Operations & Day-2)** — 7 labs: streaming telemetry (gNMI), NETCONF/RESTCONF foundations, Ansible/Nornir, network CI/CD, NetBox/IPAM, failure playbook, capacity planning.
- **Closing**: dual-site reference design document.

**Also pending**:
- **Chapter 1 addition**: LLDP & operational link discovery (planned to be inserted as a Phase 1 lab).
- **Chapter 7 addition**: EVPN Multi-Homing (ESI) — the EVPN-native replacement for MLAG.

**Pick this up when**: after the existing 33 labs are validated. The current 33 labs + practice docs give the learner enough material for a long stretch of learning before chapter 7+ becomes urgent.

**Notable platform shift**: lab 45 (VPN on MikroTik) is the first lab to step away from Arista cEOS. Will use MikroTik CHR (Cloud Hosted Router); needs vrnetlab integration into containerlab, or running CHR as a sibling VM.
