# Linux Networking — Quick Reference for the Network Engineer

> Modern network devices (cEOS, FRR, SONiC) are Linux underneath. Your servers are Linux. Your monitoring stack runs on Linux. A network engineer who's not comfortable with Linux networking commands debugs at a disadvantage. This is the short reference — enough to operate effectively. The deep dive is a separate course.

## The commands that replaced `ifconfig`

If you're still typing `ifconfig`, you're learning from old material. The modern toolkit is the **iproute2** suite:

| Old | New | Purpose |
|---|---|---|
| `ifconfig` | `ip addr` / `ip link` | Show/configure interfaces |
| `route` | `ip route` | Routing table |
| `arp` | `ip neigh` | ARP / neighbor cache |
| `netstat` | `ss` | Socket statistics |
| `iptables` | `nftables` (`nft`) | Packet filtering (iptables still works but is being deprecated) |

The `ip` commands accept abbreviations: `ip a`, `ip r`, `ip n` — common in muscle memory.

## Interface inspection and config

```bash
# Show interfaces and their addresses
ip addr
ip addr show dev eth0

# Show only L2 info
ip link
ip link show dev eth0

# Bring an interface up/down
ip link set eth0 up
ip link set eth0 down

# Set a MAC address
ip link set eth0 address aa:bb:cc:dd:ee:ff

# Add/remove an IP
ip addr add 10.0.0.1/24 dev eth0
ip addr del 10.0.0.1/24 dev eth0

# MTU
ip link set eth0 mtu 9000
```

## Routing

```bash
# Show the routing table
ip route
ip r

# Add a route
ip route add 10.20.0.0/24 via 10.10.0.1
ip route add default via 192.168.1.1

# Remove a route
ip route del 10.20.0.0/24

# Show route for a specific destination
ip route get 8.8.8.8
```

`ip route get` is underused: it tells you "if I tried to send to X right now, which interface and gateway would the kernel use?" Critical for "why isn't my packet going where I expect?"

## ARP / neighbor cache

```bash
# Show neighbor (ARP) cache
ip neigh

# Show only entries for a specific interface
ip neigh show dev eth0

# Flush the entire cache (forces re-ARP for everyone)
ip neigh flush all

# Flush for a specific interface
ip neigh flush dev eth0

# Add a static neighbor entry
ip neigh add 10.0.0.5 lladdr aa:bb:cc:dd:ee:ff dev eth0
```

`ip neigh flush all` is sometimes the right answer when you're debugging a weird L2 issue and want to start clean. Costs a brief re-ARP delay; usually invisible.

## VRFs on Linux

Yes, Linux has VRFs. The mechanism:

```bash
# Create a VRF named MGMT, associated with table 100
ip link add MGMT type vrf table 100
ip link set MGMT up

# Put eth0 into the MGMT VRF
ip link set eth0 master MGMT

# Routes in this VRF
ip route show vrf MGMT
ip route add 10.0.0.0/24 via 192.168.1.1 vrf MGMT

# Run a command sourced from a specific VRF
ip vrf exec MGMT ping 8.8.8.8
ip vrf exec MGMT curl https://example.com
```

This is the same VRF concept from lab 08 — just on Linux instead of a switch. Useful for:
- Servers with management traffic in a separate VRF.
- Reproducing network-device VRF behavior on a test host.

## Network namespaces

A **network namespace** is a fully isolated network stack inside one Linux kernel. Each namespace has its own interfaces, routing table, ARP cache. Containers use them; you can use them directly too.

```bash
# Create a namespace
ip netns add testns

# List namespaces
ip netns

# Create a veth pair (one in default ns, one in testns)
ip link add veth0 type veth peer name veth0p
ip link set veth0p netns testns

# Configure them
ip addr add 10.10.0.1/24 dev veth0
ip -n testns addr add 10.10.0.2/24 dev veth0p
ip link set veth0 up
ip -n testns link set veth0p up
ip -n testns link set lo up

# Run a command in the namespace
ip netns exec testns ping 10.10.0.1
```

Useful for reproducing network problems in isolation without touching real interfaces.

(For containerlab/cEOS containers, namespaces are managed by Docker, accessible via `nsenter -t <pid> -n`. See [`tcpdump-fluency.md`](tcpdump-fluency.md).)

## Sockets and listening services

```bash
# List all listening TCP/UDP sockets
ss -tunlp

# Just TCP, with process names
ss -tlnp

# Connections to/from a specific port
ss -tn sport = :443
ss -tn dport = :22

# Show socket details (state, queue depth, retransmits)
ss -tin
```

`ss` replaces `netstat`. Much faster on busy systems. Use `-p` to see the owning process (requires root).

## Tracing connectivity

```bash
# Classic ping
ping -c 5 8.8.8.8

# Ping with size + DF (don't fragment) — MTU testing
ping -M do -s 1472 8.8.8.8

# Source from a specific interface
ping -I eth1 8.8.8.8

# Continuous trace with stats per hop
mtr 8.8.8.8

# mtr with TCP probes (firewall-friendlier than ICMP)
mtr --tcp --port 443 example.com

# Traceroute with UDP / ICMP / TCP
traceroute -n 8.8.8.8           # UDP (default)
traceroute -nI 8.8.8.8          # ICMP
traceroute -nT -p 443 8.8.8.8   # TCP
```

`mtr` is one of the best diagnostic tools — continuous, per-hop loss and latency. Often the right answer to "why is traffic between these two hosts weird?"

## Packet inspection (briefly)

See [`tcpdump-fluency.md`](tcpdump-fluency.md) for the full guide. A starter:

```bash
sudo tcpdump -i eth0 -nn host 10.0.0.1
```

## Interface stats with `ethtool`

```bash
# Show interface settings
ethtool eth0

# Show stats (per-NIC counters)
ethtool -S eth0

# Show driver info
ethtool -i eth0

# Show transceiver / SFP info (if supported)
ethtool -m eth0

# Force speed/duplex (rare, mostly autonegotiation now)
ethtool -s eth0 speed 1000 duplex full autoneg off

# Show errors per-counter (good for "is this NIC degrading?")
ethtool -S eth0 | grep -E 'err|drop|rx_|tx_'
```

`ethtool -S` is what you actually look at in production. The driver-level error counters often reveal issues before the kernel-level interface counters do.

## Linux bridge (briefly)

If you're working on a Linux host that's bridging traffic (KVM bridge, Docker bridge, etc.):

```bash
# Show bridges
bridge link show
ip link show type bridge

# Show MAC table of a bridge
bridge fdb show

# Add an interface to a bridge
ip link set eth1 master br0
```

Knowing how Linux bridges work helps you debug VM/container networking.

## Some useful one-liners

```bash
# Show what's using bandwidth
ss -i | grep -E 'cwnd|rtt'

# Show kernel network statistics
nstat
ip -s link show dev eth0     # per-interface stats

# Show conntrack table (NAT and stateful FW state)
sudo conntrack -L

# Show IPv4 forwarding state
sysctl net.ipv4.ip_forward
# Enable IPv4 forwarding
sudo sysctl -w net.ipv4.ip_forward=1
```

## Configuration files vs runtime commands

The `ip` commands change **runtime** state. They don't persist across reboot.

For persistent config, modern Linux uses:
- **systemd-networkd** (`.network` files in `/etc/systemd/network/`)
- **NetworkManager** (`nmcli`, useful on desktops and some servers)
- **netplan** (Ubuntu's wrapper, generates configs for above)
- **Distribution-specific** (`/etc/network/interfaces` on older Debian, `/etc/sysconfig/network-scripts/` on older RHEL)

Knowing the persistence mechanism matters. A change you make with `ip route add` disappears on reboot — useful for debugging, dangerous if you forgot to make it permanent.

## TCP tuning (very briefly)

You'll occasionally hear about TCP tuning on hosts for high-throughput links:

```bash
# Show TCP settings
sysctl net.ipv4.tcp_congestion_control
sysctl net.ipv4.tcp_rmem
sysctl net.ipv4.tcp_wmem

# Tune for high-bandwidth-delay-product links (long-fat networks)
sudo sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216'
sudo sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216'
```

This is *real* engineering — modifying it without measuring is cargo-cult. But knowing it exists matters when application teams complain about TCP throughput between hosts.

## Common workflows

### "Is the host's NIC up and configured?"

```bash
ip link show eth0      # is it up?
ip addr show eth0      # does it have an IP?
ip route get 8.8.8.8   # does it have a route out?
```

Three commands, complete L1-L3 health check on the host.

### "What's making this host slow on the network?"

```bash
ss -i                  # check TCP retransmits, congestion window
ethtool -S eth0 | grep err   # NIC-level errors
ip -s link show eth0   # interface counters
mtr 8.8.8.8            # path quality
```

### "Why can't I reach this destination?"

```bash
ip route get <dst>     # what path does the kernel pick?
ping <dst>             # basic reachability
traceroute -n <dst>    # where does it die?
ss -tn dport = :<port> # is anything actually listening?
```

### "What's eating my bandwidth?"

```bash
iftop -i eth0          # if installed, real-time per-flow bandwidth
nethogs                # per-process bandwidth
tcpdump -nn -c 100 -i eth0  # what's actually flowing?
```

---

**Story-arc references**:
- **Phase 1+**: as soon as you're SSHing into containerlab hosts or real Linux servers, these commands are your daily bread.
- **Phase 3-4**: management VRF on Linux (used by container hosts), namespaces (used by VMs/containers).
- **Phase 5+**: tuning TCP for high-throughput application servers, configuring conntrack for NAT scenarios, debugging high-flow performance.

## What this isn't

This is a quick reference, not a course. Topics deliberately omitted because they're each a course in their own right:

- **nftables / iptables** (firewall) — large topic, separate domain.
- **eBPF / XDP** — modern programmable kernel networking; a separate field.
- **DPDK / kernel bypass** — high-performance networking.
- **systemd-networkd / NetworkManager / netplan internals** — distribution-specific.

If any of these come up regularly in your work, dedicate real time to learning them properly — separate from this curriculum.

## TL;DR

- Use `ip` (iproute2), not `ifconfig` / `route` / `arp`.
- `ip route get <dst>` answers "where would the kernel send this packet?"
- `ss` replaces `netstat`. Faster, better.
- `ethtool -S` shows the driver-level counters that catch NIC issues early.
- VRFs and namespaces work on Linux; you'll meet them in container hosts and real servers.
- Runtime ≠ persistent. Know your distribution's config mechanism.
