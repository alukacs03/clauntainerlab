# Lab 29 — VXLAN Data Plane

> **Format:** Hands-on. Two leaves with a static VXLAN tunnel between them over the routed underlay. Hosts in the same /24 on different leaves communicate at L2 over an L3 fabric. No EVPN yet (lab 30). Reference answer in [`solutions/`](solutions/).

## Real-world scenario

You built a clean spine-leaf fabric (lab 27/28). It's all L3 — every leaf is L3 down to the access edge. Great for routing, but customers and applications still want **L2 adjacency**: "I want VLAN 100 to span multiple racks because my VM moves between hosts." A pure L3 fabric can't deliver that directly.

**VXLAN** solves it. Encapsulate Ethernet frames inside UDP/IP packets. The L3 fabric carries the encapsulated traffic between leaves; each leaf "decaps" and delivers the frame to local hosts as if the source were on the same VLAN locally. Hosts believe they're L2-adjacent; the fabric is actually routing everything.

This lab uses **static VXLAN** (no control plane). Lab 30 adds EVPN for proper signaling.

## Goal

By the end you should be able to answer:

- What's a **VTEP** (VXLAN Tunnel Endpoint), and why is it usually a loopback?
- What's a **VNI**, and how does it relate to VLAN ID?
- How does **VXLAN encapsulation** wrap an Ethernet frame? Where do source/destination IPs come from?
- What's **head-end replication** for BUM traffic, and what does it replace from traditional L2?
- Why is VXLAN's 24-bit VNI a big deal compared to 12-bit VLAN ID?

## Topology

```mermaid
graph TB
    h1[h1<br/>10.10.10.10/24<br/>VLAN 100] --> leaf1
    h2[h2<br/>10.10.10.20/24<br/>VLAN 100] --> leaf2
    leaf1[leaf1<br/>VTEP 11.11.11.11<br/>AS65001] ==L3 underlay== spine1[spine1<br/>AS65100]
    leaf2[leaf2<br/>VTEP 22.22.22.22<br/>AS65002] ==L3 underlay== spine1
    leaf1 -.VXLAN tunnel VNI 10100.-> leaf2
```

Same routed underlay as labs 27/28 (simplified to 1 spine here). Each leaf has TWO loopbacks: one for router-id/BGP, one for VTEP. The two hosts are in the same /24 — VXLAN makes them L2-adjacent.

## Theory primer

### VXLAN encapsulation

VXLAN wraps an Ethernet frame in **UDP/IP**. The complete encapsulation looks like:

```
[ outer Ethernet ][ outer IP src=VTEP1 dst=VTEP2 ][ UDP dst=4789 ][ VXLAN header VNI=10100 ][ inner Ethernet frame from h1 to h2 ]
```

- **Outer IP**: between VTEPs. Source = source leaf's VTEP loopback; destination = destination leaf's VTEP loopback (or a flood list).
- **UDP destination port 4789** (IANA-assigned).
- **VXLAN header** carries the 24-bit VNI (vs 12-bit VLAN ID).
- **Inner Ethernet frame** is what the host actually sent — preserved exactly.

The L3 fabric routes the outer IP packet. When it arrives at leaf2's VTEP, leaf2 strips the outer encap, sees the VNI, maps it to local VLAN 100, and delivers the inner frame to the access port for h2.

### VTEP (VXLAN Tunnel Endpoint)

A device that encapsulates / decapsulates VXLAN. Every leaf is a VTEP.

VTEPs are addressed by an **IP address**, typically a loopback on the leaf. Why a separate loopback (not the BGP router-id loopback)?

- Allows mobility: anycast VTEP (multiple leaves share the same VTEP IP) is a real pattern for MLAG'd pairs.
- Clear separation between underlay routing identity and overlay encapsulation source.
- Easier to filter / monitor VTEP-specific traffic in the underlay.

Convention here: `Loopback0` for router-id, `Loopback1` for VTEP source.

### VNI vs VLAN ID

- **VLAN ID**: 12-bit (4094 usable). Local-significance on the wire.
- **VNI**: 24-bit (~16 million). Globally significant in the overlay.

In configuration, you **map** local VLANs to global VNIs:

```
vxlan vlan 100 vni 10100
```

"Frames arriving on VLAN 100 → encapsulate with VNI 10100. Frames arriving from the fabric with VNI 10100 → decap as VLAN 100."

Convention: VNI = VLAN × 100 (e.g., VLAN 100 → VNI 10100). Easy to remember.

### Head-end replication (HER) / Ingress replication

For BUM traffic (Broadcast, Unknown unicast, Multicast — like ARP requests, initial floods), VXLAN has two delivery modes:

- **Multicast-based** — VTEPs join a multicast group; BUM frames are sent to that group. Requires multicast-capable underlay. Older, complex.
- **Head-end replication (HER) / Ingress replication** — source VTEP unicasts a copy to each known remote VTEP. No multicast needed. Standard in modern fabrics.

In static VXLAN (this lab), you list the remote VTEPs manually:

```
vxlan vlan 100 flood vtep 22.22.22.22
```

"For VLAN 100 BUM, replicate to VTEP 22.22.22.22." For 50 leaves, you'd list 49 VTEPs. **Doesn't scale operationally** — that's why EVPN exists (lab 30 auto-discovers VTEPs).

### Why VXLAN matters

- **4096 → 16M segments**: VNIs eliminate the VLAN scaling ceiling.
- **L2 over L3**: VLANs span racks/sites without flat L2.
- **No STP across the fabric**: underlay is routed, overlay is encapsulated unicast.
- **VM mobility**: a VM moves between leaves, just plug into the same VNI, no IP change.

## Your task

1. Add `Loopback1` on each leaf with a VTEP IP (`11.11.11.11`, `22.22.22.22`). Advertise via BGP.
2. Configure `vlan 100` on each leaf.
3. Make leaf-to-host port an access port in VLAN 100.
4. Configure the Vxlan1 interface on each leaf:
   - `vxlan source-interface Loopback1`
   - `vxlan vlan 100 vni 10100`
   - `vxlan vlan 100 flood vtep <other-leaf-VTEP-IP>`
5. Verify the VTEP loopbacks reach each other via BGP underlay.
6. Verify h1 ↔ h2 ping works (over the VXLAN overlay).

## Hints

```
interface Loopback1
   ip address <vtep-ip>/32

interface Vxlan1
   vxlan source-interface Loopback1
   vxlan udp-port 4789
   vxlan vlan <vlan> vni <vni>
   vxlan vlan <vlan> flood vtep <remote-vtep-ip>
```

Verification:

```
show vxlan vtep
show vxlan address-table
show vxlan flood vtep
show interfaces Vxlan1
```

## Deploy

```bash
cd ~/containerlab/labs/29-vxlan-data-plane
sudo containerlab deploy
```

## Verification

### 1. Underlay reachability between VTEPs

```bash
docker exec -it clab-vxlan-data-plane-leaf1 Cli
ping 22.22.22.22
```

✅ via BGP underlay through spine1.

### 2. VXLAN config in place

```
show interfaces Vxlan1
show vxlan vtep
```

Should show source-interface Loopback1, VNI mapping, flood-list entries.

### 3. h1 ↔ h2 connectivity

```bash
docker exec clab-vxlan-data-plane-h1 ping -c 3 10.10.10.20
```

✅. First ping may be slow (initial ARP via flood-list); subsequent pings fast.

### 4. Watch the encapsulation on the underlay

```bash
sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' clab-vxlan-data-plane-leaf1) -n tcpdump -i eth1 -nn udp port 4789
```

Run a ping from h1 to h2. You'll see UDP/4789 packets between the VTEPs carrying the encapsulated ICMP frames.

### 5. MAC table after flooding

```
show vxlan address-table
```

Should show h2's MAC learned via remote VTEP `22.22.22.22`. This is data-plane learning — VTEP saw a frame from h2's MAC arriving via the VXLAN tunnel, learned where it lives.

In static VXLAN this is "learn-from-encap" — fragile at scale. EVPN replaces it with control-plane learning (lab 30).

### 6. Inspect the flood list

```
show vxlan flood vtep
```

Each VLAN with its flood-VTEP list. Adding a third leaf would require updating both existing leaves' flood lists manually. **This is what doesn't scale.** EVPN auto-discovers.

## Peek at solution

- [`solutions/leaf1.cfg`](solutions/leaf1.cfg), [`solutions/leaf2.cfg`](solutions/leaf2.cfg), [`solutions/spine1.cfg`](solutions/spine1.cfg)

## Concepts cheat-sheet

- **VTEP** — VXLAN Tunnel Endpoint; the device that encaps/decaps; loopback-addressed.
- **VNI** — 24-bit overlay segment ID. ~16M vs 4094 VLANs.
- **VXLAN encap** — outer Eth + outer IP (VTEP→VTEP) + UDP/4789 + VXLAN header + inner frame.
- **Head-end replication** — unicast BUM copies to each remote VTEP. Default modern approach.
- **Static VXLAN flood-list** — manual remote VTEP list. Doesn't scale. EVPN fixes it (lab 30).
- **Data-plane learning** — VTEP learns remote MACs from received encap frames. Fragile; EVPN does control-plane learning.

## Production deployment notes

- **MTU planning**: VXLAN adds ~50 bytes of overhead. Set underlay MTU to **jumbo (9000+)** so inner frames can be standard 1500-byte Ethernet without fragmentation.
- **Loopback-as-VTEP**: standard. Different loopback from BGP router-id (more flexibility for anycast VTEP later).
- **Don't deploy static VXLAN in production at scale** — flood-list management is painful. Use EVPN.
- **UDP source-port** is hashed by the platform across the underlay for ECMP. Different inner flows produce different outer source ports → uniform ECMP distribution.

## What's missing (deliberately)

- **EVPN control plane** — lab 30.
- **Type 5 routes / L3 overlay** — lab 31.
- **Anycast gateway in EVPN** — lab 32.
- **Multi-site DCI** — lab 33.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
