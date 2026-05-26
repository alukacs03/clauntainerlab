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

---

## NetBox / Source of Truth — deserves its own deeper treatment

**Context**: lab 54 was originally written as a quick "here's NetBox, here's an Ansible inventory plugin pointing at it" reference. On review it's too shallow for what NetBox actually is — and what the learner needs to understand about source-of-truth-driven networking. Removed from the curriculum until it gets a proper treatment.

**Why a single lab isn't enough**:
- NetBox isn't a containerlab-shaped piece — it's a multi-container web app with its own data model, API, and operational concerns. Standing it up "next to" the lab is awkward.
- The interesting parts (data modeling decisions, custom fields, dynamic inventory, intent-vs-state diff, drift detection automation, webhook-driven CI) each warrant their own walkthrough.
- The right framing is probably an entire chapter ("Source of Truth & Automation Plumbing") or a multi-lab block within Chapter 10, not one lab.

**What a proper treatment would cover**:
- Standing up NetBox with sane defaults (docker-compose alongside containerlab, or a managed instance)
- Modeling a real fabric in NetBox (sites, racks, devices, interfaces, IPs, VLANs, VRFs, cables, circuits)
- Bulk-importing from existing configs (ntc-templates, netbox-importer)
- Dynamic Ansible inventory from NetBox (and equivalent for Nornir)
- Jinja templates rendering configs from NetBox data
- Drift detection: scheduled diff of rendered intent vs. live state
- Webhook-driven automation (NetBox change → CI trigger)
- Operational realities: token management, RBAC, custom fields done right vs. abused

**Pick this up when**: existing labs validated and there's appetite for a dedicated source-of-truth chapter. Until then NetBox is mentioned conceptually in `docs/reference-design/dual-site-dc.md` and in lab 52/55 commentary as "this is where it would slot in."

---

## Out of scope for this repo: a separate "Network team leadership" track

This curriculum is technical networking. Distinct (and explicitly *not* part of it) is the management/leadership track that becomes relevant when someone transitions from senior IC to team lead. Parked here so the brainstorm isn't lost in case a separate venue (personal blog, internal company wiki, separate repo) ever wants it.

Topics that would belong there, not here:

**Tier 1 — for someone just becoming team lead:**
- Setting up project tracking for a small ops team (e.g., moving from Slack todos to Jira/Linear; ticket types, workflow states, label scheme)
- One-on-ones with a direct report (cadence, structure, growth conversations, note-taking)
- Translating business asks into network work ("sales committed something; can we do it?")
- First 90 days as a network team lead (what to fix vs. leave alone)
- SLAs / SLOs / error budgets for a network team

**Tier 2 — once established:**
- Vendor management at team/business level (RFPs, support contracts, vendor switching)
- Budget thinking — CapEx vs OpEx, TCO, cost-per-port-per-month
- Reporting up to leadership (green/yellow/red status format, asking for decisions vs informing)
- On-call rotation design for a small team
- Knowledge transfer & onboarding new hires
- Working with consultants

**Tier 3 — at larger team sizes:**
- Hiring for the network team
- Performance reviews / continuous feedback
- Change Advisory Board (CAB) processes
- Treating the network team as a product with internal customers

**Why not in this repo**: the technical curriculum is *publicly defensible* — anyone can learn from it, generic across orgs. Leadership content is much more situational, often company-specific, and dilutes the focus.

**Where it could go**: a separate personal/professional knowledge base or blog, or a company-internal wiki. The career-growth.md and incident-response.md docs in `docs/practice/` already touch the edges of this; deeper leadership content would warrant its own home.
