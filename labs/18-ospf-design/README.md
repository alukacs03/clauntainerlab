# Lab 18 — OSPF Design (Multi-Area + LSA Types)

> **Format:** Hands-on. Three switches across two OSPF areas, with an ABR in the middle and an external prefix injected as Type 5. Reference answer in [`solutions/`](solutions/).

## Real-world scenario

Lab 17 had a single OSPF area. That works for ~10–50 devices. Beyond that, the LSDB grows, SPF recalculations cost more, and a single misbehaving router floods the whole network with churn.

**Multi-area OSPF** solves this. Split the topology into the **backbone (area 0)** plus one or more leaf areas. Border routers (ABRs) only let *summarized* routes leak across the area boundary, not full LSDBs. Convergence stays local: a flap in area 1 doesn't make area 0 routers re-SPF.

This lab does the smallest possible multi-area design (3 switches, 2 areas) so you can see:
- Area boundary mechanics
- Different LSA types in action
- How a **stub area** filters external routes
- What an ABR vs ASBR actually does

## Goal

By the end you should be able to answer:

- What's an **ABR**, what's an **ASBR**?
- What are LSA **Type 1, 2, 3, 4, 5, 7**?
- How does an **`O IA`** route differ from an **`O`** route or an **`O E2`** route?
- What does making an area **stub** do, and when do you choose **stub vs totally stubby vs NSSA**?
- Why must every non-zero area connect to area 0?

## Topology

```mermaid
graph LR
    h1[h1<br/>10.10.10.10] --> sw1
    sw1[sw1<br/>1.1.1.1<br/>ASBR<br/>redistributes static] ==area 0== sw2[sw2<br/>2.2.2.2<br/>ABR]
    sw2 ==area 1== sw3[sw3<br/>3.3.3.3]
    sw3 --> h3[h3<br/>10.30.30.10]
    ext[external<br/>198.51.100.0/24] -.injected by sw1.- sw1
```

| Switch | Role | Area(s) |
|---|---|---|
| sw1 | Backbone + ASBR (redistributes a static into OSPF) | Area 0 only |
| sw2 | ABR | Area 0 on Et2, Area 1 on Et3 |
| sw3 | Branch | Area 1 only |

## Theory primer

### ABR vs ASBR

- **ABR (Area Border Router)** — a router with interfaces in **two or more areas**. Translates LSAs across the area boundary: takes intra-area routes from area X and re-floods them as Type 3 (summary) into area Y. Doesn't know about external routes specifically; only redistributes between OSPF areas.
- **ASBR (AS Boundary Router)** — a router that **redistributes routes from outside OSPF** (static routes, BGP, another OSPF process, etc.) into OSPF. These show up as Type 5 (or Type 7 in NSSA) external LSAs.

A router can be both ABR and ASBR. In this lab:
- sw2 is ABR (areas 0 and 1).
- sw1 is ASBR (redistributes `198.51.100.0/24` static into OSPF).

### LSA Types — what you'll see in `show ip ospf database`

| Type | Name | What it carries | Scope |
|---|---|---|---|
| 1 | Router LSA | "I am router X, here are my links and costs" | Within the originating area |
| 2 | Network LSA | DR-elected summaries for broadcast/multi-access segments | Within the originating area |
| 3 | Summary LSA | "From area X (via me, the ABR), these prefixes are reachable" | Flooded into other areas |
| 4 | ASBR Summary | "This ABR knows the way to ASBR router Y" | Flooded across areas so other routers can reach the ASBR |
| 5 | AS External | "Here's a prefix from outside OSPF (redistributed)" | Flooded everywhere EXCEPT into stub-type areas |
| 7 | NSSA External | Like Type 5 but lives inside NSSA areas; converted to Type 5 at the ABR | NSSA area only, then translated |

In modern point-to-point designs you mostly see Types 1, 3, and 5. Types 2/4 are corner cases. Type 7 is for NSSA only.

### Intra-area, inter-area, external — `show ip route` codes

When you look at `show ip route`:

| Code | Meaning |
|---|---|
| `O` | Intra-area OSPF — learned via Type 1/2 from within your own area |
| `O IA` | Inter-area — learned via Type 3 LSA from an ABR |
| `O E1` / `O E2` | External — learned via Type 5 (or Type 7) LSA from an ASBR; E1 includes the path cost to the ASBR, E2 doesn't (default) |
| `O N1` / `O N2` | NSSA externals (same as E1/E2 but in NSSA) |

E1 vs E2: E2 uses only the metric advertised by the ASBR, ignoring the internal cost to reach the ASBR. E1 sums both. Default is E2. For most networks E2 is fine; use E1 when the "cost to reach the ASBR" matters for path selection (rare).

### Area 0 (backbone) rules

- **Area 0 must always exist** and must be **contiguous**.
- **Every non-zero area must connect to area 0** (directly or via a virtual link, which is a hack — avoid).
- Inter-area traffic always traverses area 0 (no "shortcuts" between non-zero areas).

If you ever find yourself drawing area 1 → area 2 directly without area 0 in between, your design is wrong. Refactor.

### Stub area variants

To reduce LSDB size in branches, an area can be configured to filter certain LSA types at the ABR:

| Variant | Filters Type 4/5 (externals)? | Filters Type 3 (inter-area summaries)? | Default route injected? |
|---|---|---|---|
| **Stub area** | Yes | No | Yes (via ABR) |
| **Totally stubby area** (`stub no-summary`) | Yes | Yes | Yes (via ABR) |
| **NSSA** (Not-So-Stubby Area) | Replaces Type 5 with Type 7 (so the area can have its own ASBR) | No | Optional |
| **Totally NSSA** | Same as NSSA + filters Type 3 | Configurable | Optional |

Use stub for branches that don't need to know specific external prefixes — they get a default route to the ABR instead. Smaller LSDB, less work.

This lab demonstrates the basic stub.

## Your task

1. On all three switches: enable OSPF process 1, router-id from Loopback0, passive-by-default with selective `no passive-interface` for transit ports, point-to-point network on transit, area assignments per the topology.
2. On sw1: redistribute the existing static (`198.51.100.0/24`) into OSPF — this makes sw1 the ASBR.
3. Verify: sw3 sees the external `198.51.100.0/24` as `O E2`.
4. Convert area 1 to a **stub area**. Verify the Type 5 LSA disappears from sw3's LSDB and is replaced by a default route from the ABR (sw2).
5. Bonus: convert to **totally stubby** (`stub no-summary`). Observe Type 3 LSAs also vanish.

## Hints

Per-interface OSPF area:

```
interface <name>
  ip ospf area 0.0.0.<n>
```

Redistribute static (sw1 only):

```
router ospf 1
   redistribute static
```

Stub area (apply on **both** routers in the area — sw2 ABR side and sw3):

```
router ospf 1
   area 1 stub
```

Totally stubby (only on the ABR — sw2):

```
router ospf 1
   area 1 stub no-summary
```

Verification:

```
show ip ospf neighbor
show ip ospf database
show ip route
show ip route ospf
show ip ospf border-routers
```

## Deploy

```bash
cd ~/containerlab/labs/18-ospf-design
sudo containerlab deploy
```

## Verification

### 1. Adjacency formation

After configuring OSPF on all three:

```bash
docker exec -it clab-ospf-design-sw2 Cli
show ip ospf neighbor
```

sw2 has TWO neighbors: sw1 (in area 0) and sw3 (in area 1). Both Full.

```bash
docker exec -it clab-ospf-design-sw1 Cli
show ip ospf neighbor
```

sw1 has ONE neighbor: sw2 (in area 0).

```bash
docker exec -it clab-ospf-design-sw3 Cli
show ip ospf neighbor
```

sw3 has ONE neighbor: sw2 (in area 1).

### 2. Routes — intra vs inter-area vs external

On sw3:

```
show ip route
```

Expected codes:
- `O IA` for routes from area 0 (sw1's loopback, h1 LAN, sw2-sw1 transit) — inter-area, learned via Type 3 from sw2.
- `O E2` for `198.51.100.0/24` — Type 5 external from sw1 (ASBR).
- `O IA` for sw2's loopback (it's in area 0 — sw2 puts its loopback in area 0 by convention).

### 3. Look at the LSDB

```
show ip ospf database
```

You'll see sections for:
- **Router LSAs (Type 1)** — your own area only (area 1 for sw3).
- **Summary LSAs (Type 3)** — multiple entries from sw2 (ABR), one per area-0 prefix.
- **ASBR Summary LSAs (Type 4)** — sw2 advertising sw1's ASBR reachability into area 1.
- **AS External LSAs (Type 5)** — `198.51.100.0/24` originated by sw1.

```
show ip ospf database router
show ip ospf database summary
show ip ospf database external
```

Each command shows a specific type.

### 4. Connectivity

```bash
docker exec clab-ospf-design-h1 ping -c 3 10.30.30.10
docker exec clab-ospf-design-h3 ping -c 3 10.10.10.10
```

Both ✅.

### 5. Make area 1 a stub

On sw2 (ABR):

```
configure terminal
  router ospf 1
    area 1 stub
```

On sw3:

```
configure terminal
  router ospf 1
    area 1 stub
```

**Both routers in the area must agree it's stub**, otherwise the adjacency drops. Now:

```bash
docker exec -it clab-ospf-design-sw3 Cli
show ip ospf database
show ip route
```

Changes you'll see:
- Type 5 LSAs are **gone** from sw3's LSDB.
- `198.51.100.0/24` no longer in sw3's route table as `O E2`.
- A **default route** (`0.0.0.0/0 via 192.168.23.2`) appears, learned via OSPF from the ABR.

sw3 lost specific knowledge of externals but still reaches them via the default route through sw2. Smaller LSDB, simpler local view.

```bash
docker exec clab-ospf-design-h3 ping -c 2 198.51.100.1
```

Still works — sw3 follows the default to sw2, sw2 knows the specific route.

### 6. Totally stubby (bonus)

On sw2 only:

```
router ospf 1
   area 1 stub no-summary
```

(sw3 still has plain `area 1 stub` — sw3 doesn't need to know it's "totally" stubby; only the ABR enforces the filtering.)

Now on sw3:

```
show ip ospf database
show ip route
```

Type 3 LSAs are **also** gone. Only the default route exists for everything outside area 1.

Revert: `no area 1 stub no-summary` on sw2.

## Peek at solution

- [`solutions/sw1.cfg`](solutions/sw1.cfg), [`solutions/sw2.cfg`](solutions/sw2.cfg), [`solutions/sw3.cfg`](solutions/sw3.cfg)

## Concepts cheat-sheet

- **ABR** — router with interfaces in 2+ areas; floods Type 3 between them.
- **ASBR** — router redistributing from outside OSPF; originates Type 5 (or Type 7 in NSSA).
- **LSA types** — 1 (router), 2 (network), 3 (summary/inter-area), 4 (ASBR summary), 5 (external), 7 (NSSA external).
- **Route codes** — `O` intra, `O IA` inter-area, `O E1/E2` external.
- **Area 0** — backbone; must exist, must be contiguous, every other area must touch it.
- **Stub area** — filters Type 4/5 (externals); default route comes from ABR.
- **Totally stubby** — also filters Type 3 (inter-area summaries); only default route.
- **NSSA** — like stub but the area is allowed to have its own ASBR; uses Type 7 inside, translated to Type 5 at ABR.

## Design notes

- **Keep areas under ~50 routers** as a rough rule. Bigger areas → bigger LSDB → slower SPF.
- **Use stub/totally-stubby for branches and access closets.** They don't need to know specific external routes; defaults are fine.
- **NSSA is for "branch with its own internet exit"** — needs to redistribute its own externals locally but still wants the LSDB benefits of stub.
- **Don't use virtual links** unless you absolutely have to (e.g., a non-zero area that can't directly touch area 0 due to physical constraints). Virtual links are a band-aid; redesign instead.
- **Avoid `redistribute connected` carelessly** — leaks every connected subnet of the ASBR into OSPF as Type 5, including transit subnets that shouldn't be in OSPF as externals. Use route-maps to filter.
- **External route metric type** — choose E1 vs E2 deliberately. E2 (default) is fine for most.

## What's missing (deliberately)

- **IS-IS** — link-state alternative, common at large SP scale; conceptually similar.
- **OSPFv3** — for IPv6. Same concepts, slightly different LSA mechanics.
- **OSPF authentication** — production must-do, configured in ops lab.
- **Virtual links** — last-resort design tool; avoid if possible.
- **OSPF + BGP redistribution** — when running both, careful policy is needed; covered in BGP labs.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
