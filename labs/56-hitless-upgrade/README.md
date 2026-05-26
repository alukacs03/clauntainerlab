# Lab 56 — Hitless Upgrade / Rolling EOS Upgrade

> **Format:** Procedural / runbook. The lab provides an MLAG-style pair so you can rehearse the upgrade dance; the focus is the **steps and decision points**, not a config you push. Reference in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 9 · Tech lead · Year 5+. A new EOS version has a critical CVE fix. You need to upgrade 40 leaves and 4 spines without disrupting traffic. A bad upgrade is worse than the CVE. You write — and lead — the maintenance procedure that gets the fleet upgraded in two evenings with zero customer impact. See [`STORY.md`](../../STORY.md).

## Real-world scenario

"Just reload the switch with the new image" is fine for the kitchen network. For a production DC fabric, a reload during business hours = customer outage = SLA breach. Even at 02:00 maintenance windows, a *bad* reload can cause hours of cascading issues.

The hitless upgrade pattern depends on the redundancy you've already built:
- **MLAG pair**: upgrade one peer while the other carries all traffic. LACP failover < 1s.
- **EVPN multihoming (ESI)**: same idea — drain one ES member, upgrade, undrain, repeat.
- **Spine layer**: upgrade one spine at a time. ECMP-redistributed traffic loses 1/N of capacity briefly.
- **Edge**: drain via BGP AS-prepending or local-pref, upgrade, undrain.

This lab walks the MLAG upgrade dance specifically.

## Goal

- Understand the drain → upgrade → validate → undrain pattern
- Practice executing it (in the lab) without dropping pings from the host
- Recognize the gotchas: peer-link semantics, EVPN sync, BGP graceful restart

## Theory primer

### Drain methods

Move traffic *off* the device before reload. Common patterns:

| Layer | Drain method |
|---|---|
| BGP peer | AS-prepend outbound; raise local-pref on alternate paths |
| MLAG | Shut peer-link's keepalive momentarily? No — better: shut access ports on the draining peer (orphan LAGs go to the surviving peer via LACP failover) |
| EVPN-MH | `evpn ethernet-segment` → `mac-receive` only (stop being DF) |
| L3 ECMP path | Cost-out via routing protocol metric increase |
| Edge (transit) | Withdraw advertised routes via route-map |

After drain, the device should be carrying no traffic. Reload safely.

### Reload modes — "reload" vs "reload fast"

- **reload**: full reboot, full reinit. 90-180s outage on this device. With MLAG, traffic continues via peer.
- **reload fast**: Arista's optimized reload — kernel boots, ASIC keeps forwarding state for a few seconds, sessions reattach. Outage ~10s. Requires sufficient hardware support.
- **In-Service Software Upgrade (ISSU)**: zero-outage upgrade on hardware that supports it. Rare and finicky; some software upgrades don't qualify.

For lab leaves: `reload fast` is the right tool. For spines with massive route tables: same. For an MLAG peer-link reload that involves split-brain risk: just `reload` (with traffic on the other peer).

### Validation between each step

Before unblocking traffic on the upgraded device:
1. EOS version matches target
2. All expected interfaces up, in expected state
3. All LACP bundles formed
4. All BGP peers established
5. EVPN VTEP discovery complete (other leaves see us)
6. ACL counts match expected
7. No errors in startup logs

Automated, fast (< 30s). The on-call engineer doesn't manually scroll through `show ip bgp summary` at 02:30.

### Common gotchas

- **MLAG peer-link MTU mismatch after upgrade** → peer-link flaps → split brain → bad. Verify MTU before reload.
- **EVPN learned MACs missing on upgraded leaf** → MAC moves not seen → some hosts unreachable → wait for EVPN reconvergence (~30s) before declaring upgrade done.
- **Software changes default values** (rare but real). Read release notes. A specific case: STP defaults changed between EOS major versions for some platforms.
- **License re-check on reload**: some feature licenses might re-evaluate at boot. If your license file moved, certain features go offline.

## Runbook — MLAG-pair leaf upgrade

```
== Hitless Leaf Upgrade (MLAG Pair: leaf1 + leaf2) ==

PRE:
1. Both leaves currently active, traffic balanced
2. Upgrade image staged on both leaves (file transferred, verified)
3. Maintenance window communicated; status page updated
4. Backup configs taken (lab 55)
5. Snapshot of pre-state: `show mlag`, `show bgp summary`, `show evpn`,
   counters per interface

STEP A — UPGRADE leaf1:
  A1. Drain leaf1: shut all access ports on leaf1
     (traffic shifts to leaf2 via LACP failover; verify with host ping)
  A2. Verify zero traffic on leaf1's access ports (counters flat for 30s)
  A3. Save config: `copy running-config startup-config`
  A4. Reload with new image:
      `boot system flash:EOS-NEW.swi`
      `reload`
  A5. Wait for boot (~3 min)
  A6. SSH back in, run validation script
  A7. If validation PASSES: undrain (no shut access ports)
      verify traffic returns to balanced state
  A8. If validation FAILS: rollback (boot prior image, reload, investigate)

STEP B — UPGRADE leaf2 (same procedure as STEP A):
  Mirror of A. After this both peers run new EOS.

POST:
  - 24-hour soak: monitor for errors, anomalies
  - Update NetBox: device software version field
  - Postmortem if anything unexpected happened (even non-disruptive)
```

## Your task

1. Read the runbook.
2. From the lab host, start a ping flood to the gateway: `ping -i 0.1 10.10.10.1`
3. Execute the drain step on `leaf1` (shut access port Eth3).
4. Observe: pings continue (failover to leaf2 + the host's eth2).
5. "Reload" leaf1 (in lab, just reboot the container or `containerlab restart`).
6. Validate, undrain.
7. Repeat for leaf2.

Total ping loss during a well-executed upgrade: 0-2 packets per peer transition.

## What's missing (deliberately)

- **Real MLAG protocol config** (`mlag configuration` stanza) — focus is on procedure, not MLAG specifics (covered in lab 14)
- **Real ISSU walkthrough** — hardware-specific, requires real gear
- **EVPN-MH pair upgrade** — same pattern; configuration covered in lab 33b
- **Cluster reload of spines** — different runbook; spines drain via BGP cost, not by shutting ports

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
