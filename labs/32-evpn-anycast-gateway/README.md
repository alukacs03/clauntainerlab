# Lab 32 — EVPN Anycast Gateway

> **Format:** Hands-on. Same fabric, single subnet stretched across leaves (lab 30 style), but every leaf is the gateway via anycast SVI. The modern DC default for first-hop redundancy. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 6 · Senior · Year 4. VM mobility started mattering for real. Customers migrate VMs between racks during DRS / maintenance. With per-VLAN gateway on a single leaf pair, every VM that moves to a different leaf either keeps hairpinning to the original gateway leaf, or has to ARP a new gateway. Some applications (databases, load balancers) drop sessions either way. You deploy distributed anycast gateway. See [`STORY.md`](../../STORY.md).

## Real-world scenario

In lab 15, you saw VARP on MLAG pairs (active/active gateway across two switches). EVPN generalizes that idea to **every leaf in the fabric**.

Consider a tenant subnet `10.10.10.0/24` that's stretched across 10 leaves (VMs in rack 1, rack 3, rack 7, etc.). Without anycast gateway: only one leaf is the L3 gateway for the subnet; all VMs send their default-gw traffic to that leaf, even VMs sitting directly on a different leaf. That's a hairpin — packets cross the fabric to one leaf, then come back to another leaf for the destination. Wasteful.

**Anycast gateway**: every leaf that hosts the subnet runs the SAME gateway IP and SAME gateway MAC for it. Every VM's default-gw traffic goes to its **local** leaf, which routes locally. No hairpin. VM moves between leaves — gateway stays the same (no IP change, no ARP refresh, often not even a TCP reset).

This is the closing piece for EVPN-based fabrics.

## Goal

By the end you should be able to answer:

- How is **EVPN anycast gateway** different from VARP (lab 15)?
- What does `ip address virtual` do, and why is it the same on every leaf?
- Why is the same **virtual MAC** required on every leaf?
- What happens when a VM moves from leaf1 to leaf2?
- How does anycast gateway combine with Type 5 routes (lab 31) for full L2+L3 overlay?

## Topology

Same as lab 30: same VLAN 100 on both leaves, h1 on leaf1, h2 on leaf2.

## Theory primer

### Anycast gateway in EVPN context

Same conceptual idea as lab 15's VARP, but applied across many leaves in a routed-fabric design:

- Every leaf hosting the subnet has the SAME IP and SAME MAC for the gateway.
- Hosts ARP for the gateway → their LOCAL leaf responds with the shared MAC.
- L3 traffic from the host hits the local leaf directly — no fabric crossings for the first hop.

This combines with Type 5 routing (lab 31) so inter-subnet traffic also uses the local leaf as the first L3 hop, then crosses the fabric encapsulated via L3 VNI.

### `ip address virtual` (Arista)

Specifies the anycast gateway address. **Same value on every leaf**:

```
interface Vlan100
   vrf TENANT-A
   ip address virtual 10.10.10.254/24
```

No per-leaf `ip address X/24` is needed for this gateway purpose. (Some platforms require a unique per-leaf real IP plus the anycast IP; Arista's `address virtual` is the cleaner one-IP form.)

### Shared virtual MAC

```
ip virtual-router mac-address aa:bb:cc:00:00:01
```

Must be IDENTICAL on every leaf in the fabric. Hosts ARP, get this MAC, send frames to it, the local leaf intercepts.

### Differences from MLAG VARP (lab 15)

| | MLAG VARP (lab 15) | EVPN anycast |
|---|---|---|
| Scope | Two MLAG peers | Every leaf in the fabric |
| Underlay | L2 (MLAG peer-link) | L3 (routed fabric) |
| Mobility | Within MLAG pair | Anywhere in the fabric |
| Scale | 2 leaves per pair | Hundreds of leaves |
| Discovery | Static (MLAG peer config) | EVPN-discovered |

EVPN anycast gateway supersedes VARP in modern fabric designs. VARP remains relevant for non-EVPN MLAG deployments.

## Your task

1. On both leaves:
   - Set `ip virtual-router mac-address aa:bb:cc:00:00:01` globally.
   - Create `interface Vlan100` in VRF TENANT-A.
   - Set `ip address virtual 10.10.10.254/24` (same on both).
   - Add L3 VNI binding: `vxlan vrf TENANT-A vni 50001`.
2. Configure the EVPN VRF instance (RD/RT/redistribute connected) per lab 31.
3. Verify both h1 and h2 see `10.10.10.254` as gateway with the same MAC.
4. h1 ↔ h2 ping works (intra-subnet, via EVPN-stretched VLAN 100).
5. Bonus: shut leaf1 → h2 still reaches the gateway via leaf2's anycast presence (h1 would lose connectivity since its leaf is gone, but anycast on the remaining leaves continues serving everyone else).

## Hints

```
ip virtual-router mac-address aa:bb:cc:00:00:01

interface Vlan<n>
   vrf <name>
   ip address virtual <ip>/<mask>
```

Verification:

```
show ip virtual-router
show ip route vrf TENANT-A
show vxlan address-table
show bgp evpn route-type mac-ip
```

On hosts:

```
ip neigh show 10.10.10.254     ! check the MAC the host learned for the gateway
```

## Deploy

```bash
cd ~/containerlab/labs/32-evpn-anycast-gateway
sudo containerlab deploy
```

## Verification

### 1. Both leaves identical for the anycast gateway

```bash
docker exec -it clab-evpn-anycast-gw-leaf1 Cli
show ip virtual-router
```

```bash
docker exec -it clab-evpn-anycast-gw-leaf2 Cli
show ip virtual-router
```

Same `10.10.10.254` + same MAC `aa:bb:cc:00:00:01` on both.

### 2. Hosts learn the gateway

```bash
docker exec clab-evpn-anycast-gw-h1 sh -c "ping -c 1 10.10.10.254 && ip neigh show 10.10.10.254"
```

```bash
docker exec clab-evpn-anycast-gw-h2 sh -c "ping -c 1 10.10.10.254 && ip neigh show 10.10.10.254"
```

Both should see MAC `aa:bb:cc:00:00:01`.

### 3. Intra-subnet via EVPN-stretched VLAN

```bash
docker exec clab-evpn-anycast-gw-h1 ping -c 3 10.10.10.20
```

✅. Same as lab 30 — VXLAN-encapsulated intra-VNI.

### 4. Inspect EVPN Type 2 routes with IP

```bash
docker exec -it clab-evpn-anycast-gw-leaf1 Cli
show bgp evpn route-type mac-ip
```

Should show h1's MAC+IP on leaf1's VTEP, h2's MAC+IP on leaf2's VTEP. Each leaf knows where every host lives.

### 5. Failover demo — leaf1 disappears

Sustained ping from a third entity (we don't have one; conceptually):

Kill leaf1:

```bash
sudo docker stop clab-evpn-anycast-gw-leaf1
```

In a production fabric with more leaves, hosts on the remaining leaves would still use them as anycast gateways for `10.10.10.254` — no failover required (every leaf already was the gateway). h1 itself becomes unreachable because its leaf disappeared — but that's a separate failure mode.

Restart:

```bash
sudo docker start clab-evpn-anycast-gw-leaf1
```

Wait ~60s for EVPN to reconverge.

## Peek at solution

- [`solutions/leaf1.cfg`](solutions/leaf1.cfg), [`solutions/leaf2.cfg`](solutions/leaf2.cfg), [`solutions/spine1.cfg`](solutions/spine1.cfg)

## Concepts cheat-sheet

- **EVPN anycast gateway** — every leaf in the fabric is the L3 gateway for hosted subnets.
- **`ip address virtual`** — anycast gateway IP; same on every leaf.
- **Shared virtual MAC** — identical across leaves; hosts learn one MAC for the gateway.
- **No hairpin** — host's L3 traffic is routed by its local leaf, then crosses fabric via L3 VNI.
- **Seamless mobility** — VM moves between leaves; gateway stays the same.

## Production deployment notes

- **Pick the MAC carefully** — locally-administered range (`02:..` etc.). Document fabric-wide convention.
- **Consistency is critical** — every leaf hosting the subnet must have IDENTICAL virtual IP + MAC. Automation/config templates are essential.
- **First-hop ACLs** must be consistent across leaves — otherwise traffic landing on different leaves gets treated differently.
- **MTU consistency** — every leaf's SVI for the same VLAN should have the same MTU.
- **Pair with EVPN MH (multi-homing)** for server-side redundancy (replaces MLAG in EVPN designs).
- **Anycast IP can be inside the subnet** (`.1`, `.254`, etc.) or even a separate IP outside the host range (depends on platform & convention).

## What's missing (deliberately)

- **EVPN MH** (multi-homing) — replaces MLAG; servers dual-home to two leaves at L2 via EVPN.
- **Multi-site DCI** — lab 33.
- **Per-VRF policy at scale** — multi-tenant scenarios with shared services VRF, leaking, etc.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
