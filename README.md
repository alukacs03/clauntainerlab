# Containerlab Labs

A personal networking learning journey using [containerlab](https://containerlab.dev), Arista cEOS, and Claude as a study companion.

## What this project is

The goal is to learn networking concepts — VLANs, routing, redundancy, switching internals — on systems that look and feel like the real thing, not on toy abstractions. Containerlab gives us multi-node topologies of actual NOS images (primarily **Arista cEOS** here) running as containers, so the CLI, config style, and behavior match what you'd encounter on real production gear.

Each lab is built as a **hands-on exercise**, not a demo: the starter configs only get the devices booting, and the learner builds the actual configuration themselves, guided by a theory primer and a task spec in the lab README. A reference solution is provided in `solutions/` for after you've tried — peek when stuck, compare when done.

Claude (Claude Code, specifically) is used throughout to design the labs, explain concepts in the READMEs, and help debug when something doesn't behave as expected.

## Setup

Labs run on a dedicated VM on a Proxmox server. See [`docs/vm-setup.md`](docs/vm-setup.md) for VM provisioning, Docker + containerlab installation, and the manual Arista cEOS image import procedure.

## Lab Index

| # | Lab | Topic | Status |
|---|-----|-------|--------|
| 01 | [vlan-basics](labs/01-vlan-basics) | Access ports, trunks, 802.1Q tagging | Ready |
| 02 | [inter-vlan-svi](labs/02-inter-vlan-svi) | Inter-VLAN routing with SVIs | Ready |

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

Planned labs. Order may shift as topics naturally pull each other in. Strikethrough = done (see Lab Index above).

| # | Lab | What it adds |
|---|-----|--------------|
| ~~01~~ | ~~VLAN basics~~ | Access ports, trunks, 802.1Q tagging |
| ~~02~~ | ~~Inter-VLAN routing (SVI)~~ | L3 switch role, virtual VLAN interfaces |
| 03 | First-hop redundancy (VRRP) | Gateway failover (active/standby) |
| 04 | Spanning Tree | L2 loop avoidance, root election, port states |
| 05 | Link Aggregation (LACP) | Multi-cable bundle to one switch |
| 06 | MLAG | LACP bundle terminated on two switches — active/active, no switch SPOF |
| 07 | Anycast Gateway (VARP) | Both MLAG peers serve the same gateway IP simultaneously |
| 08 | DHCP relay | `ip helper-address`, host-side automation |
| 09 | OSPF basics | Dynamic L3 routing across multiple switches |
| 10 | ACLs | Filtering traffic between subnets/VLANs |
| 11 | NAT & edge role | When an L3 switch becomes an actual router |
| 12+ | BGP / VRF / VXLAN+EVPN | Datacenter fabric: routed underlay, overlay tenants |

## Concepts

Standalone deep-dives on questions that come up while doing the labs:

- [L3 Switch vs. Router](docs/concepts/l3-switch-vs-router.md) — when does an L3 switch stop being a switch and become a router?

## Repo Conventions

See [`CLAUDE.md`](CLAUDE.md) for the directory layout, the hands-on lab format, and the rules Claude follows when adding new labs.
