# Containerlab Learning Repo

This repository is a personal networking learning journey using [containerlab](https://containerlab.dev). Labs are run on a dedicated VM on a Proxmox server; this directory is the source of truth and is deployed to the VM via git.

## Repository Layout

```
containerlab/
├── CLAUDE.md            # this file
├── README.md            # human-facing intro + lab index
├── .gitignore
├── labs/                # one directory per lab, numbered + named
│   └── NN-short-name/
│       ├── topology.clab.yml
│       ├── configs/     # starter configs (minimal — learner fills in)
│       ├── solutions/   # full reference answer
│       └── README.md    # theory + task spec + hints + verification
├── docs/
│   ├── vm-setup.md      # one-time provisioning of the lab VM
│   └── concepts/        # standalone deep-dives on networking concepts
├── images/              # notes on NOS image sourcing (not the images themselves)
└── scripts/             # shared helpers (deploy, bootstrap, teardown)
```

## Conventions

- **Lab naming**: `NN-short-kebab-name` where `NN` is a zero-padded sequence number reflecting learning order, not topic grouping. Topics belong in the lab's README.
- **Topology files**: always named `topology.clab.yml` inside the lab directory so `containerlab deploy` works without `-t`.
- **Configs**: per-node configs live under `configs/<node-name>.cfg` (starter — minimal, usually just hostname) and `solutions/<node-name>.cfg` (full reference answer). The topology always references `configs/`.
- **Hands-on, not demo**: labs are exercises. The learner deploys the starter, then configures each device themselves — either live in the NOS CLI or by editing `configs/` and redeploying. The README explains concepts and specifies the *goal state*; the learner figures out the commands.
- **Lab READMEs**: must include in this order — Goal, Topology diagram (Mermaid preferred for simple, PlantUML for complex), Theory primer, **Your task** (what to achieve, not how), Hints (relevant CLI verbs/commands without giving the answer), Verification steps, Peek at solution (pointer to `solutions/`), Concept reinforcement, Cleanup.
- **No secrets or images in git**: NOS images (cEOS, SR Linux, etc.) are pulled separately on the VM. The `images/` directory holds notes/links only.

## Deployment Model

- Source of truth: this directory (pushed to a git remote).
- Target: a Debian/Ubuntu VM on Proxmox with Docker + containerlab installed.
- Deploy mechanism: `git pull` on the VM (or bare repo + post-receive hook — TBD when VM exists).
- Labs are deployed from the VM with `cd labs/NN-... && sudo containerlab deploy`.

## Working Style for Claude

- When adding a new lab, create the full directory structure (topology + configs/ + solutions/ + README.md) in one go.
- **Always update the top-level `README.md` Lab Index** when adding, renaming, or removing a lab. The index has columns: `# | folder-link | topic | status | reviewed`. Status flips `Ready` when content is complete; the `Reviewed` column is updated by the user (not Claude) after they've actually deployed and validated the lab end-to-end. Leave `Reviewed` as `—` when adding new labs.
- **Concept deep-dives belong in `docs/concepts/`.** When a learner question goes beyond the scope of a single lab README (e.g. "router vs L3 switch", "what's actually in an Ethernet frame", "how does ARP cache aging work"), write a focused standalone Markdown file under `docs/concepts/` instead of bloating a lab README. Link to it from the relevant lab's "Concepts cheat-sheet" or from the top-level README's "Concepts" section. Update both indices.
- **Verify EOS syntax against the local EOS User Guide PDF before writing configs.** A local copy of the Arista EOS User Guide lives at the repo root as `EOS-User-Manual.pdf` (gitignored). When writing any non-trivial config block — especially for EVPN, MLAG, BGP unnumbered, VARP, VRF, anycast gateway, AAA, or any other feature where syntax has shifted across EOS versions — read the relevant chapter of the PDF via the Read tool (use `pages` parameter for navigation, max 20 pages per call) and confirm the exact command syntax instead of relying on memory. Cite the PDF version (current: 4.36.0F) in lab READMEs when the syntax is version-sensitive. Don't silently assert syntax correctness for things Claude hasn't either tested or verified against the manual.
- **Cross-reference, don't re-paste.** When a lab is a sequel to an earlier lab (same underlay, adds a feature), reference the previous topology/config explicitly ("starter assumes lab 27 underlay") rather than re-pasting tens of lines of identical config. Keeps labs DRY and makes the *new* concept the obvious focus of the lab.
- **Re-Read before Edit in long sessions.** Edit tool requires a Read in the same conversation. If you've written a file earlier in the session, you must Read it again before the next Edit (Write doesn't count as Read for Edit purposes). Failing this produces "File has not been read yet" errors mid-batch — re-Read defensively for files you haven't touched in a while.
- **Always ground labs in real production scenarios.** Lab READMEs should open the "Goal" section by framing the lab around a realistic operational situation a DC/cloud-provider engineer would actually face — not abstract "ping A from B" exercises. Examples: "you're rolling out a new tenant VLAN across two access switches", "the on-call engineer just got paged because the gateway flipped", "marketing wants their dev environment isolated from production". The scenario motivates the topology and the task, and makes the lab memorable. Concepts get learned via the *problem*, not the abstraction.
- **Anchor every lab to the curriculum's continuous narrative.** The repo has a single overarching story (`STORY.md`) — the learner is a fresh-grad junior at "The Company" who grows into a senior DC architect across 7 phases as The Company itself grows from a small hosting shop into a multi-DC cloud provider. Every lab README must include a `> **Story chapter:**` callout right after the `> **Format:**` callout, identifying the phase, the learner's role at that point, an approximate timeline marker, and a one-or-two-sentence story beat. Link to `STORY.md` from the callout. The per-lab Real-world scenario then expands that beat technically. When generating new labs, decide which phase they belong to and write the story beat first.
- **Professional-practice docs live in `docs/practice/`.** Beyond technical concept docs (`docs/concepts/`), the repo also has standalone guides for the non-technical-but-essential parts of senior engineering: migration planning, incident response, ADRs, runbooks. Templates live under `docs/practice/templates/`. When generating new practice docs, include a copy-pasteable template alongside the prose. Each practice doc ends with a Story-arc references block linking back to the phase(s) where it becomes relevant. The Phase-end "Skills earned beyond the labs" blocks in `STORY.md` should reference the relevant practice doc.
- For lab READMEs, include a Mermaid topology diagram by default.
- Don't fetch or commit NOS images. If a lab needs one, document the source in `images/` and reference the image tag in the topology.
- When proposing topology changes, show the diff against the existing `topology.clab.yml` clearly.
- Assume the user is **learning** — explain the *why* of networking choices in lab READMEs, not just the *what*.
- **Be honest about cEOS non-enforcement.** Hardware/ASIC dataplane features (HW QoS shaping/policing, PFC/ETS/DCB, storm-control, DHCP-snooping/DAI/IPSG drops, HW port-security, NAT/NAT64 datapath, CoPP enforcement) are config-accepted but NOT enforced in a cEOS container. When a lab teaches such a feature, mirror the **labs 38 and 47 honesty pattern**: keep the (correct) config so the learner still learns the syntax, but add a clear callout stating it won't enforce in cEOS and what they'd actually observe (and, where useful, split Verification into "on production hardware" vs "on cEOS"). Never silently claim a drop/cap/blackhole happens when the container won't do it.
- **Recurring lab-authoring pitfalls to self-check (the bug classes the big review found most often):** (1) Cisco-IOS-isms cEOS rejects — e.g. `ip nat enable`/`ip nat source list ... overload`, `bfd all-interfaces`, `neighbor X fall-over bfd`, `graceful-restart restart-time`, `ip dhcp snooping trust`, `ip ospf passive`, `is-type level-2-only` (use EOS forms: `bfd default`, `neighbor X bfd`/`ip ospf neighbor bfd`, `graceful-restart stalepath-time`, `is-type level-2`); (2) management/automation/host nodes that can't reach every device because all links share one /24 with only one interface addressed, or mismatched /30 ends — verify end-to-end reachability in the addressing plan; (3) verification steps that can't produce the claimed output (pinging a Null0-routed prefix, self-ping, expecting a VARP virtual MAC in a MAC table); (4) Alpine-based helper images (`network-multitool`, FRR) where `apt` doesn't exist (use `apk`, or note the tool is preinstalled).
- **EOS syntax must be validated on a RUNNING cEOS, not just the manual or memory.** A 2026-05 live-validation pass against `ceos:4.35.4M` (lab VM, `root@192.168.1.45`) found that static review + the EOS manual were NOT sufficient — the manual documents hardware EOS, but the cEOS container rejects or can't run a whole class of commands. Spin up a 1-node cEOS rig and load each solution via `configure session` (errors print as `% Invalid input` / `% Unavailable command (not supported on this hardware platform)`; `abort` to discard) before trusting any non-trivial config. Empirically confirmed on cEOS 4.35.4M:
  - **Not supported at all** (`% Unavailable command … hardware platform`) → reframe the lab as hardware-only/study (keep the production config, add a clear "won't load on cEOS" callout, like labs 38/47): `policy-map type qos` + `class`/`set dscp`/`police`, `tx-queue N` egress scheduling, `match ip access-group` in a class-map, `storm-control`, `control-plane`/CoPP, `ip arp inspection`/`ip verify source` (DAI/IPSG), port-security.
  - **Valid EOS but the wrong form was used** (`% Invalid input`): `bfd interval … min-rx … multiplier …` is **interface-level**, not global; `ip ospf passive` → `passive-interface default` + `no passive-interface <uplink>` under `router ospf`; `vrrp <id> description` does not exist (use `vrrp <id> ip|priority-level|preempt`); `soft-reconfiguration inbound [all]` is unsupported (EOS keeps the Adj-RIB-In; just remove it); IP-neighbor peer-group is `neighbor <ip> peer group NAME` (space) while unnumbered is `neighbor interface EtX peer-group NAME` (hyphen); `remote-as external` is unsupported (use a numeric ASN); pool-based PAT `ip nat source dynamic … pool … overload` fails — interface PAT is `ip nat source dynamic access-list X overload` (no pool) and 1:1 is `ip nat source static <in> <out>`; in an `address-family`, put **all** `neighbor X activate` lines FIRST, then the per-neighbor `route-map`/`route-reflector-client`/`send-community` lines (interleaving makes the next `activate` fail).
  - **Silent keyword expansion (worst kind — config-accepted but wrong):** under `router isis … / address-family ipv4 unicast`, `redistribute ospf` resolves to `redistribute ospfv3` (the IPv6 process) — so OSPFv2→IS-IS redistribution silently carries no IPv4 routes. `redistribute ospf` works correctly under `router bgp` and `router ospf`, so prefer OSPF↔BGP for redistribution labs. Always `show active` / `show running-config` after configuring to catch silent rewrites.
  - **Validating config via `docker exec Cli`:** the pipe runs at privilege 1 — prefix with `enable` (`printf "enable\nconfigure\n…"`); extended `ping … source … repeat` also needs enable. Bulk-feeding a config with nested `address-family` sub-blocks via the pipe does NOT reliably keep the sub-mode — the **authoritative** validation is to boot the node with the solution as its `startup-config` (cEOS applies it natively) and then check routes/pings.
  - Loop: edit locally → `tar czf - $(git diff --name-only) | ssh root@<vm> 'tar xzf - -C /root/containerlab'` → run the deploy/apply harness (or boot-with-solution) → only commit once the live apply is clean.
