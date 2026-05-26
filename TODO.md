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

## Chapters 8-9 + closing reference design

Still planned, not yet written. Story callouts and directory structure already exist; just need the technical content:
- Ch 8 (Edge/WAN): eBGP at scale, NAT, IPv6 deployment, control-plane protection
- Ch 9 (Operations): streaming telemetry, config-as-code, failure playbooks, capacity planning
- Closing: dual-site reference design document

**Pick this up when**: after the existing 33 labs are validated. The current 33 + Phase 6 are enough material for a long stretch of learning.
