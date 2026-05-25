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
│       ├── configs/     # per-node startup configs
│       └── README.md    # what this lab teaches, how to run, what to observe
├── images/              # notes on NOS image sourcing (not the images themselves)
└── scripts/             # shared helpers (deploy, bootstrap, teardown)
```

## Conventions

- **Lab naming**: `NN-short-kebab-name` where `NN` is a zero-padded sequence number reflecting learning order, not topic grouping. Topics belong in the lab's README.
- **Topology files**: always named `topology.clab.yml` inside the lab directory so `containerlab deploy` works without `-t`.
- **Configs**: per-node startup configs go under `configs/<node-name>.cfg` (or vendor-appropriate extension). Reference them from `topology.clab.yml` via `startup-config`.
- **Lab READMEs**: must include — Goal, Topology diagram (Mermaid preferred for simple, PlantUML for complex), How to deploy, Things to try / verify, Cleanup.
- **No secrets or images in git**: NOS images (cEOS, SR Linux, etc.) are pulled separately on the VM. The `images/` directory holds notes/links only.

## Deployment Model

- Source of truth: this directory (pushed to a git remote).
- Target: a Debian/Ubuntu VM on Proxmox with Docker + containerlab installed.
- Deploy mechanism: `git pull` on the VM (or bare repo + post-receive hook — TBD when VM exists).
- Labs are deployed from the VM with `cd labs/NN-... && sudo containerlab deploy`.

## Working Style for Claude

- When adding a new lab, create the full directory structure (topology + configs/ + README.md) in one go.
- For lab READMEs, include a Mermaid topology diagram by default.
- Don't fetch or commit NOS images. If a lab needs one, document the source in `images/` and reference the image tag in the topology.
- When proposing topology changes, show the diff against the existing `topology.clab.yml` clearly.
- Assume the user is **learning** — explain the *why* of networking choices in lab READMEs, not just the *what*.
