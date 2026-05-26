# Your Story: From First-Day Junior to DC Architect

> **What this is.** Every lab in this repository is a chapter in one continuous story. You are a fresh IT graduate joining **The Company** on day one. They're a small web-hosting shop with ~15 people, one office, one internet uplink. By the end of the curriculum, The Company is a regional cloud provider operating a multi-site EVPN fabric — and you grew with it from network-cabling-the-conference-room to designing the reference architecture.
>
> Read this once for the big picture. Each lab's **Real-world scenario** picks up the story at the relevant beat. Labs are not isolated exercises — they're moments in a career.

---

## The Company — and you

**The Company**: small hosting shop when you join. Sells shared web hosting and a handful of dedicated servers. Founded by two ex-sysadmins. ~15 employees, one office, one rack at a colo. The kind of place where "the network" means a switch in a closet and a broadband router.

**You**: just graduated. Linux is comfortable, you can ping things, you've read about VLANs but never configured one. The senior engineer who hired you is the only person who knew the network — and they just left for a competitor. Your first task: don't break anything.

---

## Phase 1 — Onboarding (Labs 01–05)

> Month 1–2. Junior. You are alone with the network for the first time.

The previous engineer left a working but undocumented mess. The office is mid-renovation; new desks are arriving and need network drops. There's a new dev team starting next week, and management wants them isolated from finance.

| Lab | Story beat |
|---|---|
| **01 — VLAN basics** | Your first real task: split the new office floor into two VLANs (office team / dev team) so they can't see each other's traffic. You learn what "L2 separation" means. |
| **02 — Inter-VLAN routing (SVI)** | A week later: "Marketing can't reach the dev portal — fix it." You discover that VLAN isolation is *too good* — you need controlled L3 between them. You turn the access switch into an L3 switch. |
| **03 — Trunk deep-dive** | The auditor visits. They flag your inter-switch trunk for "allowing all VLANs" and "using VLAN 1 native." You learn that defaults are dangerous in production and harden the trunks. |
| **04 — STP / RSTP** | The office added a second uplink for redundancy. The network died for 4 minutes — broadcast storm. STP saved it (and you), but you didn't even know it was running. Time to actually understand the spanning tree. |
| **05 — STP protections** | An intern plugged a $20 SOHO switch into a wall jack. It tried to become root bridge. Half the office lost network for 30 seconds. You install PortFast + BPDU Guard on every access port. |

**Where you are by end of Phase 1**: you can build a small office L2 network correctly. You understand VLANs, trunks, STP, and basic protections. You're no longer afraid of the access layer.

**Skills earned beyond the labs**: you've learned (the hard way) that *every change in production needs a written plan*. Read [`docs/practice/migration-planning.md`](docs/practice/migration-planning.md) — your next change should follow the MOP template.

---

## Phase 2 — Hardening (Labs 06–07)

> Month 3–6. Junior+. Security has noticed you exist.

The Company hired its first part-time security consultant. They're going through the network looking for issues. Two of them land on your desk.

| Lab | Story beat |
|---|---|
| **06 — Port security & storm control** | Security found that an unauthorized laptop got LAN access from a conference room jack by spoofing a registered MAC. Also: a malfunctioning NIC on a tenant VM took down a segment with a broadcast storm. You implement MAC limits and storm thresholds. |
| **07 — L2 security trifecta** | Support keeps getting tickets about "weird IPs" and "the gateway suddenly being someone else's machine." You discover rogue DHCP servers and ARP spoofing. You learn the binding-table-based defense: DHCP snooping → DAI → IPSG. |

**Where you are by end of Phase 2**: you're treating the access layer as an attack surface, not just a switching layer. Security signs off on the office. You feel competent for the first time.

**Skills earned beyond the labs**: you start writing things down — what you change, what you investigate, what's currently weird-but-not-broken. Your first attempts at structure. Not yet runbooks; closer to a personal logbook.

---

## Phase 3 — Operational maturity (Labs 08–11)

> Month 6–12. Mid-level. The Company outgrows "we'll just SSH in and look at it."

The Company grew. 35 people now. The original two founders hired more devs, and you got a teammate (an experienced contractor who comes in two days a week). Customers started complaining about outages, and the founders want "professional operations."

| Lab | Story beat |
|---|---|
| **08 — Management VRF** | You changed a route at 17:45 on a Friday and lost SSH to the core switch. You drove to the DC and consoled in. Never again. You build out a management VRF so data-plane mistakes can't kill the mgmt session. |
| **09 — AAA / TACACS+** | Onboarding is a mess: every switch has a shared `admin` password, you have no idea who ran `clear bgp *` last Tuesday at 02:14, and offboarding the contractor means changing passwords on dozens of devices. You roll out TACACS+ with per-user logins, per-command authorization, and accounting. |
| **10 — Logging, NTP, baseline hardening** | A 03:00 outage. By 07:00, when you got in, the switch's local log buffer had rotated and you couldn't see what happened. Different switches' timestamps disagreed by minutes. You ship logs centrally and sync time. While you're at it, you apply a baseline hardening profile: banners, timeouts, disable HTTP. |
| **11 — Out-of-band management network** | Worst outage of the year: a routing bug took out the data plane for 45 minutes. You couldn't SSH in. The on-call engineer drove to the DC. After that, you build a real OOB network with dedicated mgmt ports and a console server. |

**Where you are by end of Phase 3**: The Company's network is professionally operated. You have central logging, central authentication, OOB access, and the muscle memory of someone who's been on-call. You're a mid-level network engineer.

**Skills earned beyond the labs**:
- After the 03:00 outage where logs had rotated, you wrote your first real **runbook** — read [`docs/practice/runbooks.md`](docs/practice/runbooks.md). Future-you at 3 AM thanks present-you.
- After the worst-of-year outage in lab 11, you learn what **incident response** discipline looks like — read [`docs/practice/incident-response.md`](docs/practice/incident-response.md). You'll be Incident Commander on your next outage.

---

## Phase 4 — Redundancy and routing (Labs 12–19)

> Year 1–2. Mid-level → Senior IC. The Company adds a second office and a real DC presence.

The Company won a contract that required a second DC. Suddenly you have two physical sites, redundant uplinks everywhere, and the founders are talking about "high availability" in customer pitches. Single switches are no longer acceptable as single points of failure.

| Lab | Story beat |
|---|---|
| **12 — LACP** | Your inter-switch uplink hit 80% utilization. Buying 10G is expensive; you have a spare 1G cable lying unused because STP blocked it. You bundle both with LACP — doubled bandwidth, no STP block. |
| **13 — VRRP** | When sw1 reloaded for maintenance, every host lost its gateway for 8 minutes. The founders want a status page that doesn't show outages during planned work. You deploy VRRP. |
| **14 — MLAG** | VRRP got rid of the gateway SPOF. But the switch itself is still a SPOF — if it dies catastrophically, both halves of the bundle die with it. You learn MLAG: two switches pretending to be one to downstream LACP. |
| **15 — Anycast gateway** | MLAG works, but only one MLAG peer is the L3 gateway at a time (VRRP-style). Half your routing capacity is idle. You move to active/active via VARP — both MLAG peers serve the same gateway IP simultaneously. |
| **16 — Static routing** | The Company added a third site. Static routes were fine when there were two boxes; now there are 47 entries in a spreadsheet and it took 2 hours and an outage to add the last route. You start thinking about dynamic routing. |
| **17 — OSPF basics** | You roll out OSPF across all internal L3 switches. New links auto-discover. Failures reroute in under a second. You feel a quiet relief every time you `show ip ospf neighbor`. |
| **18 — OSPF design** | Your OSPF area got bigger than ~50 routers. SPF recalculations take longer; LSDB is huge. You split into a backbone area plus branch areas (stub) for the smaller sites. |
| **19 — BFD** | A transport switch between two of your core routers had a partial hardware failure. OSPF didn't notice for 40 seconds (default dead timer). You roll out BFD everywhere. Convergence is now sub-second. |

**Where you are by end of Phase 4**: You operate a multi-site, redundant, OSPF-routed network with sub-second convergence. Your job has moved from "configure stuff" to "design the topology". The founders gave you the title **Senior Network Engineer** and a small budget.

**Skills earned beyond the labs**:
- You've executed several major-change MOPs (site cutovers, OSPF rollout). You now insist on peer-reviewed MOPs for *every* multi-device change.
- You've been Incident Commander on at least one sev1 outage. The team noticed; the founders noticed.
- You started writing **Architecture Decision Records** for your design choices — read [`docs/practice/adr.md`](docs/practice/adr.md). Your "OSPF area design" doc is the first ADR in The Company's history.

---

## Phase 5 — BGP and the outside world (Labs 20–26)

> Year 2–3. Senior IC. The Company becomes a regional cloud provider.

The Company decided to stop reselling other people's transit. They got their own AS number from RIPE, leased a /22 of public IPv4 space, and contracted with two upstream ISPs for redundancy. Customers now get public IPs from your space; you announce to the internet. Welcome to BGP.

| Lab | Story beat |
|---|---|
| **20 — BGP fundamentals** | Your first eBGP session — to your new transit provider. You read the session-state machine carefully because if you screw this up, your company is offline. |
| **21 — iBGP with route reflectors** | Your network has 5 BGP-speaking routers internally. Full-mesh iBGP works but adding the 6th would be painful. You introduce route reflectors. |
| **22 — BGP path selection** | The Company has two upstream ISPs. ISP1 is faster but expensive; ISP2 is cheaper but higher-latency. You learn local-pref, AS-path prepend, and MED to deliberately steer traffic. |
| **23 — BGP route policy** | Both ISPs send you everything they have — including bogons, your own /22, and routes you don't want. You build a route-policy framework: prefix-lists, route-maps, community tagging. |
| **24 — BGP at the internet edge** | You design the proper customer-facing edge: two edge routers, iBGP between them, default-only inbound from ISPs (you don't need full table), AS-prepend for inbound TE, floating static last-resort. |
| **25 — BGP business angle** | The Company became big enough that the founders pitched starting a small transit business — sell connectivity to other companies. You implement the customer/peer/transit policy model (Gao-Rexford) so you don't accidentally become free transit between your peers and your upstreams (the famous "BGP leak"). You learn about RIPE membership, IRR, RPKI. |
| **26 — BGP operations** | Three operational issues from an audit: no BGP session passwords, no max-prefix limits, slow convergence. You apply the hardening profile (MD5, TTL security, BFD-driven fall-over, max-routes, graceful restart) on every session. |

**Where you are by end of Phase 5**: You own the company's internet edge. You can speak intelligently with transit providers and peers. You have a working knowledge of routing policy at the AS-boundary. The founders ask your opinion on infrastructure investments.

**Skills earned beyond the labs**:
- You've opened (and successfully closed) **TAC cases** with two upstream ISPs. You know how to write a clear case description that doesn't waste an hour going back and forth on basics.
- You ran the postmortem on the day your bogon-filter typo caused a 12-minute customer outage. **Blameless** — the org learned about the missing automated lint instead of blaming you. The pattern stuck.
- You're now writing ADRs for every significant policy choice. Future-you (and your replacement) will thank present-you when "why did we community-tag like this?" comes up in two years.
- You've started **saying no** to stakeholders. Not rudely — but you know what realistic timelines look like, and you know which asks are not what they appear to be.

---

## Phase 6 — Modern DC fabric (Labs 27–33)

> Year 3–4. Senior, leading DC architecture. The Company builds a real cloud.

The growth keeps coming. The colo-rack-and-a-couple-of-servers era is over — The Company is building proper datacenter infrastructure. Two physical sites are coming online, multi-tenant workloads need true isolation, and customers are asking for "stretched subnets" between sites. You're the architect.

| Lab | Story beat |
|---|---|
| **27 — Spine-leaf** | You design the new DC fabric from scratch. Three-tier is dead; everyone with scale uses Clos. You build a 2-spine 2-leaf reference, validate ECMP and east-west performance. |
| **28 — BGP unnumbered** | The /31 IPAM for transit links is becoming unmanageable. You discover BGP unnumbered. The new fabric runs entirely on IPv6 link-local for underlay peering. |
| **29 — VXLAN data plane** | First customer asks for a stretched VLAN across racks. You implement static VXLAN. It works for the first customer; you immediately see why "flood-list maintenance" is a problem at scale. |
| **30 — EVPN control plane** | Twenty customers in, the static VXLAN flood-lists are impossible to maintain. You roll out EVPN. Now adding a new leaf "just works" — every other leaf discovers it via BGP. |
| **31 — EVPN Type 5** | Customers want multiple subnets per tenant with controlled inter-subnet routing. You implement L3 overlay via Type 5 routes and tenant VRFs. Symmetric IRB. |
| **32 — EVPN anycast gateway** | VM mobility started mattering. A customer's load balancer moves between leaves and you don't want the gateway to change. You deploy distributed anycast gateway — every leaf is the local gateway for hosted subnets. |
| **33 — EVPN multi-site DCI** | The big one: a customer (and your CTO) want a /24 that works in both DCs simultaneously. You design the multi-site EVPN extension: back-to-back EVPN for now, with a plan to migrate to Border Gateway pattern as you scale. |

**Where you are by end of Phase 6**: You operate (and largely designed) a modern multi-site EVPN fabric. You can have a substantive conversation about VXLAN encapsulation, RD/RT semantics, anycast gateway, and DCI patterns. Your CTO trusts you with the architecture decisions.

**Skills earned beyond the labs**:
- You ran (or substantially contributed to) the multi-week migration project that moved customers onto the new EVPN fabric. Every migration was a peer-reviewed MOP with rollback plans. Some rolled back. None became outages.
- You established the team's **ADR repository** as a real practice — there are 15+ ADRs now, and new engineers read them as part of onboarding.
- You've negotiated peering at an IXP and represented The Company at a peering meet. You can now small-talk about MED games, AS-path tricks, and RPKI deployment status.
- You're the **default Incident Commander** for sev1s in your area. Other senior engineers handle their own areas; you handle the network.

---

## Phase 7 — Internet Edge & Public-facing (Labs 34–41)

> Year 4. Senior+. The Company is no longer just running its own DCs — it's a real internet operator, with public IP space, RIPE membership, peering relationships, and customers who get DDoS'd.

> *(Labs 34-52 are planned, not yet written. Phase 7-9 span the work of turning a DC operator into a real internet operator, traffic-manager, and day-2 ops shop.)*

| # | Lab | Theme |
|---|---|---|
| **34 — eBGP upstream peering at scale** | Peering at multiple IXPs. RPKI ROV deployment. Real peering economics. |
| **35 — NAT in the DC** | 1:1 NAT, PAT/source NAT, common patterns and anti-patterns. |
| **36 — CGNAT** | Carrier-grade NAT44 with port allocation strategies. The IPv4-exhaustion answer for customer-facing operators. |
| **37 — IPv6 fundamentals + dual-stack** | The Company's `/22` of IPv4 is running out and RIPE has nothing left to sell. Time to deploy IPv6 for real. |
| **38 — IPv6-only deployment** | NAT64/DNS64 for the long tail of IPv4-only services. Customer-facing IPv6-only access with backwards compatibility. |
| **39 — Service Anycast** | A customer wants their service to "just work globally". You learn the same pattern that runs 1.1.1.1, 8.8.8.8, and every modern CDN. |
| **40 — DDoS mitigation** | A customer gets DDoS'd at 3 AM. You implement RTBH, BGP Flowspec, and integrate with upstream scrubbing. The new operational playbook for "we're under attack". |
| **41 — Control-plane protection** | CoPP + mgmt-plane ACLs to harden every device from the inside. |

## Phase 8 — Application & Traffic Management (Labs 42–45)

> Year 4-5. Senior+. Customers stop being "VMs" and start being "applications" that need network behavior.

A long-time customer adds a VoIP service. Their one-way audio issue is now your problem. Another customer asks for load-balancing across their backends. The partner network you connect to over the internet wants an encrypted tunnel. Your network needs to understand the *applications* on top of it.

| # | Lab | Theme |
|---|---|---|
| **42 — QoS fundamentals** | DSCP, queuing, shaping vs policing. End-to-end QoS in your fabric. |
| **43 — VoIP networking** | Latency / jitter / packet-loss budgets, RTP, voice VLANs, one-way audio debug. Your VoIP-using customers' calls travel over your network — make them sound good. |
| **44 — Load balancing patterns** | BGP-as-LB, ECMP-LB, anycast LB, integration with HAProxy/Envoy/F5. Where the network ends and the application starts. |
| **45 — VPN technologies on MikroTik** | IPsec site-to-site, WireGuard, GRE, L2TP/IPsec — for partner connections and customer-facing VPN service. MikroTik because that's the typical mid-size-shop platform for this. |

## Phase 9 — Operations & Day-2 (Labs 46–52)

> Year 5+. Tech lead. There's a NOC. You have a team. You write standards, not configs. But you still get pulled into the gnarliest incidents.

| # | Lab | Theme |
|---|---|---|
| **46 — Streaming telemetry** | Legacy `show interface counter` polling can't keep up. You move to gNMI/OpenConfig. |
| **47 — NETCONF / RESTCONF foundations** | The programmable-device protocols. YANG models. Foundation for everything below. |
| **48 — Ansible & Nornir for network automation** | Toolbox for managing 100+ devices at once. Idempotent, inventory-driven config. |
| **49 — Network CI/CD pipeline** | Click-ops doesn't scale. You roll out a git-driven config workflow with linting, staging validation, and automated rollback. |
| **50 — Source of truth & IPAM (NetBox)** | The canonical database that knows what every device *should* be. Drives automation. |
| **51 — Failure scenario playbook** | A new junior joined the team. You write failure playbooks they can follow at 3 AM. |
| **52 — Capacity & MTU planning** | Several near-misses with saturation and MTU mismatches. Quantitative planning and validation tooling. |

**Skills earned beyond the labs in Phases 7–9**:
- You no longer write configs directly. You **review** configs, **mentor** writers, and **own standards**.
- You've written the team's incident response standard, the MOP review checklist, the ADR practice document, and the runbook style guide.
- You onboard new hires by walking them through the ADR repository — the org's institutional memory in document form.
- You're regularly asked by leadership for honest estimates and risk assessments. You're trusted to say "this will take longer than they want" without it being a career risk.

---

## Closing — The Reference Design

> The capstone, not a lab.

It's your fifth anniversary at The Company. The CTO asks you to write the **reference architecture document** that every new engineer will read on day one. You write a clean, comprehensive design of a dual-site DC with redundant edge, EVPN-multi-site fabric, anycast gateways, secured management plane, and documented failure modes.

It's everything the previous chapters of your story taught you, distilled into one document. New engineers will read it before their first shift. And someone fresh out of school — like you were, five years ago — will read it and start their own journey.

---

## How to read this story

- **Sequentially** — labs were ordered to build on each other and on the narrative.
- **Out of order** — each lab still works as a standalone exercise. The Real-world scenario at the top tells you where in the story you are.
- **As a reference** — once you've gone through, the labs are reference material for "how do I configure X on Arista" plus the conceptual deep-dives in `docs/concepts/` and the professional-practice guides in `docs/practice/`.

## Beyond the labs — professional practice

Labs teach you the *technical* moves. They don't teach you how to plan a migration, run an incident, write down decisions, or document procedures so a junior can run them at 3 AM. That's the content in [`docs/practice/`](docs/practice/):

- [Migration planning](docs/practice/migration-planning.md) (with [MOP template](docs/practice/templates/mop-template.md))
- [Incident response & blameless postmortems](docs/practice/incident-response.md) (with [postmortem template](docs/practice/templates/postmortem-template.md))
- [Architecture Decision Records (ADRs)](docs/practice/adr.md) (with [ADR template](docs/practice/templates/adr-template.md))
- [Runbooks](docs/practice/runbooks.md) (with [runbook template](docs/practice/templates/runbook-template.md))

These aren't optional reading. By Phase 4-5 of your story, they're the difference between "engineer who knows configs" and "engineer the org can trust with the network".

The protagonist is "you" because this story really is generic — every senior engineer at every cloud/hosting provider has lived some version of it. The technology choices are real; the growth pattern is real; the operational lessons are real. By the end, when someone asks you "how does your DC work?", you'll be able to explain it from first principles.
