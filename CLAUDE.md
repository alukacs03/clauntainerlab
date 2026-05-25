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
- For lab READMEs, include a Mermaid topology diagram by default.
- Don't fetch or commit NOS images. If a lab needs one, document the source in `images/` and reference the image tag in the topology.
- When proposing topology changes, show the diff against the existing `topology.clab.yml` clearly.
- Assume the user is **learning** — explain the *why* of networking choices in lab READMEs, not just the *what*.
