# Lab 04 — Spanning Tree (RSTP)

> **Format:** Hands-on. The starter already has a working RSTP-protected loop. Your job is to *understand* the current state, then take deterministic control of the design. Reference answer in [`solutions/`](solutions/).

## Real-world scenario

You inherited an access-layer network. Three access switches are wired in a triangle for redundancy — any single link or switch can fail and connectivity survives. But:

- Nobody knows which switch is the **root bridge** today.
- The root election ran whenever the switches last booted, which means whichever booted first won.
- When you tested failover last quarter, traffic took an unexpected path because the root was "the wrong" switch.

Your job: pick a deterministic root, document the design, and watch RSTP converge under failure so you know exactly what will happen at 3 AM when a link fails.

## Goal

By the end you should be able to answer:

- What is a root bridge, and how is it elected?
- What do the port roles (**root port, designated port, blocked/alternate port**) mean?
- What's the difference between **STP** and **RSTP**, and why does it matter?
- What happens to traffic during a topology change, and how fast does it recover?
- Why is "leave defaults and hope" not an acceptable production design?

## Topology

```mermaid
graph TB
    h1[h1<br/>10.10.10.1] --> sw1
    h2[h2<br/>10.10.10.2] --> sw2
    h3[h3<br/>10.10.10.3] --> sw3
    sw1 ==trunk== sw2
    sw2 ==trunk== sw3
    sw1 ==trunk== sw3
```

Three switches in a triangle, one host per switch, all in VLAN 10 (subnet `10.10.10.0/24`). Three trunks — one of them will always be blocked by RSTP, because a triangle is a Layer 2 loop and only a loop-free spanning tree can survive.

## Theory primer

### Why we need STP at all

Ethernet has no TTL. A broadcast frame in a Layer 2 loop circulates forever, multiplied at every switch, until the broadcast domain melts. (You will eventually see this in a real outage. It's unforgettable.)

The solution: **Spanning Tree Protocol**. Switches elect a root bridge, then each switch computes the shortest path to the root. Links not on a shortest path are *blocked* — they exist physically, carry no data frames, but stand by for failover.

Result: a redundant physical topology is reduced to a loop-free *logical* tree. Add a fourth link tomorrow — STP will block it. Remove the currently-active link — STP unblocks a standby.

### Root election

Every switch starts believing it's the root. They exchange **BPDUs** (Bridge Protocol Data Units) on every trunk. A BPDU advertises:
- The sender's **bridge ID** = `priority` (lower is better) + `MAC address`
- The sender's idea of who the **root** currently is
- The **cost** to reach that root

Lowest bridge ID wins. Default priority is **32768**. When all priorities are equal, the lowest MAC wins — which means **whichever box came off the truck first** becomes root. That's no design.

### Setting priority deliberately

Modern practice: pick the root explicitly. On Arista:
- **4096** → primary root candidate
- **8192** → secondary (failover) root
- **32768** → default (leave alone for non-root switches)

Never set priority to 0 — leaves no headroom if you ever need to override.

### Port roles (RSTP)

After the tree converges, every trunk port has one of:

- **Root port** — *this switch's* best path toward the root. Exactly one per non-root switch.
- **Designated port** — *this switch's* best path toward a segment, on the switch advertising the lowest cost on that segment. Forwards traffic.
- **Alternate port (blocked)** — a backup path to the root that loses to a better port. Receives BPDUs, does not forward data.
- **Backup port** — rare; only when a switch has two ports on the same shared segment (mostly a hub-era concept).

On the root bridge itself, **every port is designated** (the root has no path "to" itself).

### STP vs RSTP

Classic STP (802.1D): convergence took ~50 seconds. Painful.

RSTP (802.1w, baseline default on every modern switch): uses proposal/agreement handshakes to converge in **under a second** on point-to-point links. Arista runs RSTP by default; configure it as MSTP later if you need per-VLAN-group control.

## Your task

1. Deploy and figure out **who the current root is** (probably whichever switch happens to have the lowest MAC).
2. Look at port roles on all three switches. **Which trunk is currently blocked?** Why that one?
3. Configure **sw1 as the primary root** by setting its priority to `4096`.
4. Configure **sw2 as the secondary root** (`8192`).
5. Re-check the topology. Did the blocked port move? Why?

## Hints

Arista commands you'll need:

```
configure terminal
  spanning-tree vlan-id <vlan> priority <value>
end
```

Inspection (no config needed):

```
show spanning-tree
show spanning-tree root
show spanning-tree blockedports
```

`show spanning-tree` is the daily-driver — gives you root, costs, roles, port states per VLAN in one screen.

## Deploy

```bash
cd ~/containerlab/labs/04-stp-rstp
sudo containerlab deploy
```

Wait ~30 seconds for cEOS to converge RSTP after boot.

## Verification

### 1. Identify the current root (before you change anything)

```bash
docker exec -it clab-stp-rstp-sw1 Cli
```

```
show spanning-tree root
```

The line listing "this bridge is the root" appears on exactly one switch. Repeat on sw2 and sw3 to confirm.

```
show spanning-tree
```

Note the "Role" column — find which port is `Altn` (alternate/blocked) — that's the loop-break.

### 2. Verify connectivity works despite the blocked port

```bash
docker exec -it clab-stp-rstp-h1 ping -c 3 10.10.10.3
```

✅ — even though one trunk is blocked, two are forwarding and that's enough for a connected tree.

### 3. Make sw1 the deterministic root

Apply priorities (see Hints). Then on sw1:

```
show spanning-tree root
```

It should now say sw1 is the root. Check sw2 and sw3 — they should agree, and report sw1's bridge ID as root.

### 4. Watch the blocked port move (if it did)

Before your change, the blocked port was somewhere in the triangle. After making sw1 the root, the blocked port is likely on a different switch — because the shortest-path tree shifted.

Find the new blocked port:

```
show spanning-tree blockedports
```

Reason it out: sw1 is root. sw2 and sw3 each need ONE root port (best path to sw1). The third trunk in the triangle is between sw2 and sw3, which is not on any shortest path to sw1 — so it's the one that gets blocked. On which end? The end with the **higher bridge ID** (lower priority loses). Since sw2 has priority 8192 and sw3 has 32768, the **sw3 side** becomes alternate/blocked.

### 5. Failover demo

While a sustained ping runs from h1 to h3, kill the link between sw1 and sw3 by shutting an interface:

```
docker exec -it clab-stp-rstp-sw1 Cli
configure terminal
  interface Ethernet3
    shutdown
```

Watch the ping. With RSTP you should lose **at most a few packets** before traffic reroutes via sw2. Then on sw3:

```
show spanning-tree
```

The previously-blocked port should now be forwarding — it took over as root path. RSTP transitioning a port from blocking→forwarding without the old 50s STP delay is the whole point.

Restore:

```
configure terminal
  interface Ethernet3
    no shutdown
```

### 6. Inspect a BPDU on the wire

```bash
sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' clab-stp-rstp-sw1) -n tcpdump -i eth2 -nn -e stp
```

You'll see BPDUs flowing roughly every 2 seconds. Inside each: root bridge ID, sender bridge ID, root path cost. This is the protocol's heartbeat.

## Peek at solution

- [`solutions/sw1.cfg`](solutions/sw1.cfg) — primary root, priority 4096
- [`solutions/sw2.cfg`](solutions/sw2.cfg) — secondary root, priority 8192
- [`solutions/sw3.cfg`](solutions/sw3.cfg) — unchanged

## Concepts cheat-sheet

- **Root bridge** — the switch elected as the top of the spanning tree. Lowest bridge ID (priority+MAC) wins. Set priorities deliberately; never trust defaults in production.
- **BPDU** — control frames switches exchange to run STP. Sent every 2s by default. Carries root info, cost, sender ID, timers.
- **Port roles**: Root (toward root), Designated (away from root on a segment this switch wins), Alternate (backup root path; blocked).
- **Port states (RSTP)**: Discarding, Learning, Forwarding. (Classic STP also has Listening/Blocking — gone in RSTP.)
- **Bridge priority increments** in steps of 4096 on most modern platforms. 4096 = primary root, 8192 = secondary, 32768 = default.
- **Convergence**: RSTP < 1s on healthy P2P links. Classic STP ~50s. Always run RSTP or MSTP today.
- **STP runs per VLAN by default on Arista** (Rapid-PVST style) — meaning each VLAN has its own tree and can have a different root. We use one VLAN here but that's a design lever for load-spreading on Cisco's PVST.

## Going deeper

- [Spanning Tree variants](../../docs/concepts/stp-variants.md) — the full family (STP, RSTP, MSTP, PVST+, RPVST+), what each adds, and how they interact with MLAG/EVPN.

## What's missing (deliberately)

- **MSTP** (Multiple Spanning Tree) — groups VLANs into instances. Important at scale but conceptually identical at this level.
- **STP protections** (BPDU guard, root guard, loop guard, bridge assurance) — lab 05.
- **TCN handling** — topology change notifications and MAC flushing are real but rarely something you touch directly.
- **MLAG** — eliminates the need for STP between MLAG peers, but STP still runs everywhere else. Lab 14.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
