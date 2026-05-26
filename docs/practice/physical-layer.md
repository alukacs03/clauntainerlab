# The Physical Layer — Optics, Cables, MTU, and Why "It's Always DNS" Is Actually "It's Often L1"

> Network engineers who can't debug L1 stall their careers. The dirty fiber, the wrong-optic combination, the MTU-mismatch-that-only-bites-large-packets — these are the bugs that look like "the network is broken" but are actually physics being honest with you. This is what to know.

## Why this matters

The classic outage timeline:
- 02:00 — alert: BGP session down.
- 02:05 — engineer SSHs in. Interface "up". Counters incrementing. Looks fine.
- 02:30 — they've checked BGP config, neighbor config, routing policy. All correct.
- 03:15 — they wake up a senior. "Is the link clean? Did anyone touch the patch panel?"
- 04:00 — they find a dirty fiber connector. Two-minute cleaning, problem solved.

Two hours of debugging at the wrong layer. The senior knew to ask about L1 immediately because they've been burned. This document is to spare you those two hours.

## The optic landscape

Modern network gear is modular. The switch has cages; you plug **optical transceivers (optics)** or **direct-attach copper (DAC) cables** into them. Picking the wrong one is a common, expensive mistake.

### Optic form factors (cages)

You'll mostly see these on modern gear:

| Cage | Bandwidth | Use |
|---|---|---|
| **SFP** | 1G | Legacy / management. Still found on access switches. |
| **SFP+** | 10G | The 10G workhorse for most of the 2010s. |
| **SFP28** | 25G | 25G server-facing on modern leaves. SFP+ optics fit but run at 10G. |
| **QSFP+** | 40G (4×10G) | Older 40G cage. |
| **QSFP28** | 100G (4×25G) | 100G workhorse. Breakout-capable to 4×25G. |
| **QSFP-DD** | 400G (8×50G) | High-density 400G; backward-compat with QSFP28. |
| **OSFP** | 400G/800G | The other 400G+ form factor; not compatible with QSFP. |

The cage is the *physical socket*. The optic is what plugs in. They must match.

### Common optic types (the names you'll see)

Single-mode fiber (SMF):

| Optic | Distance | Wavelength | Use |
|---|---|---|---|
| **LR (Long Reach)** | up to 10 km | 1310 nm | Standard SMF for intra-DC and short inter-DC. |
| **ER (Extended Reach)** | up to 40 km | 1550 nm | Longer SMF runs. |
| **ZR / ZR+** | 80–120 km | 1550 nm | DCI distances. Has built-in coherent optics. |

Multi-mode fiber (MMF):

| Optic | Distance | Wavelength | Use |
|---|---|---|---|
| **SR (Short Reach)** | 100 m (OM3) to 300 m (OM4) | 850 nm | Intra-rack and short inter-rack. Standard for server cabling. |
| **SR4** | similar | 4 lanes × 25G | 100G over MMF. Less common than 100G-LR in DCs. |

Direct-attach (no optics, just a cable):

| Cable | Distance | Use |
|---|---|---|
| **DAC (Direct Attach Copper)** | 1m, 3m, 5m, sometimes 7m | Intra-rack switch-to-switch and switch-to-server. Cheap, low power. |
| **AOC (Active Optical Cable)** | up to 30m | Inter-rack where DAC won't reach. Pre-terminated; can't change connectors. |

**Key gotcha**: SR optics work only over MMF (orange/aqua cable). LR optics need SMF (yellow cable). Plug an LR optic onto MMF and the link won't come up — or comes up but errors furiously.

### Common mismatch traps

These bite people regularly:

- **Mode mismatch**: SR optic on SMF, or LR optic on MMF. Either no link or extreme error rate.
- **Wavelength mismatch in CWDM/DWDM**: each end must use the same wavelength. Different colors = no link.
- **Speed mismatch**: SFP+ optic in an SFP28 cage works at 10G, not 25G. SFP28 optic in an SFP+ cage might not work at all.
- **Breakout mismatch**: 100G QSFP28 broken out as 4×25G into 25G ports — the breakout cable must match (1×100G→4×25G splitter, not 1×100G→4×10G).
- **Coding-incompatible 100G**: 100GBASE-LR4 vs 100GBASE-LR (single-lambda). Look similar; not interoperable.
- **Polarity issues on MPO**: 12-fiber MPO ribbons have polarity (Type A/B/C). Wrong polarity = no link or no light on one direction.

### How to debug an optic

Modern optics support **DDM (Digital Diagnostic Monitoring)** or DOM. The switch tells you the optic's reported temperature, voltage, transmit (TX) power, receive (RX) power, and laser bias current.

```
show interfaces Ethernet1 transceiver
```

Read what you get:

- **TX power**: should be in range for the optic spec (e.g., -8 to +0.5 dBm for 10G-LR).
- **RX power**: should also be in spec range. If too low, the link is dirty or too long. If too high (rare), the link is too short and the receiver is saturating — add an attenuator.
- **Temperature**: if high (>70°C), check cooling.
- **TX bias**: if it's climbing, the laser is degrading; replace the optic.

**Rule of thumb**: if RX power is more than 3 dB below the expected range, suspect dirty connectors or a damaged fiber.

### Cleaning fiber connectors

This is a real skill that's strangely undervalued. Dirty fiber is a top-three cause of "weird intermittent network issues" in production.

Tools:
- **One-click cleaner** (Cletop or equivalent): the standard tool. Insert connector, click, click, done.
- **Fiber inspection scope**: optical scope that shows you the end-face. Catches contamination before you plug it in.

Protocol: **always inspect, then clean if needed, then re-inspect before connecting**. A dirty connector on one side contaminates the other side when you connect them — now you have two dirty connectors. Inspect both sides of every fiber junction before mating.

If you've never cleaned a fiber connector, watch a 10-minute YouTube video. The skill compounds across your career.

## Cabling fundamentals

### Single-mode vs multi-mode

- **Single-mode (SMF, OS2)**: yellow jacket usually. Smaller core (9 µm). Lasers (not LEDs) drive it. Used for long distances and high speeds (100G+ LR/ER). Modern DC standard.
- **Multi-mode (MMF, OM3/OM4/OM5)**: aqua/orange/lime. Larger core (50 µm). Cheaper optics, shorter distances. Common for intra-rack 10G and 100G-SR4.

**Mixing is bad**: a single fiber path with one segment of SMF and one segment of MMF is broken. The core diameters don't match; light scatters.

### Fiber types and grades

OM3, OM4, OM5 are MMF grades — higher numbers handle higher speeds over longer distances:

- OM3: 10G to 300m, 100G-SR4 to 70m.
- OM4: 10G to 400m, 100G-SR4 to 100m, 25G to 100m.
- OM5: wider wavelength range, used for wavelength-division on MMF.

Most new DC pulls in OM4 unless there's a specific reason to differ.

### Connectors

- **LC**: small duplex connector, standard for SFP/SFP+/SFP28. Two LC tips = TX and RX.
- **MPO/MTP**: ribbon connector with 8, 12, 16, or 24 fibers. Used for QSFP-SR4 (8 of 12), parallel optics, structured cabling backbones.
- **SC**: older, larger duplex connector. Found in legacy installations.

### Patch panels and structured cabling

A well-cabled DC has **patch panels** — passive blocks where cables terminate. Switches connect to patch panels via short patch cords; long fiber runs go between patch panels (and only between patch panels).

Why: when a long fiber needs replacing, you don't unplug a switch port. You replace a patch cord at the panel.

If you ever pull a cable directly from one switch to another rack — without a patch panel — your future self will hate you. Always patch.

## MTU planning

Maximum Transmission Unit (MTU): the largest packet/frame size a link can carry without fragmentation.

### The default Ethernet MTU is 1500 bytes

But it's actually more nuanced:

- **1500**: the standard payload size for Ethernet. Almost every host defaults to this.
- **1522**: with VLAN tag (+4 bytes for 802.1Q).
- **9000 (Jumbo)**: larger frames, used in DCs for performance and to make room for encapsulation overhead.
- **Vendor-specific**: 9216 (Cisco common), 9214 (Arista common). 9000 is the safe interop value.

### Why jumbo matters in a modern DC

VXLAN encapsulation (lab 29) adds ~50 bytes to the original frame:
- Outer Ethernet (14) + outer IP (20) + outer UDP (8) + VXLAN header (8) = 50 bytes overhead.

If the host sends a 1500-byte frame and the underlay is also 1500, then VXLAN-encapsulated, the encap packet is 1550 — bigger than the underlay MTU. Result: fragmentation, drops, or PMTU games. All bad.

**Fix**: set the underlay MTU to jumbo (9000+) so the VXLAN-encapped 1550-byte packet fits comfortably. The inner host MTU stays 1500. Encapsulation overhead is absorbed.

### How MTU mismatches bite

Classic failure modes:

- **Asymmetric MTU on a link**: one end set to 1500, other end to 9000. Frames up to 1500 work in both directions; larger frames fail in one direction. Some apps notice, some don't. *Insidious*.
- **End-to-end path with one low-MTU hop**: a transit somewhere has MTU 1492 (PPPoE etc.); large packets get fragmented or dropped. SSH works (small packets); large file transfers stall.
- **VXLAN encap MTU not accounted for**: as above; inner frames near 1500 get dropped after encap.
- **MPLS adds 4 bytes per label**: a path with 2 MPLS labels adds 8 bytes; need to size MTU for the labels.

### How to test for MTU issues

```bash
# Linux host: ping with DF (don't fragment) and increasing size
ping -M do -s 1472 <dest>     # 1472 + 28 (ICMP+IP headers) = 1500 byte packet
ping -M do -s 8972 <dest>     # 9000 byte packet
```

If small pings work but large pings fail, you have an MTU issue somewhere on the path.

Tracing the exact hop where it fails:

```bash
mtr --no-dns -s 1472 <dest>   # mtr with size; the failing hop is your culprit
```

Or fancier: PMTUD (Path MTU Discovery) inspection if you have access to intermediate devices.

### Operational MTU rule

- **Underlay MTU**: 9214 or higher (provides headroom for VXLAN + future encapsulations).
- **Host MTU**: 1500 unless app specifically wants larger.
- **MTU on every interface in a fabric must be consistent** within the underlay. Mixed MTU is a hidden time bomb.
- **Don't change MTU lightly**: it triggers a brief outage on the interface as the kernel re-IPs the queue.

## L1 debug workflow

When something is broken and you don't know where to start, run this in order:

1. **`show interfaces` — is the port "up"?**
   - If "up": L1 is at least sort of working.
   - If "down": physical issue (cable, optic, port).
   - If "errdisabled": the switch turned it off for cause; see lab 06.

2. **`show interfaces ... counters errors`** (or `counters` and look for non-zero error counts).
   - **CRC errors**: dirty fiber, wrong optic, electrical interference, bad cable.
   - **Input errors / runts / giants**: MTU mismatch, frame errors.
   - **Output drops**: queue saturation; not L1, but useful.
   - Watch *delta over time*, not absolute (some errors accumulate from old events).

3. **`show interfaces ... transceiver`** — read RX/TX power, temperature.
   - Out of spec: clean fiber, replace optic, check connector.

4. **`show interfaces ... status`** — speed, duplex.
   - Speed mismatch: optic and cage incompatible, or breakout misconfigured.

5. **`show lldp neighbors` / `show cdp neighbors`** — is the neighbor what you expect?
   - Wrong neighbor: someone re-patched the cable somewhere.

6. **Visual inspection**: walk to the rack. Does the SFP have a light? Is the cable properly seated? Is it the right cable for the optic?

This sequence catches 80%+ of L1 issues in <10 minutes.

## Common L1 horror stories

### "The link is up but traffic is corrupting"

CRC errors climbing. Looked at config — no smoking gun. Replaced the optic on side A — still happening. Replaced the patch cable — still happening. Replaced the optic on side B — fixed.

Lesson: optics can be partially faulty. The "side B receives, but transmits corruption" failure is a real thing.

### "It works at 1G but not 10G"

Two switches connected by what was sold as "category 6A copper" — but actually a too-long run with too many patch panel insertions. 1G works because gigabit is forgiving. 10G needs cleaner signal.

Lesson: long copper runs at high speed are stress tests on the cable. Fiber from ~30m and up.

### "It works in the morning but breaks every afternoon"

A bundle of fibers ran across a window. Direct sunlight heated the fibers; signal degraded as the day warmed up. Re-routed away from the window; problem solved.

Lesson: temperature affects optical performance. Fibers under raised floors in unfilled DC space are not safe from environmental variation.

### "All four 100G ports work except port 17"

Pulled the optic from port 17, swapped with port 18. Problem stayed on port 17. So the cage itself was bad. Hardware RMA.

Lesson: cages fail. Don't assume the optic is bad; swap-test.

### "We replaced a switch and now MTU 9000 broke"

The replacement switch's QSFP cages were physically different (newer revision); the same optic worked at 1500-byte MTU but glitched on 9000-byte frames because of a marginal seating issue. Reseating fixed it.

Lesson: not all "physically compatible" optics are perfectly compatible. Reseating is free; try it.

## Buying optics — vendor vs third-party

Vendors charge a *lot* for their branded optics. Third-party optics ("compatible") are dramatically cheaper and usually work identically.

The trade-off:

- **Vendor optics**: 3-10× the price. Guaranteed compatible. Vendor support if it breaks. May be required by warranty/SLA on some hardware.
- **Third-party optics**: 1/10 the price. Usually work identically. Some platforms refuse to operate them unless you enable "unsupported optic" mode. Vendor support may be limited.

Production reality: many DCs run third-party optics in non-critical paths and vendor optics where SLA matters. The "all-vendor optics" purist approach is usually overkill outside hyperscale or regulated environments.

---

**Story-arc references**:
- Phase 4-6: as The Company's fabric grows, optic and cabling decisions stop being trivial. You start spec'ing cabling plans for new pods, picking optic types, and signing off on procurement.
- Phase 6+ (EVPN fabric): MTU planning becomes a per-pod design parameter. Every spine-leaf link must support jumbo. Every customer-edge port stays at 1500.
- L1 debug skills: useful from day one. The 3 AM outage where "the link is up but traffic isn't flowing" — you check transceiver telemetry instead of staring at routing configs.

## TL;DR

- **Match optics to fiber type**: SR with MMF, LR with SMF. Don't mix.
- **Match optic to cage**: SFP+ ≠ SFP28 ≠ QSFP28.
- **Inspect and clean fiber connectors**: dirty fiber is a top-three cause of "weird network issues".
- **MTU consistency**: every interface in the underlay needs the same MTU. Jumbo (9214+) for VXLAN fabrics.
- **L1 debug workflow**: errors → transceiver telemetry → visual → swap-test.
- **`show interfaces transceiver`**: your friend.
