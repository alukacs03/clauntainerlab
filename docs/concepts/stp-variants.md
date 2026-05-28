# Spanning Tree: the Family of Variants

> STP, RSTP, MSTP, PVST+, RPVST+, Rapid PVST+, and a handful of vendor extras. They all solve "no L2 loops"; they differ in convergence speed, per-VLAN-ness, and how much of the spec is proprietary.

## What they all do

Build a loop-free **spanning tree** over your L2 topology. Block redundant links to break loops. Recompute the tree when something changes.

The differences are:

- **Convergence speed** — how fast the tree settles after a change.
- **Per-VLAN behavior** — one tree for all VLANs, or one tree per VLAN, or trees per group of VLANs.
- **Vendor-specific vs standard**.

## Quick comparison

| | STP | RSTP | MSTP | PVST+ | RPVST+ (Rapid PVST+) |
|---|---|---|---|---|---|
| IEEE Spec | 802.1D (1990) | 802.1w (2001), folded into 802.1D-2004 | 802.1s (2002), folded into 802.1Q-2003 | None (Cisco proprietary) | None (Cisco proprietary) |
| Convergence | ~30–50 seconds | <1 second on P2P links | <1 second | ~30–50 seconds | <1 second |
| Trees | One for whole bridge | One for whole bridge | N instances, each carries M VLANs | One per VLAN | One per VLAN |
| Scaling | Best | Best | Best (group VLANs by traffic engineering) | Worst (BPDU per VLAN) | Better than PVST+, still per-VLAN BPDUs |
| Vendor | All | All | All | Cisco | Cisco |
| Use today | Almost never | Common default | Large multi-vendor designs needing per-VLAN-group load balancing | Old Cisco shops | Cisco shops |

## STP (802.1D, the original)

The granddaddy. One tree for the whole bridge, regardless of VLANs. Convergence has three timers stacked up to ~50 seconds total (Listening → Learning → Forwarding). Painfully slow.

You should never see this on a modern device. Everything switched to RSTP-or-newer by ~2005.

If you encounter STP in production today, it's either misconfigured ("we set bridge mode to STP" by accident) or an ancient device. Replace.

## RSTP (802.1w)

Rapid STP. Same tree concept, dramatically faster convergence via **proposal/agreement handshakes** on point-to-point links. Designated ports propose, peers agree, the port goes to forwarding within ~1 second instead of 30s.

This is the **modern default** on most switches (cEOS included). One spanning tree across all VLANs; if you need per-VLAN trees you go to MSTP or PVST.

Port roles in RSTP: **Root, Designated, Alternate, Backup**. Port states: **Discarding, Learning, Forwarding** (the old Listening/Blocking are merged into Discarding).

Lab 04 covers RSTP fundamentals.

## MSTP (802.1s, now part of 802.1Q)

Multiple Spanning Tree. The standard answer to "I want trees per VLAN, but not 4000 separate trees".

You define **MST instances**. Each instance is its own spanning tree. You map VLANs to instances. Example:

- MSTI 0 (the "default" / CIST): no VLANs by default; can be the catch-all.
- MSTI 1: VLANs 10, 11, 12 (low-priority traffic, one tree).
- MSTI 2: VLANs 20, 21, 22 (high-priority traffic, different tree, different root).

By choosing different roots per MSTI, you can **load-balance** between switches: traffic in MSTI 1 takes path A, traffic in MSTI 2 takes path B. Both paths are active for some VLAN somewhere — no single link is idle.

Convergence: RSTP-fast within each instance.

MSTP regions: switches sharing the same MST config name + revision form a "region". Inside a region, MSTIs work as designed. Between regions, only the CIST runs — regions appear as single big switches to each other.

**When to use**: large designs (5+ switches, dozens of VLANs) where you want per-VLAN-group load balancing without the overhead of per-VLAN BPDUs.

Complexity cost is real. Many networks just run RSTP.

## PVST+ (Cisco)

Per-VLAN Spanning Tree Plus. Cisco's answer to "I want per-VLAN trees" before MSTP standardized. Runs a full STP instance per VLAN — separate root, separate BPDUs, separate convergence per VLAN.

Pros: simple per-VLAN load balancing — different root per VLAN spreads traffic.
Cons: ~50s convergence per VLAN (it's classic STP under the hood) + a BPDU per VLAN per 2s = a LOT of BPDUs at scale.

Mostly replaced by RPVST+ even within Cisco shops.

## RPVST+ (Cisco)

**Rapid PVST+**. Per-VLAN trees + RSTP-style fast convergence per VLAN. Cisco's working default for many deployments.

Same pros as PVST+ (per-VLAN load balancing) but with sub-second convergence per VLAN.

Cons: still one BPDU per VLAN per 2 seconds. At 500 VLANs, that's significant CPU on every switch.

## What runs by default where?

- **Cisco**: RPVST+ is the default on most Catalyst and Nexus platforms.
- **Arista**: RSTP is the default. Per-VLAN behavior is achieved via MSTP if needed.
- **Juniper**: RSTP default.
- **HP / Aruba**: RSTP or MSTP, varies.

Mixed-vendor environments: stick to RSTP or MSTP (open standards). Don't try to interop PVST+ with non-Cisco — it works in spec but is full of edge cases.

## Interaction with MLAG / EVPN

- **Within an MLAG pair**: the peer-link doesn't run STP (it's a peer-link, not a regular trunk). The MLAG bundle to downstream is one logical link, so no loop from STP's perspective.
- **MLAG peers facing the rest of the network**: STP still runs. MLAG peers usually have priorities set so they jointly own the root (lower priority than other devices) for predictable convergence elsewhere.
- **EVPN fabric**: no L2 loops in the underlay (it's all routed). STP runs at the access edge (between leaves and downstream non-EVPN switches) and may stop at the leaf boundary.

## STP-related security & operational features

(All standard regardless of variant; pair with whichever STP you run.)

| Feature | What it does | Where to put it |
|---|---|---|
| **PortFast** | Skip learning/listening on edge ports | Host-facing access ports |
| **BPDU Guard** | Err-disable port if BPDU received | Host-facing access ports (with PortFast) |
| **Root Guard** | Reject superior BPDUs on a port (keep root location stable) | Designated ports facing less-trusted switches |
| **Loop Guard** | If BPDUs stop arriving on a root/alternate port, don't transition to forwarding | Root + alternate ports of trunks |
| **Bridge Assurance** (Cisco) | Send BPDUs on all operational ports; lack of BPDUs = problem | Trunks between known switches |
| **BPDU Filter** | Silently drop BPDUs in/out — **almost always wrong**, use BPDU Guard instead | Avoid; use only if you really know why |

Lab 05 covers PortFast, BPDU Guard, and Root Guard. See also the [STP protections checklist](../labs/05-stp-protections/README.md).

## TCN (Topology Change Notification)

When a port goes up/down, the bridge floods a **TCN** through the tree. Every other bridge flushes its MAC table (or ages it out aggressively) to relearn after the change.

A flapping port → continuous TCNs → continuous MAC table flushes → traffic floods to everyone (because no MAC entries) → CPU spike → outage.

Mitigation: **fix flapping links**. Don't try to suppress TCNs; they're the symptom, not the cause.

## Convergence times (rough)

| Event | Classic STP | RSTP/RPVST+/MSTP |
|---|---|---|
| Link up on edge port | ~30s | Instant (PortFast) |
| Link up on trunk | ~30–50s | <1s |
| Link down (designated) | ~30s | <1s |
| Root bridge failure | ~30–50s | ~2–6s (worst case in large trees) |

Real-world note: even sub-second STP convergence is *not* fast enough for some applications. Voice and some clustered services notice. That's why MLAG and EVPN are preferred for "no convergence visible to apps" — they keep both paths active.

## When picking for a new design

- **Default**: RSTP. Simplest, fastest, standard, well-understood.
- **Need per-VLAN load balancing across multiple physical paths**: MSTP. Define instances by VLAN groups; pick different roots per instance.
- **Cisco-only shop and you want simple**: RPVST+ is fine.
- **Need active/active redundancy without spanning tree convergence at all**: MLAG (lab 14) or EVPN (chapter 7). STP is then a safety net, not the primary mechanism.

## Where this matters in the lab series

- **Lab 04** — RSTP fundamentals (root election, port roles, convergence).
- **Lab 05** — STP protections (PortFast, BPDU Guard, Root Guard).
- **Lab 14** — MLAG (eliminates STP between the MLAG peers).
- **Lab 30+** — EVPN fabric (no L2 loops in the underlay, STP only at the access edge).
