# Lab 03 — Trunk Deep-Dive

> **Format:** Hands-on. Starter is a "lazy admin" trunk config that *works* but has three production-relevant problems. Your job is to harden it. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 1 · Junior · Month 2. An external auditor visits The Company. They flag your inter-switch trunks for allowing all VLANs and using VLAN 1 as native. You learn that vendor defaults are not production defaults. See [`STORY.md`](../../STORY.md).

## Real-world scenario

You're operating a multi-tenant access layer. Three tenants share these two switches via VLANs 10, 20, 30. A new audit just landed: the auditor flagged your trunks as "non-compliant" because they allow **all VLANs** and use **VLAN 1 as native**.

Your job: tighten the trunk between sw1 and sw2 without breaking anything for the tenants, and understand *why* each step matters. The same hardening will need to roll out across every inter-switch link in the network — so the exercise is also a template you'll reuse.

## Goal

Three things you should be able to explain by the end:

1. Why is "trunk allows all VLANs" the wrong default for production?
2. What's the **native VLAN** and why is leaving it as VLAN 1 a problem?
3. What does forcing native-VLAN traffic to be tagged (Arista's `switchport trunk native vlan tag`) actually do, and why does turning it on close a known attack vector?

## Topology

Same physical layout as labs 01/02, plus a third tenant on each switch.

```mermaid
graph LR
    h1[h1<br/>10.10.10.1<br/>VLAN 10 TENANT-A] --> sw1
    h2[h2<br/>10.20.20.2<br/>VLAN 20 TENANT-B] --> sw1
    h5[h5<br/>10.30.30.5<br/>VLAN 30 TENANT-C] --> sw1
    sw1 ===|trunk Et4| sw2
    sw2 --> h3[h3<br/>10.10.10.3<br/>VLAN 10]
    sw2 --> h4[h4<br/>10.20.20.4<br/>VLAN 20]
    sw2 --> h6[h6<br/>10.30.30.6<br/>VLAN 30]
```

| Host pair | VLAN | Subnet           |
|-----------|------|------------------|
| h1 ↔ h3   | 10   | 10.10.10.0/24    |
| h2 ↔ h4   | 20   | 10.20.20.0/24    |
| h5 ↔ h6   | 30   | 10.30.30.0/24    |

## Theory primer

### What "trunk allows all VLANs" actually means

`switchport mode trunk` with no further config = the trunk carries **every VLAN 1–4094** (or whatever the platform supports). Three problems:

1. **Blast radius.** Any new VLAN you create anywhere in the campus shows up on this trunk automatically. If sw1 accidentally has VLAN 99 with a misconfigured port, frames cross to sw2 even if you never intended them to.
2. **MAC table bloat.** Every switch learns MACs for every VLAN it sees on a trunk. Wide-open trunks = every switch learning everything = wasted hardware resources.
3. **Audit / least privilege.** You can't justify "this trunk needs VLAN 1234" if 1234 isn't actually used anywhere — but with allow-all you'd never notice.

The principle of least privilege says: **a trunk should allow exactly the VLANs that legitimately need to traverse it. Nothing more.**

### Native VLAN

On a trunk, frames belonging to the **native VLAN** are sent **untagged** on the wire. All other VLANs get an 802.1Q tag. The default native VLAN is **VLAN 1**.

Why this exists: legacy compatibility with non-VLAN-aware devices that drop tagged frames. Almost nobody needs this today.

Why VLAN 1 is a bad choice for it:
- VLAN 1 is the default for *everything* — any unconfigured access port often defaults to VLAN 1.
- Many Cisco L2 control-plane protocols (CDP, VTP, PAgP, DTP) historically default to VLAN 1. (LLDP frames are sent untagged regardless, so they're not native-VLAN-dependent.)
- An attacker on an access port in VLAN 1 sits in the same broadcast domain as the trunk's native VLAN by default.

### VLAN hopping (double-tag attack)

The classic attack:
1. Attacker is on an access port in VLAN 1 (the native VLAN).
2. They craft a frame with **two 802.1Q tags**: outer = VLAN 1 (native, will be stripped), inner = VLAN 20 (the victim VLAN).
3. The first switch strips the outer tag (because it's the native VLAN, untagged on egress). The frame, now carrying only the VLAN 20 tag, enters the trunk.
4. The next switch reads the VLAN 20 tag and forwards into VLAN 20.
5. Attacker just injected a frame into a VLAN they had no right to touch.

Defenses:
- **Don't use VLAN 1 as native.** Move it to an unused, unrouted VLAN ("parking" VLAN).
- **Force native VLAN to be tagged on the wire** — on Arista, `switchport trunk native vlan tag` per interface causes the port to drop all untagged frames; native traffic must arrive tagged with its VLAN ID. The "untagged frame on a trunk" ambiguity disappears, and the double-tag trick fails. (On Cisco IOS the equivalent is the global `vlan dot1q tag native`.)
- Don't put any access port in the native VLAN. Native VLAN should be an empty hole.

## Your task

Reconfigure both sw1 and sw2 trunks (Ethernet4) so that:

1. **Allowed VLANs are explicitly listed** — only VLAN 10, 20, 30. No "allow all".
2. **No untagged frames cross the trunk.** Force all frames to be tagged; native-VLAN ambiguity goes away.

Do *not* break the existing inter-tenant connectivity. After your changes:
- h1 ↔ h3 should still work
- h2 ↔ h4 should still work
- h5 ↔ h6 should still work

### Two valid hardening models (and why we pick one)

There are two production patterns for native-VLAN hygiene; on Arista they can't be combined:

| Pattern | Command | Behavior |
|---|---|---|
| **Parking-native** (Cisco-tradition) | `switchport trunk native vlan 999` (where 999 has no access ports) | Untagged frames mapped to VLAN 999. Safe only as long as no access port ever lands in VLAN 999. |
| **Drop-untagged** (Arista-modern) | `switchport trunk native vlan tag` | Untagged frames are dropped at the trunk. There is no native VLAN. |

The same `switchport trunk native vlan ...` command takes mutually-exclusive arguments (`<id>` or `tag`) — setting one overwrites the other. **Drop-untagged** is stronger (no "what's in VLAN 999?" question), so the solution uses that. The Cisco-style parking-VLAN pattern is shown here for cross-vendor awareness; on a pure-Arista network you don't need a parking VLAN.

## Hints

EOS commands you'll need:

```
configure terminal
  interface Ethernet4
    switchport trunk native vlan tag
    switchport trunk allowed vlan <comma-separated-list>
  exit
end
write memory
```

Apply identically on both switches. **The "drop untagged" setting must match on both ends** — otherwise one side will forward untagged frames the other side rejects.

## Deploy

```bash
cd ~/containerlab/labs/03-trunk-deep-dive
sudo containerlab deploy
```

## Verification

> **cEOS note (this one's real):** Unlike the hardware-only features some later labs cover (storm-control, HW QoS/policing, port-security — config-accepted but *not* enforced in cEOS), the primitives in this lab — `switchport trunk allowed vlan` and `switchport trunk native vlan tag` — are L2 trunk forwarding/tagging behaviors handled by the cEOS software forwarding agent. They **are** enforced in the container, so the verification below produces real, observable behavior. The `eth4` ↔ `Ethernet4` interface mapping in the step-5 capture is standard containerlab.

### 1. All three tenants work end-to-end

```bash
docker exec -it clab-trunk-deep-dive-h1 ping -c 3 10.10.10.3
docker exec -it clab-trunk-deep-dive-h2 ping -c 3 10.20.20.4
docker exec -it clab-trunk-deep-dive-h5 ping -c 3 10.30.30.6
```

All ✅. Connectivity unchanged from before — hygiene shouldn't break anything.

### 2. Verify allowed-list is restricted

```bash
docker exec -it clab-trunk-deep-dive-sw1 Cli
```

```
show interfaces Ethernet4 switchport
show interfaces trunk
```

You should see allowed VLANs explicitly listed (10,20,30), not "1-4094". `show interfaces trunk` is the operationally useful command — gives you a one-line summary of every trunk and what it carries.

### 3. Verify native-VLAN tagging is on

In the same Cli:

```
show interfaces Ethernet4 switchport | include Native
```

You should see `Administrative Native VLAN tagging: enabled`. With this on, untagged frames arriving on the trunk are dropped.

### 4. Asymmetric tagging — why both ends must agree (thought-experiment + config check)

On sw1 only, turn tagging back off, then re-check the administrative state:

```
interface Ethernet4
   no switchport trunk native vlan tag
end
show interfaces Ethernet4 switchport | include Native
```

Note that sw1 now reports `Administrative Native VLAN tagging: disabled` while sw2 still reports `enabled`. The two ends of the trunk are now configured asymmetrically.

**What you will (and won't) observe on this topology.** Re-run the three tenant pings from step 1 — they all still pass. That's expected, and it's the point worth internalizing: every tenant here rides a *tagged* VLAN (10, 20, 30), and VLAN 1 is not in the allowed-list, so there is no untagged data traffic on this trunk for the asymmetry to affect. You won't see broken pings or dropped frames, and `show logging` won't print anything specific.

So why does this asymmetry matter in production? Imagine a trunk where the **native VLAN carries real, untagged traffic** (a common legacy pattern — e.g. an unmanaged device or a server NIC that sends untagged frames into native VLAN 1, with VLAN 1 in the allowed-list). With sw1 set to "drop untagged off" it would map those untagged frames to native VLAN 1 and forward them tagged; sw2, still in drop-untagged mode, would silently discard them. From sw1's side everything looks normal — which is exactly the kind of bug that hides for months. The defensive takeaway: **both ends of a trunk must agree on the tagging mode**, and you verify that with the `show interfaces ... | include Native` command above on *both* switches, not by waiting for traffic to break.

Restore symmetry: `switchport trunk native vlan tag` on sw1.

### 5. See native-tagging on the wire

With `switchport trunk native vlan tag` enabled, capture on the trunk — every frame carries an 802.1Q tag:

```bash
sudo nsenter -t $(docker inspect -f '{{.State.Pid}}' clab-trunk-deep-dive-sw1) -n tcpdump -i eth4 -nn -e vlan
```

Now disable it temporarily:

```
no switchport trunk native vlan tag
```

Re-capture. Some control-plane frames (LLDP, etc.) may go untagged or end up in VLAN 1. Notice the difference. Re-enable: `switchport trunk native vlan tag`.

### 6. Operational reflex — `show interfaces trunk`

Get used to this command. In real ops you'll run it constantly:

```
show interfaces trunk
```

Output tells you in one screen: which ports are trunks, what VLANs they're allowed, what VLANs are *actually active* on each, and what native VLAN is in use. This is your single best L2 sanity check.

## Peek at solution

- [`solutions/sw1.cfg`](solutions/sw1.cfg)
- [`solutions/sw2.cfg`](solutions/sw2.cfg)

## Concepts cheat-sheet

- **Allowed VLAN list** — explicit comma-separated list of VLANs that may traverse a trunk. Default is all; production should be explicit.
- **Native VLAN** — the one VLAN on a trunk whose frames are *not* tagged on the wire. Default VLAN 1. Two options: move it to an unused parking VLAN (`switchport trunk native vlan <id>`), or eliminate the concept entirely by dropping all untagged frames (`switchport trunk native vlan tag`, Arista-modern).
- **`switchport trunk native vlan tag`** (Arista) — drops every untagged frame at the trunk. Closes the double-tag VLAN hopping attack and removes the "untagged frame on a trunk" ambiguity. On Cisco IOS the analogous global command is `vlan dot1q tag native`.
- **VLAN hopping** — attacker on an access port crafts a double-tagged frame; first switch strips outer (native) tag, second switch honors inner tag, frame ends up in a VLAN the attacker shouldn't reach. Defense: don't use VLAN 1 as native + tag everything.
- **`show interfaces trunk`** — your operational best friend for L2 sanity.

## What's missing (deliberately)

- **DTP / negotiation** — older platforms negotiate trunk mode automatically. Modern best practice: hard-code mode on both ends, disable negotiation. cEOS doesn't have DTP, so we skip it here, but on Cisco you'd add `switchport nonegotiate`.
- **VLAN pruning protocols** — VTP pruning, MVRP. Largely deprecated in favor of explicit allowed-lists.
- **STP impact** — we still have only one trunk, no loops yet. STP-related VLAN behavior comes in lab 04.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
