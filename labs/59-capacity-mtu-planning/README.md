# Lab 59 — Capacity & MTU Planning

> **Format:** Reference + calculation exercises. Quantitative planning is the actual focus; the lab provides a fabric for verifying assumptions.
>
> **Story chapter:** Phase 9 · Tech lead · Year 5+. After two near-miss saturation incidents and one painful "why are jumbo pings failing on the new fabric" investigation, you write the planning guide. Bandwidth math, MTU end-to-end, oversubscription ratios — the unglamorous numbers that decide whether the fabric works at scale. See [`STORY.md`](../../STORY.md).

## Real-world scenario

Two situations the playbook addresses:

**Situation A — Capacity:** Marketing wants to add a new customer running 5 Gbps of inbound traffic. Your fabric "should" handle it; you "think" your spines have capacity. But you've never actually counted. Senior leadership asks: "if we onboard this customer, what's our risk?"

**Situation B — MTU:** A new customer reports their large-file transfers fail. Small pings work. You investigate. Somewhere on the path, MTU is wrong. Whose responsibility is it to know?

Both situations are solved by *doing the math first*.

## Goal

- Compute oversubscription ratio for a Clos fabric
- Compute end-to-end MTU budget including overheads (VXLAN, IPsec, etc.)
- Apply the planning workflow to extension decisions

## Theory primer

### Oversubscription

```
N_leaf_ports_to_servers × server_link_speed       (south)
─────────────────────────────────────────────  =  oversubscription ratio
N_leaf_ports_to_spines × spine_link_speed         (north)
```

Example: 48× 10G server ports + 4× 100G uplinks per leaf.

```
48 × 10 Gbps = 480 Gbps  south
 4 × 100 Gbps = 400 Gbps  north

ratio = 480/400 = 1.2:1
```

Industry rules of thumb:
- **1:1** (non-blocking) — required for HPC, AI training, storage backbone
- **2:1 - 3:1** — typical for general cloud workloads
- **5:1+** — only OK if you know workload averages
- **10:1+** — campus/office; assumes most servers idle

Add up the *actual* worst-case demand across your customers. If it exceeds the north bandwidth, you have a capacity problem before the link counter shows it.

### Capacity planning workflow

1. **Inventory all customer/tenant peaks** (NetBox-tagged, or from Prom metrics)
2. **Compute simultaneous-worst-case demand** (not always sum-of-peaks; correlate)
3. **Compare to fabric north bandwidth per leaf**
4. **Compare to inter-pod bandwidth**
5. **Compare to external/transit bandwidth**
6. **Identify the bottleneck** (the smallest of the above)
7. **Plan expansion before utilization hits 70%** (rule of thumb)

70% is the planning threshold because:
- ECMP hash imbalance can push the busiest link 30% above average
- A single device failure means remaining devices absorb its share
- Lead time to add capacity is weeks to months

### MTU math

For a payload to travel end-to-end without fragmentation, every link in the path must support the largest frame size used.

Stack overheads (add to your payload):

| Layer | Overhead bytes |
|---|---|
| Ethernet header + FCS | 18 (14 + 4) |
| 802.1Q VLAN tag | +4 |
| QinQ (S-tag + C-tag) | +8 |
| IP header (v4) | 20 |
| TCP header | 20 |
| UDP header | 8 |
| VXLAN | 50 (8 VXLAN + 14 outer eth + 20 outer IP + 8 UDP — minus inner) |
| GRE | 24 (4 GRE + 20 outer IP) |
| IPsec ESP tunnel mode | ~50-90 (varies with crypto) |
| WireGuard | 60 |
| MPLS label | +4 per label |

Example: ethernet payload over VXLAN over a normal IP fabric:
- Tenant frame: 1500 bytes (standard MTU)
- After VXLAN encap: 1500 + 50 = **1550 bytes** on the underlay
- → Underlay MUST support MTU 1550 (typically you set 9000 to leave headroom)

### Path MTU Discovery and where it breaks

ICMP "Frag Needed" (type 3 code 4) is the message that tells a sender to back off. If any device on the path blocks ICMP (firewall), PMTUD silently breaks — connections to that destination hang on large transfers but work on small ones.

Fixing this requires identifying the blocker and reopening ICMP. Don't blanket-block ICMP at firewalls; allow at least type 3.

### Jumbo frame deployment checklist

To roll out MTU 9000 in a fabric:
1. Confirm all *physical* links support it (some old switches cap at 9216)
2. Set MTU 9214 on every device-to-device link (Arista convention)
3. Set MTU 9000 on host-facing access ports (or 9214 if hosts also use jumbo)
4. **Test end-to-end**: `ping -M do -s 8972 dest` from every endpoint
5. Roll out per-fabric, not all at once
6. Monitor: any drops with "MTU mismatch" log lines

A common partial deployment: jumbo set on switches but not on one customer's NIC. That customer's TCP traffic works (PMTUD), UDP-heavy traffic gets dropped. Hard to spot; verify endpoint MTU separately.

### Bandwidth modeling for a planned change

When adding a new service:

```
expected_throughput   = (target QPS) × (bytes per request)
+ overhead for retries, headers, etc.   ~20%
+ peak factor (peak/average)            ~3× for typical web,
                                          ~1.5× for storage
= planned bandwidth

Compare to:
- per-server NIC capacity (>2× planned)
- per-leaf north capacity (planned + existing < 70% of leaf's spine bandwidth)
- per-spine capacity (sum across leaves < 70% of spine total)
- transit capacity (if egress-heavy)
```

If any of those fail, plan expansion first.

## Your task

The "task" here is computational, not configurational:

1. Given the lab topology (2 spines, 4 leaves, 1G links throughout), compute:
   - Oversubscription ratio per leaf
   - Maximum tenant-to-tenant bisection bandwidth (single direction)
   - Same with one spine failed
2. Plan a hypothetical customer: 800 Mbps sustained + 1.5× peak factor. Will the fabric handle:
   - One such customer? Two? Five?
   - Where's the first bottleneck?
3. MTU exercise: a customer wants jumbo on their stretched VLAN (VXLAN-extended across DCs). Their VMs use MTU 1500. What's the *underlay* MTU you need (and on the inter-DC link too)?

## Verification

Verify MTU on the lab:
```bash
docker exec clab-capacity-mtu-planning-host1 ping -M do -s 1472 10.10.20.10  # 1500-28 → should work
docker exec clab-capacity-mtu-planning-host1 ping -M do -s 8972 10.10.20.10  # 9000-28 → fails (default MTU is 1500)
```

## What's missing (deliberately)

- **TCAM utilization planning** — distinct discipline; hardware-specific
- **Forwarding plane microburst analysis** — needs production telemetry
- **AI/ML workload modeling** — distinct patterns; needs domain knowledge
- **Cost/$$ modeling** — out of scope for technical curriculum
- **CDN / edge capacity** — covered conceptually in lab 39

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
