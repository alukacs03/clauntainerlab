# Lab 48 — Storage QoS & Tenant Isolation

> **Format:** Hands-on. Per-tenant rate-limit (policer) on ingress, DSCP marking by tenant, queue bandwidth allocation on the shared egress. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 8 · Senior+ · Year 5. Multi-tenant storage. Tenant B's backup job at 02:00 is starving Tenant A's database I/O — same SAN, same network. Tenant A pays for "premium IOPS." Tenant B doesn't. The network has to enforce the difference. See [`STORY.md`](../../STORY.md).

## Real-world scenario

The "noisy neighbor" problem in storage:

Two tenants share a SAN backend. Tenant A pays for guaranteed IOPS; Tenant B is on standard pricing. Without QoS, Tenant B's nightly backup hits 8 Gbps and saturates the link to the SAN. Tenant A's database queries slow to a crawl. Tenant A escalates.

The fix has three layers:
1. **Mark per-tenant**: at the ingress port, tag every packet with a DSCP value that identifies the tenant's tier.
2. **Rate-limit (policer) the lower tier**: cap Tenant B's bandwidth so they can't even produce a full saturation. Hard ceiling.
3. **Queue scheduling on the contested egress**: on the link to the SAN, give the premium class 80% of bandwidth when there's contention.

Combined effect: Tenant B can use up to 100 Mbit. Beyond that, dropped at ingress. The link to the SAN reserves 80% for premium even if standard tries to use it all.

## Goal

- Per-tenant DSCP marking
- Ingress policer for the lower tier
- Per-class bandwidth allocation on the contested egress

## Theory primer

### Policer vs shaper

- **Policer**: drop (or remark) packets exceeding rate. Cheap. Adds no latency. Bursty: TCP flows back off, then ramp up again repeatedly.
- **Shaper**: buffer packets to meet rate. Smooths. Adds latency (proportional to buffer depth). Uses memory.

For tenant isolation: policer is usually right — you want a hard ceiling without consuming switch memory. For a customer-facing access link: shaper is sometimes better — smoother user experience.

This lab uses a policer.

### Token bucket

A policer is conceptually a token bucket:
- Tokens generated at `rate` (e.g., 100 Mbit/s = 12.5 MB/s)
- Bucket capacity = `burst-size` (e.g., 64 KB)
- Each packet consumes tokens equal to its size; if not enough tokens, drop
- Bucket can absorb short bursts up to its size, then enforces the rate

Why burst matters: a burst-size of 0 means a single 1500-byte packet exceeds the bucket and gets dropped. Typical bursts: 32 KB - 256 KB for normal traffic.

### Class-based bandwidth allocation on egress

When the egress link is congested (i.e., total demand > link capacity), the scheduler picks. With class-based allocation:
- Class A (AF31): 80% guaranteed minimum
- Class B (CS1): 20% guaranteed minimum

"Guaranteed minimum" — if A doesn't use its 80%, B can borrow it. When A wants its 80%, B is pushed back to 20%. No bandwidth wasted; tenants protected.

This is what implements the "premium gets bandwidth guarantee" promise.

### The trust boundary

Tenants can mark their own packets. You can't trust that — they'll mark everything as the premium tier. Therefore:
- On the tenant-facing port: **re-mark** ingress traffic (don't trust whatever DSCP they sent)
- On internal links: **trust** DSCP (it's already been set by your edge)

This is the same principle as voice marking (lab 43): mark at the edge, trust internally.

### What about IOPS, not just bandwidth?

Network QoS controls bandwidth and latency, not IOPS directly. For per-tenant IOPS limits, that's done at the **storage controller** (LVM, ZFS, vSphere SIOC, Ceph QoS, etc.) — outside the network.

The network's role: don't let one tenant's storage traffic starve another's at the *transport* layer. The storage system handles per-LUN/per-volume IOPS caps.

## Your task

1. Build the marking policy: Tenant A → AF31, Tenant B → CS1.
2. Build the policer: 100 Mbit/s, 64 KB burst, drop on exceed.
3. Apply marking and policer at each tenant's ingress port.
4. On the shared egress (to target): trust DSCP, allocate 80%/20% to AF31/CS1 traffic classes.

## Verification

### Check policies are applied
```bash
docker exec -it clab-storage-qos-isolation-sw1 Cli
show policy-map interface ethernet 2 input
show qos interface ethernet 3
```

### Test policing
On target, listen:
```bash
docker exec -d clab-storage-qos-isolation-target iperf3 -s
```

From tenant-b, attempt 1 Gbps:
```bash
docker exec clab-storage-qos-isolation-tenant-b iperf3 -c 10.50.99.10 -b 1G -t 10
```

Expected: throughput caps at ~100 Mbit/s, "lost" packet count is high (the policer is dropping).

From tenant-a, attempt same:
```bash
docker exec clab-storage-qos-isolation-tenant-a iperf3 -c 10.50.99.10 -b 1G -t 10
```

Expected: throughput is near link rate (no policer on tenant-a).

### Test bandwidth allocation under contention
Run both tenants simultaneously. Tenant A should retain near-full link share even when Tenant B is hammering — because Tenant B is policed first, and the egress bandwidth allocation backs it up if needed.

## What's missing (deliberately)

- **DSCP-aware Linux host marking** — tenants' marking from inside their VM
- **Burst-aware policing** (two-rate three-color marker / 2R3C) — color-aware traffic conditioning
- **Storage-controller IOPS limits** — non-network
- **Per-flow fairness** (DRR / FQ-CoDel) — modern Linux qdisc features
- **Telemetry exporting drops/throttles** to billing/alerting

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
