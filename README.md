# Containerlab Labs

A personal networking learning journey, one lab at a time, using [containerlab](https://containerlab.dev).

## Setup

Labs run on a dedicated VM on a Proxmox server. See [`docs/vm-setup.md`](docs/vm-setup.md) for VM provisioning and containerlab installation.

## Lab Index

| # | Lab | Topic | Status |
|---|-----|-------|--------|
| _none yet_ | | | |

Each lab lives under `labs/NN-name/` and has its own README explaining goals, topology, and how to run it.

## Running a Lab

On the VM, after `git pull`:

```bash
cd labs/NN-name
sudo containerlab deploy
# ... explore, configure, break things ...
sudo containerlab destroy
```

## Repo Conventions

See [`CLAUDE.md`](CLAUDE.md) for layout and conventions.
