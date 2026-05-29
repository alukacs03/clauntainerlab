# Lab 59 — Worked answers

These are the worked numeric answers for the computational task. Try the math
yourself first; check here second. The lab fabric is deliberately tiny (2 spines,
2 leaves, one server port per leaf) so the arithmetic is easy to do by hand — the
*method* is what transfers to a real 48-port leaf.

> Reminder: "1G links throughout" is a **paper assumption** for these calculations.
> containerlab veth links are not rate-limited (see the note in the README), so
> none of these capacity numbers can be observed as congestion on the lab — only
> the MTU behaviour is directly observable.

## 1. Oversubscription, bisection, one-spine-failed

**Topology that ships:** 2 spines, 2 leaves, 1G everywhere. Each leaf has:

- **South (server-facing):** 1× server port — `eth3` @ 1 Gbps
- **North (spine-facing):** 2× uplinks — `eth1`→spine1, `eth2`→spine2 = 2 Gbps

**Per-leaf oversubscription ratio** = south ÷ north:

```
south = 1 × 1 Gbps = 1 Gbps
north = 2 × 1 Gbps = 2 Gbps
ratio = 1 / 2 = 0.5 : 1   (i.e. NORTH-heavy — the lab leaf is under-subscribed)
```

A real leaf is the other way round, which is why oversubscription is a concern in
production. Worked production example from the primer (48× 10G south, 4× 100G
north): `480 / 400 = 1.2:1`.

**Maximum tenant-to-tenant bisection bandwidth (single direction).** Traffic from
host1 (leaf1) to host2 (leaf2) is ECMP-hashed across both spines. Each leaf↔spine
link is 1 Gbps, and there are two parallel spine paths:

```
bisection = 2 spines × 1 Gbps = 2 Gbps (single direction)
```

> Caveat that bites in practice: a *single* TCP/UDP flow is pinned to **one**
> ECMP path by the hash, so one flow tops out at **1 Gbps**, not 2. The 2 Gbps is
> the aggregate across many flows. This is exactly the ECMP-imbalance effect that
> motivates the 70% planning threshold.

**With one spine failed:**

```
bisection = 1 spine × 1 Gbps = 1 Gbps (single direction)
```

Losing one of two spines halves east-west capacity. With 4 spines you'd lose only
25%, which is why production fabrics run more, thinner spines.

## 2. Planning an 800 Mbps customer

Planned bandwidth = sustained × peak factor:

```
800 Mbps × 1.5 = 1.2 Gbps planned (per customer)
```

Walk it through the bottleneck chain (smallest pipe wins):

| Pipe                              | Capacity | One customer (1.2 G) | Notes |
|-----------------------------------|----------|----------------------|-------|
| Server/access port (`eth3`)       | 1 Gbps   | **does NOT fit**     | first bottleneck |
| Leaf north (2 uplinks)            | 2 Gbps   | fits                 | |
| Leaf↔leaf bisection (2 spines)    | 2 Gbps   | fits                 | 1 Gbps if a spine is down |

- **One customer?** The 1.2 Gbps *planned peak* already exceeds the **1 Gbps
  server/access port** — that single 1G port is the **first bottleneck**. On a real
  leaf with a 10G/25G server NIC the access port is no longer the limit and the
  question moves north.
- **Two customers?** 2 × 1.2 = 2.4 Gbps. Exceeds the 2 Gbps leaf-north bandwidth
  (and the 2 Gbps bisection) — over 100%, far past the 70% planning threshold.
- **Five customers?** 5 × 1.2 = 6 Gbps. Far beyond every pipe in this fabric.

**Where's the first bottleneck?** In *this* tiny lab it is the 1 Gbps server/access
port. In a realistic fabric (big server NICs) the first bottleneck is the
**leaf-to-spine north bandwidth** once aggregate tenant peak crosses 70% of it —
that is the number you actually watch in capacity planning.

## 3. MTU for a VXLAN-stretched VLAN across DCs

Customer VMs use **MTU 1500** (standard) on the stretched VLAN. The VLAN is
extended between DCs over VXLAN, which adds 50 bytes of encapsulation on top of the
inner Ethernet frame (8 VXLAN + 8 UDP + 20 outer IPv4 + 14 outer Ethernet):

```
inner frame  = 1500 bytes
+ VXLAN encap = +50 bytes
underlay min  = 1550 bytes  ← absolute minimum the underlay MUST carry
```

So the **underlay minimum MTU is 1550**. In practice you do **not** set exactly
1550 — you set a jumbo value to leave headroom for additional tags/labels and to
match fabric convention:

- **Underlay / fabric links:** set **9214** (Arista convention) on every
  device-to-device link.
- **Inter-DC link:** also set **9214** (or the highest the provider/transport will
  carry end-to-end). The inter-DC link is the one people forget — if it silently
  caps at 1500, VXLAN traffic of full-MTU inner frames gets dropped, and because
  PMTUD doesn't see inside the tunnel the failure looks like the "small pings work,
  big transfers hang" symptom from the primer.

**Answer:** underlay MTU minimum = **1550**; deploy **9214** on the fabric *and* on
the inter-DC link. Leave the customer VMs at 1500 — they never need to know the
underlay carries jumbo.
