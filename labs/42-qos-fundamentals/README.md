# Lab 42 — QoS Fundamentals

> **Format:** Hands-on. Classify traffic at ingress, mark with DSCP, give the latency-sensitive class strict priority on egress. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 8 · Senior+ · Year 4–5. A customer added a VoIP service to their hosting bundle. When their nightly backup runs, voice quality collapses — calls go choppy, audio drops. Same network, same uplink. The fix isn't "more bandwidth" — it's making sure voice gets to skip the queue. See [`STORY.md`](../../STORY.md).
>
> **Syntax verification:** QoS syntax varies significantly across cEOS / production EOS / different chipsets. The config in this lab represents the *pattern*; on a specific platform check `show qos interface` and the EOS Manual chapter "Quality of Service".

## Real-world scenario

A customer hosts both a VoIP PBX and a file-backup target on the same VM cluster. Their uplink is 1 Gbps. Most of the time everyone's happy. But every night at 02:00 the backup runs and saturates the uplink — and the on-call engineer in Singapore (where it's daytime) can't have a clear call with the team.

You can't buy more bandwidth (it's a fixed customer contract). The real fix: when the link is full, **voice packets jump the queue**. Bulk traffic waits a few milliseconds longer; voice stays sub-20ms one-way. The customer hears nothing different. That's QoS.

## Goal

- Classify traffic at the network edge by some attribute (port, ACL, DSCP)
- Mark traffic with a DSCP value that *survives the trip* through the fabric
- On every potentially-congested interface, configure queue scheduling so voice (EF) gets priority over bulk (CS1)

## Theory primer

### The QoS pipeline

```
[ingress] → classify → mark → [transit] → queue → schedule → [egress]
              ↑          ↑                  ↑          ↑
            "what       "stamp it"      "put in     "decide
             is this?"                   the right   what to
                                         queue"     send next"
```

Three jobs, three places:
- **Edge (ingress)**: classify and mark. This is where you decide what class a packet belongs to. Do it once, at the trust boundary.
- **Core (transit)**: trust the marking. Don't reclassify.
- **Every potentially-congested interface (egress)**: queueing and scheduling. This is where QoS actually does work — when the link is full and you have to choose what to send next.

### DSCP — the marking field

6 bits in the IPv4 ToS / IPv6 Traffic Class byte. 64 possible values, but in practice only a handful are used:

| DSCP name | Decimal | Typical use |
|---|---|---|
| EF (Expedited Forwarding) | 46 | Voice RTP — strict priority |
| CS5 | 40 | Voice signaling (SIP) |
| AF41 | 34 | Video conferencing |
| AF31 | 26 | Multimedia streaming |
| CS3 | 24 | Signaling/broadcast video |
| AF21 | 18 | Important data |
| 0 (BE) | 0 | Best-effort default |
| CS1 | 8 | Scavenger / bulk / backups |

The values themselves don't *do* anything — they're just labels. What matters is that every device on the path agrees what each label means and treats them accordingly.

### Scheduling

When a link is congested, the scheduler decides which queue to drain next. Common patterns:

- **Strict priority (LLQ — Low Latency Queue)**: queue X is drained first whenever it has packets. Used for voice. Risk: starves everything else if not capped.
- **Weighted Round Robin (WRR) / DWRR**: each queue gets a share proportional to its weight. Used for everything that isn't LLQ.
- **WFQ / CBWFQ**: fair queueing with class-based weights.

A typical voice-aware config:
- tx-queue 7 (EF) → strict priority, capped at, say, 30% of link
- tx-queues 0–6 → DWRR with weights for default, bulk, etc.

### Shaping vs policing

- **Policing**: drop (or remark) traffic exceeding a rate. Cheap, but bursty traffic suffers.
- **Shaping**: buffer traffic up to a rate. Smoother but adds latency and uses memory.

Use policing at edges for ingress contracts; use shaping at egress to smooth traffic toward a sub-rate.

## Your task

1. On `sw1`, mark all ingress from `voice` (Ethernet1) as DSCP EF.
2. Mark all ingress from `bulk` (Ethernet2) as DSCP CS1.
3. On the uplink trunk (sw1 Ethernet3), configure tx-queue 7 as strict priority and give the default queue ~20% bandwidth.
4. On `sw2`, trust DSCP on the trunk (don't re-mark).

## Verification

### Inspect QoS state
```bash
docker exec -it clab-qos-fundamentals-sw1 Cli
show qos interface Ethernet3
show qos maps
```

### Generate voice + bulk traffic
On `receiver`, listen with iperf3:
```bash
docker exec -d clab-qos-fundamentals-receiver iperf3 -s
```

From `voice` (mimics voice with small UDP packets at ~100 kbps):
```bash
docker exec clab-qos-fundamentals-voice iperf3 -c 10.0.1.10 -u -b 100K -l 200 -t 30
```

From `bulk` (saturate):
```bash
docker exec clab-qos-fundamentals-bulk iperf3 -c 10.0.1.10 -b 0 -t 30
```

Voice flow's jitter and loss should stay low even when bulk saturates. Without the QoS policy, voice loss climbs with bulk's throughput.

### Verify DSCP marking
On `receiver`:
```bash
docker exec clab-qos-fundamentals-receiver tcpdump -i eth1 -nn -v 'src host 10.0.0.10' -c 5
```

Look for `tos 0xb8` (DSCP 46 = EF). For `10.0.0.20` (bulk), look for `tos 0x20` (DSCP 8 = CS1).

## What's missing (deliberately)

- **WRED (Weighted Random Early Detection)** — TCP-friendly congestion avoidance
- **Hierarchical QoS** (parent shaper + child policy) — common on WAN edges
- **Per-tenant rate limits** (covered conceptually in lab 48)
- **MPLS EXP / 802.1p CoS interaction** — relevant on L2 service-provider gear
- **Trust boundary discussions** (when not to trust DSCP from a customer) — production policy
- **End-host marking** — Linux `tc` / Windows QoS / softphone DSCP

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
