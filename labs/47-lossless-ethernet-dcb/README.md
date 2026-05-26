# Lab 47 — Lossless Ethernet (DCB / PFC / ETS)

> **Format:** Hands-on configuration pattern + concept-heavy. cEOS limitation: PFC/ETS are implemented in ASIC on production hardware (DCS-7060X / 7280R / 7500R / 7800R); on cEOS the syntax is accepted but enforcement is partial. The point of this lab is the *pattern* — production hardware enforces, but you learn the config and the model. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 8 · Senior+ · Year 5. After lab 46, storage works — but at 60% of expected throughput, and one customer keeps complaining about "weird IOPS spikes." You learn the unfortunate truth: classical ethernet drops packets when congested, and TCP retransmits — but for storage, retransmits look like latency, and latency looks like a broken disk. You need *lossless* ethernet. See [`STORY.md`](../../STORY.md).

## Real-world scenario

iSCSI (and especially NVMe-oF / RoCE) was designed assuming a *lossless* transport — like Fibre Channel. Plain ethernet drops packets when buffers overflow; TCP recovers but only after retransmit timeouts (typically tens to hundreds of milliseconds). For a storage workload, that's a disaster: each "lost" packet looks like a 200ms disk seek, application I/O queues stall, customers see stuttering.

DCB (Data Center Bridging) is the IEEE protocol family that turns standard ethernet into a lossless transport for specific traffic classes. Three pieces:

1. **PFC (802.1Qbb)** — Priority-based Flow Control. Per-class PAUSE frames. When a buffer fills for class X, send a PAUSE for class X to the upstream device; other classes keep flowing.
2. **ETS (802.1Qaz)** — Enhanced Transmission Selection. Bandwidth guarantees per traffic class. Storage gets 50% guaranteed.
3. **DCBX (802.1Qaz)** — Discovery and Capability Exchange. Switch and host negotiate which classes are lossless, which DSCP values map to which class.

The combination: storage class is guaranteed 50% bandwidth, is lossless via PFC, and the host's NIC firmware knows to mark iSCSI traffic as that class via DCBX.

## Goal

- Build the standard "lossless storage class" config pattern
- Understand the role of each piece (PFC, ETS, DCBX) and how they combine
- Recognize the configuration on production gear when you encounter it

## Theory primer

### Why classical ethernet drops packets

When two ports send to one output (incast pattern — common in storage where one initiator pulls from many targets), the output port's queue fills up. When the queue is full and another packet arrives → drop. TCP retransmits, but the retransmit + recovery costs 50–500 ms.

For storage:
- 50 ms latency vs 0.5 ms typical = **100x slower I/O**
- Application timeout watchdogs trigger
- For RoCE (RDMA over Converged Ethernet), the application *cannot* recover — RoCE has no software retransmit; lost packet = lost write

### PFC: per-class PAUSE frames

Pre-PFC ethernet had "global" PAUSE (802.3x) — send a PAUSE frame and ALL traffic on that link stops. Useless for storage because you'd stop voice + control traffic too.

PFC (802.1Qbb) is **per-priority**: 8 priority classes (mapped from 802.1p PCP or DSCP), each with independent PAUSE. When buffer for class 3 fills → send PAUSE for class 3 only → upstream holds back class 3 → other classes keep flowing.

Mechanics:
- The downstream sets a "no-drop" mark on traffic class X
- When TX buffer for X fills, it sends a MAC Control PAUSE frame (PCP=X, pause-time in quanta)
- Upstream device honors it for that class

For PFC to work end-to-end, **every device on the path must support it and have it configured consistently for the same class.** One misconfigured device = drops happen there = lossless broken.

### ETS: bandwidth guarantees

Without ETS, queueing is strict-priority or WRR by default. ETS adds: "TC3 gets at least 50% of the link, the rest is shared by everyone else." Guarantees minimums, doesn't hard-cap (other classes can use unused storage bandwidth).

Use case: voice in TC5 (strict priority), storage in TC3 (50% min, lossless via PFC), default in TC0 (rest).

### DCBX: auto-negotiation

DCBX runs over LLDP. Switch advertises: "I support PFC on TC3, ETS reserves 50% for TC3, DSCP 26 maps to TC3." The host's NIC (Mellanox, Intel X550, Broadcom NetXtreme) accepts those settings and configures its own QoS to match.

Two flavors: IEEE (preferred) and CEE (older, from pre-standardization). Use IEEE on new gear.

### How this interacts with TCP

PFC slows down the sender at the link layer rather than letting packets drop. TCP never sees congestion → never reduces window → throughput stays high.

Risk: **PFC deadlocks**. If A pauses B, B pauses C, C pauses A, you have a cycle → traffic stops permanently. Real risk on misdesigned topologies; spine-leaf with PFC is usually OK because the topology is acyclic.

### When *not* to use lossless ethernet

- **General-purpose data networks**: TCP recovers fine from drops at <0.01% loss; PFC adds complexity without benefit.
- **Mixed traffic with bursts**: PFC can cause **head-of-line blocking** — one slow consumer pauses everyone sharing that class.
- **Path includes non-DCB-capable devices**: lossless requires end-to-end. One non-PFC switch = no lossless.

Rule of thumb: enable PFC/ETS only on the storage VLAN, only between hosts and switches that you control end-to-end.

## Your task

The lab's config is mostly demonstrative because cEOS doesn't enforce PFC. The goal is:

1. Read the solution carefully.
2. Apply it.
3. Verify the configuration is accepted (`show qos interface ethernet 1`, `show dcbx`).
4. Understand what each piece does.

On production hardware, you'd also:
- Run incast traffic (many → 1)
- Observe TX queue depth on the receiver
- Observe PAUSE frame counters (`show interfaces ethernet 1 priority-flow-control counters`)
- Compare with/without PFC: drops vs PAUSE counts

## Verification

```bash
docker exec -it clab-lossless-ethernet-dcb-sw1 Cli
show qos maps
show qos interface ethernet 1
show dcbx
show interfaces ethernet 1 priority-flow-control
```

The exact output varies by EOS version; the key fields:
- Trust mode = DSCP
- PFC enabled on priority 3
- No-drop on TC 3
- ETS bandwidth allocation

## Common gotchas (production hardware)

- **MTU mismatch on PFC-enabled link** → PAUSE frames don't arrive in time → drops anyway. Verify with `ping -M do`.
- **Wrong DSCP → TC mapping on one side** → host marks AF31, switch maps it to TC0 → no PFC for that traffic. Fix with `qos map dscp X to traffic-class N` on both ends.
- **DCBX mode mismatch** (IEEE vs CEE) → no auto-negotiation → fall back to defaults → no lossless. Standardize on IEEE.
- **Asymmetric PFC** (enabled on switch but not on host NIC) → only one direction is lossless → drops happen on the un-paused direction.
- **PFC deadlock** in topologies with loops. Modern hardware has deadlock detection (Arista's "PFC Watchdog" feature) — enable it.

## What's missing (deliberately)

- **RoCE / RoCEv2 deployment** — RDMA over ethernet; the more demanding use case for PFC. Different configuration profile.
- **PFC Watchdog tuning** — deadlock detection on Arista
- **Buffer profiles** — on Arista, `platform sand qos` configurations
- **Host NIC tuning** — Mellanox `mlxconfig`, Intel `ethtool --set-priv-flags`
- **AI/ML cluster networking** — modern variant with even tighter latency requirements

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
