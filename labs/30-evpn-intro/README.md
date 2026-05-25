# Lab 30 — EVPN Control Plane (Type 2 + Type 3)

> **Format:** Hands-on. Same VXLAN topology as lab 29, but the flood-list is replaced by **EVPN BGP signaling**. No more manual VTEP lists; auto-discovered via BGP. Reference answer in [`solutions/`](solutions/).

## Real-world scenario

Lab 29 got VXLAN working with a manual flood-list. Adding a third leaf means editing every other leaf's flood-list. With 50 leaves and 200 VLANs, that's thousands of lines and a guarantee that someone forgets one and traffic black-holes.

**EVPN** (Ethernet VPN) is BGP's way of carrying overlay information automatically. Each VTEP **announces via BGP**: "I am VTEP X, I have MAC AA:BB:CC:DD:EE:FF in VNI 10100." Every other VTEP receives the announcement and updates its overlay tables automatically. Adding a new leaf? Just turn on EVPN — it joins the fabric and is discovered by everyone else without touching their configs.

This lab swaps lab 29's static VXLAN for EVPN-signaled VXLAN. Same topology, same data plane (VXLAN/UDP encap), but the **control plane** is now BGP EVPN.

## Goal

By the end you should be able to answer:

- What's the difference between **VXLAN (data plane)** and **EVPN (control plane)**?
- What are EVPN **Type 2** and **Type 3** routes?
- What's a **Route Distinguisher (RD)** and **Route Target (RT)** in EVPN's context?
- Why does the **spine need `next-hop-unchanged`** on EVPN routes in eBGP designs?
- What does `redistribute learned` do under the VLAN service instance?

## Topology

Same as lab 29: 1 spine, 2 leaves, hosts in same /24.

## Theory primer

### EVPN's job

EVPN distributes overlay information via BGP. Every VTEP becomes a BGP speaker; routes carry MAC/IP/VTEP-IP/VNI bindings.

This replaces:
- **Flood-and-learn** at L2 → explicit Type 2 announcements
- **Static flood-lists** for BUM → automatic Type 3 announcements
- **Discovery via probing** → discovery via BGP

### EVPN address family

BGP normally carries IPv4 (`address-family ipv4`) or IPv6. For EVPN, there's a new address-family:

```
address-family evpn
   neighbor X activate
```

Same BGP session can carry IPv4 (underlay) and EVPN (overlay). One TCP connection, multiple address-families.

### EVPN route types

The most common ones:

- **Type 2 (MAC/IP)** — "VTEP X has host with MAC Y and IP Z in VNI N." Used for L2 forwarding learning and ARP suppression.
- **Type 3 (Inclusive Multicast)** — "VTEP X is participating in VNI N. Send BUM frames for VNI N to me." Used to build the per-VNI flood list automatically.
- **Type 5 (IP Prefix)** — "Prefix P is reachable via VTEP X." Used for L3 overlay / inter-VNI routing (lab 31).

Type 2 and Type 3 are what we use here. Type 5 is lab 31's focus.

### Route Distinguisher (RD)

A prefix added to make EVPN routes globally unique even when multiple VTEPs advertise the same MAC address (which they shouldn't normally, but the protocol handles it).

Convention: `<router-id>:<VNI>` or `<router-id>:<small-id>`. Each VTEP picks its own; doesn't need to match across VTEPs.

```
vlan 100
   rd 1.1.1.1:10100
```

### Route Target (RT)

Determines which VTEPs **import** the routes for this VNI. Routes tagged with RT `10100:10100` get imported by any VTEP that imports RT `10100:10100`.

Convention: `<VNI>:<VNI>` so all leaves importing VNI 10100 share the same RT and form the EVPN domain for that VNI.

```
vlan 100
   route-target both 10100:10100
```

`both` = both import and export.

### `redistribute learned`

Tells EVPN to advertise locally-learned MACs (from the data plane on access ports) as Type 2 routes. Without this line, the leaf knows about local MACs but doesn't tell other VTEPs.

```
vlan 100
   redistribute learned
```

### `next-hop-unchanged` on spines

In eBGP EVPN: when spine1 receives an EVPN Type 2 from leaf1, the next-hop is leaf1's VTEP IP. Normally spine1 would rewrite the next-hop to itself before forwarding to leaf2 (`next-hop-self` default for eBGP). But spine1 isn't a VTEP — it can't decap VXLAN.

**`next-hop-unchanged`** tells spine1: "don't rewrite the next-hop on EVPN routes. Pass them through unchanged so leaf2 sees leaf1's original VTEP IP as next-hop." Now leaf2 encaps VXLAN with destination IP = leaf1's VTEP, packet goes leaf2 → spine1 → leaf1 at the underlay level, decapped at leaf1.

Without this, VXLAN-encaps target the spine, which can't decap → packets drop.

## Your task

1. On **spine1**:
   - Add `address-family evpn` to the BGP process.
   - Activate both leaf neighbors under EVPN.
   - **Critical**: `neighbor X next-hop-unchanged` for both EVPN neighbors.
   - `send-community extended` for both (EVPN uses extended communities for RT).
2. On **each leaf**:
   - Configure `interface Vxlan1` (same as lab 29 minus the flood-list).
   - Under `router bgp`, add `vlan 100` service instance with RD, RT, `redistribute learned`.
   - Activate EVPN under `address-family evpn` on the spine neighbor.
   - `send-community extended`.
3. Verify EVPN sessions, Type 2 and Type 3 routes, and end-to-end overlay traffic.

## Hints

EVPN service instance (per VLAN/VNI):

```
router bgp <asn>
   vlan <vlan-id>
      rd <router-id>:<vni>
      route-target both <vni>:<vni>
      redistribute learned

   address-family evpn
      neighbor X activate
```

Verification:

```
show bgp evpn summary
show bgp evpn
show bgp evpn route-type mac-ip
show bgp evpn route-type imet
show vxlan vtep
show vxlan address-table
```

## Deploy

```bash
cd ~/containerlab/labs/30-evpn-intro
sudo containerlab deploy
```

## Verification

### 1. EVPN session up

```bash
docker exec -it clab-evpn-intro-leaf1 Cli
show bgp evpn summary
```

The session to spine1 should be Established for EVPN.

### 2. Type 3 (Inclusive Multicast) routes

```
show bgp evpn route-type imet
```

Should show one entry per VTEP/VNI: leaf1 announces "I'm in VNI 10100", leaf2 does the same. Each leaf sees the other.

This **replaces the manual flood-list** from lab 29. BUM traffic for VNI 10100 floods to the union of Type 3 advertisers.

### 3. Type 2 (MAC/IP) routes appear after traffic

```bash
docker exec clab-evpn-intro-h1 ping -c 1 10.10.10.20
```

This triggers an ARP. h1 ARPs broadcast → leaf1 → VXLAN-encap to leaf2 (via Type 3 flood list) → h2. h2 replies; leaf2 learns h2's MAC; leaf2 announces Type 2 EVPN route for h2.

Now:

```
show bgp evpn route-type mac-ip
```

Type 2 entries: h1's MAC at VTEP 11.11.11.11, h2's MAC at VTEP 22.22.22.22.

```
show vxlan address-table
```

Local + remote MAC entries. Remote MAC's VTEP comes from EVPN, not from data-plane learning.

### 4. End-to-end

```bash
docker exec clab-evpn-intro-h1 ping -c 3 10.10.10.20
```

✅. Same as lab 29 but via EVPN control plane now.

### 5. Add a host live and watch propagation

If you add a third host on leaf1 (you'd need to extend the topology — beyond this lab's scope), watching `show bgp evpn` shows the Type 2 route appearing immediately on leaf2. No config changes needed on leaf2. **This is what doesn't scale in static VXLAN.**

### 6. Capture EVPN BGP traffic

```bash
sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' clab-evpn-intro-spine1) -n tcpdump -i eth1 -nn tcp port 179
```

Then trigger an update (e.g., ping from a new MAC). You'll see BGP UPDATE messages for EVPN.

## Peek at solution

- [`solutions/spine1.cfg`](solutions/spine1.cfg), [`solutions/leaf1.cfg`](solutions/leaf1.cfg), [`solutions/leaf2.cfg`](solutions/leaf2.cfg)

## Concepts cheat-sheet

- **VXLAN** = data plane (UDP/4789 encap of L2 frames).
- **EVPN** = control plane (BGP-signaled MAC/IP/prefix/flood info).
- **Type 2** = MAC/IP advertisement.
- **Type 3** = inclusive multicast (BUM flood-list builder).
- **Type 5** = IP prefix advertisement (L3 overlay; lab 31).
- **RD** — globally unique per route in BGP.
- **RT** — controls which VTEPs import the route.
- **`next-hop-unchanged`** — spine must not rewrite VTEP IPs in EVPN.

## Production deployment notes

- **iBGP-EVPN-with-RR** is the most common alternative to eBGP-EVPN. Spines are route reflectors for the EVPN address-family. Cleaner failure semantics for some operators.
- **Loopback for VTEP separate from loopback for router-id** — gives flexibility for anycast VTEP (MLAG'd leaves sharing a VTEP IP).
- **MTU planning** — same as lab 29; jumbo underlay required.
- **Naming conventions**: VLAN N → VNI N×100 is conventional; pick a scheme team-wide.
- **MAC mobility** — when a host moves between leaves, EVPN handles via sequence numbers in Type 2 routes. The "MAC moves too often" alerts you can configure.
- **Test failure modes** — kill a leaf, watch withdrawals propagate via EVPN. Faster than data-plane learning loss.

## What's missing (deliberately)

- **EVPN Type 5 / L3 overlay** — lab 31.
- **EVPN anycast gateway** — lab 32.
- **EVPN multi-homing (MH)** — replaces MLAG; the all-routed alternative.
- **EVPN multi-site** — lab 33.
- **ARP suppression** via EVPN — when a leaf knows the IP→MAC binding for a remote host from a Type 2 route, it can answer local ARP requests without flooding. Massive scale benefit.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
