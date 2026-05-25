# Lab 05 — STP Protections

> **Format:** Hands-on. Same triangle topology as lab 04, with a rogue switch deliberately wired into an access port to test your defenses. Reference answer in [`solutions/`](solutions/).

## Real-world scenario

Your access network has three legitimate switches (lab 04 design). Today:

- A user "fixed their slow internet" by plugging an unmanaged 8-port switch into the office wall jack so they could connect their laptop, a NAS, and a printer. That switch's STP is running and *might* announce itself as root if it has a low MAC. Your team's design carefully picked sw1 as root — that user's $20 switch could undo it.
- Last month someone in a remote office plugged the *uplink* of a borrowed switch into the wrong port. The borrowed switch had a misconfigured priority of 0 and stole the root role from the entire campus for 90 seconds. The on-call engineer found out via PagerDuty.

You need three things, and you need them on every access switch:

1. Access ports must be **fast and rogue-proof** — host plugs should come up immediately, but any device that talks STP must be cut off.
2. Trunks toward less-trusted neighbors must **refuse to demote the configured root**, no matter what BPDUs they receive.
3. The design must survive someone plugging the wrong cable into the wrong port.

That's what PortFast + BPDU Guard + Root Guard buy you.

## Goal

By the end you should be able to answer:

- What is **PortFast** and why do hosts need it?
- What does **BPDU Guard** do, and when does it trigger?
- What's the difference between **BPDU Guard** and **BPDU Filter** (and why is filter rarely the right answer)?
- What does **Root Guard** protect against, and where do you put it?
- What's the recovery procedure when one of these protections fires?

## Topology

```mermaid
graph TB
    h1[h1] --> sw1
    h2[h2] --> sw2
    h3[h3] --> sw3
    sw1 ==trunk== sw2
    sw2 ==trunk== sw3
    sw1 ==trunk== sw3
    rogue[sw-rogue<br/>priority 0<br/>plugged into wall jack] -.Et4 access port.- sw1
```

Lab 04's triangle (sw1 = root @ priority 4096, sw2 = secondary @ 8192, sw3 = default) + a **rogue switch** wired into sw1's Et4. The rogue is configured with **priority 0** — it desperately wants to be root and is broadcasting BPDUs every 2 seconds.

## Theory primer

### PortFast — get hosts online faster

When a port comes up, classic STP makes it go through Listening → Learning → Forwarding (~30 seconds combined). For a host port, this is silly — there's no loop risk from a single PC. **PortFast** skips the wait: an edge port goes straight to Forwarding.

PortFast alone is unsafe — it assumes the device behind it isn't a switch. So PortFast almost always pairs with BPDU Guard.

### BPDU Guard — "this is a host port, nothing else"

When BPDU Guard is enabled and a BPDU arrives on the port, the switch **err-disables** the port. The port goes down hard. The device behind it is cut off until an operator manually re-enables the port (or err-disable recovery is configured to retry after a timeout).

Why err-disable instead of just blocking the BPDU?
- "Block the BPDU" (= **BPDU Filter**) would silently allow the rogue switch to *operate* on the port; it just hides STP from each side. That can create undetected L2 loops elsewhere.
- "Err-disable" guarantees the rogue can't pass any traffic at all. Loud failure > silent disaster.

**Rule of thumb**: every host-facing access port gets PortFast + BPDU Guard. Always. No exceptions for "this special device" — if it talks STP, it doesn't belong on an access port.

### Root Guard — "you may never become root via this port"

PortFast/BPDU Guard protect access ports. **Root Guard** protects trunks. The use case: you have a legitimate downstream switch (e.g. an access closet) reachable via a known trunk, and you want to allow normal switching but never allow that switch to become the root bridge of the spanning tree.

When a port has Root Guard and receives a **superior** BPDU (one that would make the sender root), the port goes into a **root-inconsistent** state — blocks traffic, but auto-recovers as soon as the superior BPDUs stop. No manual intervention needed (unlike BPDU Guard's err-disable).

Where to put Root Guard:
- On the trunks **away from the root**, on the root switch itself (and other core switches).
- On any trunk toward a switch you control administratively but don't fully trust to keep its STP priority sane.

You do NOT put Root Guard on the root port (toward the actual root) — that's where superior BPDUs are supposed to come from.

### Loop Guard, Bridge Assurance (mentioned, not configured)

- **Loop Guard** — protects against unidirectional link failures that cause a blocked port to incorrectly transition to forwarding (because BPDUs stopped arriving). Put it on root ports and alternate ports of trunks.
- **Bridge Assurance** — Cisco-specific; sends BPDUs on every operational port, treats lack of BPDUs as failure. Belt-and-suspenders for trunks between known switches.

We won't configure these in this lab but they exist; see [`docs/concepts/stp-protections-reference.md`](../../docs/concepts/stp-protections-reference.md) when we add it.

## Your task

1. Add **PortFast + BPDU Guard** to every host-facing access port:
   - sw1: Et1 (h1) and Et4 (wall jack with sw-rogue)
   - sw2: Et1 (h2)
   - sw3: Et1 (h3)
2. Add **Root Guard** to sw1's Et3 (trunk to sw3) so sw3 can never claim root via that link.
3. Observe sw1 Et4 immediately err-disable when your config touches it (sw-rogue's BPDUs are already arriving — the guard fires the moment it's enabled).
4. As a bonus, force a root-guard event: set sw3's priority to 0 and watch sw1 Et3 go root-inconsistent.

## Hints

EOS commands per access port:

```
interface Ethernet<n>
  spanning-tree portfast
  spanning-tree bpduguard enable
```

EOS command for root guard on a trunk:

```
interface Ethernet<n>
  spanning-tree guard root
```

Recovery from err-disable (after the rogue is removed in real life):

```
configure terminal
  interface Ethernet<n>
    no shutdown
```

Or with auto-recovery configured globally:

```
errdisable recovery cause bpduguard
errdisable recovery interval 300
```

## Deploy

```bash
cd ~/containerlab/labs/05-stp-protections
sudo containerlab deploy
```

## Verification

### 1. Confirm the baseline — sw-rogue can currently talk

Before you change anything:

```bash
docker exec -it clab-stp-protections-sw1 Cli
```

```
show spanning-tree
show interfaces Ethernet4 status
```

Et4 is up. sw-rogue is sending BPDUs (it has priority 0!), and you might even see it appearing in `show spanning-tree` as a candidate root — depending on whether sw1 is filtering it on the access port. This is the "uncontrolled" baseline.

### 2. Enable BPDU Guard on Et4 — watch the trap snap

Apply the PortFast + BPDU Guard config to Et4. Within ~2 seconds:

```
show interfaces Ethernet4 status
show logging | tail
```

Port status: `errdisabled`. Log line: BPDU Guard error-disabled. **sw-rogue is now cut off**. It can't pass traffic. The user's $20 switch is dead until an operator re-enables it.

### 3. Recover (simulate "rogue device removed")

In real life: identify what was plugged in, remove it, then `no shutdown` the port. Here, sw-rogue is still connected, so re-enabling will just err-disable again — which is the point.

To prove that, try recovery:

```
configure terminal
  interface Ethernet4
    no shutdown
```

Wait 5–10 seconds. Re-check:

```
show interfaces Ethernet4 status
```

Back to `errdisabled`. The protection is permanent until the rogue is physically removed.

### 4. Demonstrate Root Guard

Apply Root Guard to sw1 Et3 (the trunk toward sw3). Verify nothing breaks:

```
show spanning-tree
show interfaces Ethernet3 status
```

sw1 is still root, Et3 is still forwarding (designated). Now make sw3 try to steal root:

```bash
docker exec -it clab-stp-protections-sw3 Cli
```

```
configure terminal
  spanning-tree vlan-id 10 priority 0
end
```

Back on sw1:

```
show spanning-tree
show spanning-tree inconsistentports
```

sw1 Et3 should now be **root-inconsistent** — the port is blocked because sw3's superior BPDU was rejected. **sw1 stays root**, sw3's BPDUs are ignored on that link.

Recovery: undo the priority change on sw3:

```
no spanning-tree vlan-id 10 priority
```

Within seconds sw1 Et3 returns to designated/forwarding without manual intervention.

### 5. Trace the BPDUs

```bash
sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' clab-stp-protections-sw1) -n tcpdump -i eth4 -nn -e stp
```

After BPDU Guard fires, the port is shut — no more BPDUs. Re-enable briefly and capture before it re-disables to see the actual rogue BPDU.

## Peek at solution

- [`solutions/sw1.cfg`](solutions/sw1.cfg) — PortFast + BPDU Guard on Et1, Et4; Root Guard on Et3
- [`solutions/sw2.cfg`](solutions/sw2.cfg), [`solutions/sw3.cfg`](solutions/sw3.cfg) — PortFast + BPDU Guard on host ports

## Concepts cheat-sheet

- **PortFast** — skip the STP learning delay for edge ports; host comes up immediately.
- **BPDU Guard** — receiving a BPDU on a PortFast port = port goes err-disabled. Loud, manual recovery. Default for host ports.
- **BPDU Filter** — silently drop BPDUs in/out of the port. **Almost always the wrong choice** — masks problems instead of stopping them.
- **Root Guard** — port-level protection on trunks; receiving a superior BPDU = port goes root-inconsistent (auto-recovers when bad BPDUs stop). Put on designated ports facing potentially-misbehaving neighbors.
- **Loop Guard** — port-level protection against unidirectional link failures causing incorrect transition to forwarding. Put on root/alternate ports.
- **Err-disable recovery** — global feature to auto-`no shutdown` ports after a cooldown. Useful but should be tuned per cause; for BPDU Guard, manual recovery is often preferred so the root cause gets investigated.

## Production hardening checklist (from this lab)

For every access switch you ever touch:

- ✅ Every host-facing access port: `portfast` + `bpduguard enable`
- ✅ Every trunk toward less-trusted devices (campus access, partner connect, lab gear): `guard root`
- ✅ Trunks between trusted core/distribution switches: consider Loop Guard (and Bridge Assurance on Cisco)
- ✅ Deterministic root priority on core (not 0 — use 4096 as primary, 8192 as secondary)
- ✅ Err-disable recovery configured with sane causes/intervals, not blanket auto-recover

## What's missing (deliberately)

- **MSTP / per-VLAN priority** — covered in MSTP-specific labs later
- **STP load-balancing across multiple instances** — design topic, not protection
- **Storm control** — lab 06
- **DHCP snooping / DAI / IPSG** — lab 07

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
