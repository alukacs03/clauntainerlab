# tcpdump Fluency for the Network Engineer

> Career multiplier. Engineers who are comfortable with tcpdump debug in minutes what others spend hours guessing about. This guide is the practical reference: filters you'll use, patterns for common protocols, and a way of thinking about packet capture.

## The mental model

tcpdump answers one question with high precision: **what is actually on the wire?**

When configs look right but the network is misbehaving, tcpdump tells you what the boxes are actually saying to each other. No guessing, no inference — direct observation.

The skill is twofold:
1. **Constructing filters** so you see what you want, not 10,000 lines of irrelevance.
2. **Reading output** with enough protocol knowledge to extract meaning.

## Where to run tcpdump on cEOS / containerlab

Container network namespaces aren't registered under `/var/run/netns`, so plain `ip netns exec` doesn't find them. Two ways:

```bash
# 1. nsenter from the host into the container's network namespace
sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' clab-<lab>-sw1) -n tcpdump -i eth1 -nn ...

# 2. docker exec if tcpdump is in the container
docker exec clab-<lab>-sw1 tcpdump -i eth1 -nn ...
```

The first form is more reliable (uses the host's tcpdump regardless of what's inside).

## Common flags you'll use 90% of the time

| Flag | Purpose |
|---|---|
| `-i <intf>` | Interface to capture on (`-i any` for all) |
| `-nn` | Don't resolve hostnames or port names. Faster, cleaner output. **Always use.** |
| `-e` | Show Ethernet header (MAC addresses, EtherType, VLAN tags) |
| `-v` / `-vv` / `-vvv` | Verbose — more decoded protocol fields |
| `-c <N>` | Capture N packets then exit |
| `-w <file>` | Write to file (for later analysis or sharing) |
| `-r <file>` | Read from file |
| `-s <N>` | Snap length (bytes per packet). `-s 0` for full packets. |
| `-tttt` | Human-readable timestamps with date |
| `-X` | Hex+ASCII payload dump (good for HTTP, occasional protocol decoding) |
| `-A` | ASCII-only payload (good for plain-text protocols) |

A reasonable default:

```bash
tcpdump -i eth1 -nn -e -tttt
```

## Filter syntax — the basics

tcpdump uses BPF (Berkeley Packet Filter) syntax. The grammar:

- **Host**: `host 10.0.0.1`, `src host`, `dst host`
- **Net**: `net 10.0.0.0/24`
- **Port**: `port 179`, `src port 443`, `dst port 22`
- **Protocol**: `tcp`, `udp`, `icmp`, `arp`, `ip`, `ip6`
- **Combine**: `and`, `or`, `not`
- **Group**: `( ... )` (escape in shells if needed)

Examples:

```bash
# All traffic to/from a specific host
tcpdump -i eth1 -nn host 10.0.0.1

# Only BGP traffic
tcpdump -i eth1 -nn tcp port 179

# Specific subnet only, but not ICMP
tcpdump -i eth1 -nn 'net 10.0.0.0/24 and not icmp'

# Both directions of an SSH session
tcpdump -i eth1 -nn '(src host 10.0.0.1 and dst port 22) or (src port 22 and dst host 10.0.0.1)'
```

## Per-protocol filter recipes

### BGP

```bash
# All BGP control traffic
tcpdump -i eth1 -nn tcp port 179

# BGP between two specific peers
tcpdump -i eth1 -nn 'host 10.0.0.1 and host 10.0.0.2 and tcp port 179'

# Only BGP OPEN/UPDATE messages (TCP payload analysis)
tcpdump -i eth1 -nn -X tcp port 179
```

### OSPF

```bash
# All OSPF (IP protocol 89)
tcpdump -i eth1 -nn ip proto 89

# OSPF Hello packets specifically (sent to 224.0.0.5)
tcpdump -i eth1 -nn 'ip proto 89 and host 224.0.0.5'
```

### BFD

```bash
# BFD asynchronous mode runs on UDP/3784
tcpdump -i eth1 -nn udp port 3784

# BFD echo mode runs on UDP/3785
tcpdump -i eth1 -nn udp port 3785
```

### ARP

```bash
# All ARP
tcpdump -i eth1 -nn arp

# ARP requests only
tcpdump -i eth1 -nn 'arp and arp[6:2] = 1'

# Gratuitous ARPs (sender IP == target IP)
tcpdump -i eth1 -nn -e 'arp and arp[24:4] = arp[14:4]'
```

### VLANs (802.1Q)

```bash
# Show VLAN tags on a trunk
tcpdump -i eth4 -nn -e vlan

# Specific VLAN only
tcpdump -i eth4 -nn -e vlan 10

# Untagged traffic (frames without 802.1Q tag) — note: not "vlan 0", that has special meaning
tcpdump -i eth4 -nn -e 'not vlan'
```

### VXLAN

```bash
# Default VXLAN UDP port
tcpdump -i eth1 -nn udp port 4789

# Show outer + inner with verbose decode
tcpdump -i eth1 -nn -vvv udp port 4789

# Specific VTEP-to-VTEP flow
tcpdump -i eth1 -nn '(src host 11.11.11.11 and dst host 22.22.22.22 and udp port 4789)'
```

### DHCP

```bash
# DHCP runs on UDP/67 (server) and UDP/68 (client)
tcpdump -i eth1 -nn 'udp and (port 67 or port 68)'

# Just DHCP DISCOVER/REQUEST from client
tcpdump -i eth1 -nn 'udp src port 68 and udp dst port 67'
```

### ICMP

```bash
# All ICMP
tcpdump -i eth1 -nn icmp

# Only ICMP echo requests/replies (ping)
tcpdump -i eth1 -nn 'icmp and (icmp[icmptype] = icmp-echo or icmp[icmptype] = icmp-echoreply)'

# ICMP unreachables — useful for "where is traffic dying?"
tcpdump -i eth1 -nn 'icmp and icmp[icmptype] = icmp-unreach'
```

### LACP

```bash
# LACP (slow protocol)
tcpdump -i eth1 -nn -e ether proto 0x8809
```

### STP

```bash
# STP BPDUs
tcpdump -i eth1 -nn -e stp
```

### DNS

```bash
# All DNS
tcpdump -i eth1 -nn udp port 53

# DNS responses (verbose enough to see the answer)
tcpdump -i eth1 -nn -vvv udp src port 53
```

## Reading output

A typical line looks like:

```
14:23:01.234567 IP 10.10.10.1.42398 > 10.20.20.10.80: Flags [S], seq 12345, win 64240, length 0
```

Decoding:
- `14:23:01.234567` — timestamp (microsecond precision)
- `IP` — Ethertype (might be ARP, IPv6, etc.)
- `10.10.10.1.42398 > 10.20.20.10.80` — source IP.port → destination IP.port
- `Flags [S]` — TCP flag (S=SYN, A=ACK, F=FIN, R=RST, P=PSH, .=no flag)
- `seq 12345` — TCP sequence number
- `win 64240` — TCP receive window
- `length 0` — payload length (0 for SYN)

For other protocols (UDP, ICMP, ARP), the layout adapts but the time-source-dest pattern stays.

### TCP three-way handshake recognition

You'll see this often:

```
A.42398 > B.80: Flags [S]              # SYN
B.80    > A.42398: Flags [S.]          # SYN-ACK
A.42398 > B.80: Flags [.]              # ACK
```

If the SYN goes out but no SYN-ACK comes back, the connection isn't establishing. Possible causes: routing issue, firewall, the destination isn't listening on that port.

If SYN/SYN-ACK happen but then RST appears, the destination actively closed the connection — often a TCP keepalive timeout, or the destination has the port closed at the application layer.

## Patterns that catch real bugs

### Pattern: "the link is up but no traffic"

```bash
# Capture in both directions
tcpdump -i eth1 -nn -e
```

- If you see traffic in one direction but not the other: unidirectional link issue, ACL, asymmetric routing.
- If you see traffic going out but no responses: destination not reachable, return-path broken.
- If you see no traffic at all: nothing is trying to use this link. Generate test traffic (ping from a host) and try again.

### Pattern: "asymmetric path"

```bash
# On interface A
tcpdump -i ethA -nn host <src> and host <dst>

# On interface B simultaneously
tcpdump -i ethB -nn host <src> and host <dst>
```

If outbound goes via A but inbound via B, you have asymmetric routing. Often fine; sometimes breaks stateful firewalls or causes weird latency.

### Pattern: "is the MTU issue real?"

```bash
# Look for fragmentation
tcpdump -i eth1 -nn 'ip[6:2] & 0x1fff != 0 or ip[6] & 0x20 != 0'

# Or look for ICMP "Fragmentation needed" (PMTU)
tcpdump -i eth1 -nn 'icmp[0] = 3 and icmp[1] = 4'
```

### Pattern: "spoofed source addresses"

```bash
# Source MAC doesn't match expected
tcpdump -i eth3 -nn -e 'ether src not 00:11:22:33:44:55'

# Source IP outside expected range (subnet on the access port)
tcpdump -i eth3 -nn 'src not net 10.10.10.0/24'
```

### Pattern: "broadcast storm"

```bash
# Just broadcast traffic
tcpdump -i eth1 -nn -e ether broadcast

# Multicast (often confused with broadcast)
tcpdump -i eth1 -nn -e ether multicast
```

A normal segment has some broadcast and multicast (ARP, IGMP, OSPF Hellos). A *storm* is when the volume is dramatically higher than baseline. Combine with `-c 1000` and see how long it takes to fill — that tells you the rate.

### Pattern: "weird latency"

```bash
# Capture with full timestamps; analyze later for jitter
tcpdump -i eth1 -nn -tttt -w /tmp/capture.pcap

# Read back with timestamps; compute deltas between packets
```

Or use `tshark`/Wireshark for proper latency analysis — `tcpdump` alone isn't great at calculating deltas, but the raw timestamps are there.

## Capturing for offline analysis

If the issue is complex and you want to study the capture later:

```bash
# Capture full packets, written to file
sudo tcpdump -i eth1 -s 0 -w /tmp/issue.pcap

# Filter while writing (smaller file)
sudo tcpdump -i eth1 -s 0 -w /tmp/bgp.pcap tcp port 179
```

Then transfer the `.pcap` and read with `tcpdump -r` or open in Wireshark for graphical analysis.

**Rotation**: `-G <seconds> -W <count>` rotates capture files. Useful for long-running diagnostics:

```bash
# Rotate every hour, keep 24 files (1 day of history)
sudo tcpdump -i eth1 -G 3600 -W 24 -w '/tmp/cap-%Y%m%d-%H%M.pcap' -s 0
```

## Performance considerations

`tcpdump` is heavier than you'd think on a busy interface. On a host doing 10 Gbps, full-packet capture can saturate the CPU and cause packet drops *in tcpdump itself* — meaning you miss packets and don't realize it.

Mitigations:
- **Narrow the filter**: capture only relevant flows.
- **Use `-s <small>`**: capture only the first N bytes per packet (e.g., 96 bytes catches all headers but not payload).
- **`-w file` instead of stdout**: writing to disk is faster than rendering text.
- **Avoid heavy verbose decoding (`-vvv`)** on high-rate captures.

If tcpdump reports `dropped N packets by kernel` at exit, you missed data. Tighten the filter and retry.

## tcpdump and the management plane

Avoid capturing on the management interface during incident response. The capture process itself adds CPU load; if the control plane is already strained (BGP flapping, BFD timing out), tcpdump might push it over the edge.

Capture on the *data interface* of interest, or use a dedicated capture port (mirror/SPAN if configured).

## When tcpdump isn't enough

- **Beyond packet capture**: for very high-rate flows you might want hardware-accelerated capture (DPDK, AF_XDP, or vendor mirror-to-collector).
- **Aggregated views**: tcpdump is per-interface, per-packet. For "show me all flows summarized" you want flow records (NetFlow, sFlow, IPFIX).
- **Application-layer protocol decoding**: Wireshark is dramatically better at decoding complex application protocols. Use tcpdump to capture, Wireshark to analyze.

But for the network engineer's daily debug — *what is actually on this link right now?* — tcpdump is the right tool 90% of the time.

## Practice this skill

The reason most engineers aren't tcpdump-fluent: they never practice. tcpdump is a "use it or lose it" skill.

Suggestions:
- **Capture in the labs.** Each lab has packet-on-the-wire moments — VLAN tags in lab 03, STP BPDUs in lab 04, VRRP advertisements in lab 13, VXLAN encap in lab 29. Capture each and read the output. Build intuition.
- **Capture during your own changes.** Before/after a config change, capture. See what changed on the wire.
- **Maintain a personal cheat-sheet** of filter recipes for protocols you debug often.
- **Pair-debug with a senior**: when they're using tcpdump, watch their filter choices and ask "why that filter, not this one?"

In ~3 months of regular use, you'll go from "I have to look up the filter syntax every time" to "the filter syntax is muscle memory and I'm reading output fluently". The skill compounds.

---

**Story-arc references**:
- **Phase 1+**: every lab in this curriculum benefits from `tcpdump` somewhere. The lab READMEs include specific captures to run.
- **Phase 3+**: in real incidents, `tcpdump` is your fastest path from "I don't know what's wrong" to "I see the issue."
- **Phase 5-6 (BGP/EVPN)**: capturing on the underlay to verify VXLAN encap is what real-life debugging looks like.

## TL;DR

- `tcpdump -i <intf> -nn -e` is your default base command.
- Build filter recipes for the protocols you debug often.
- Read TCP flags fluently — `[S]`, `[S.]`, `[.]`, `[F]`, `[R]` patterns tell you the connection lifecycle.
- Capture to `.pcap` when the issue is complex.
- Use it constantly — fluency comes from repetition.
