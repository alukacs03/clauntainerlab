# Lab 55 — Network Device Backup & Disaster Recovery

> **Format:** Hands-on + procedural. Build automated config backup; walk the full "switch died, replace it" procedure. Reference scripts in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 9 · Tech lead · Year 5+. A leaf switch died at 02:00. The replacement arrived at 09:00. The question every new tech asks: "now what?" You write the runbook that turns "panic, hope someone remembers the config" into "follow these 12 steps, you're back in 25 minutes." See [`STORY.md`](../../STORY.md).

## Real-world scenario

A switch dies. Could be a PSU, could be the fabric ASIC, could be cosmic rays. Doesn't matter — you have to get the replacement running with the right config in minimal time.

Without preparation:
- Hunt for last-known config in the wiki (does anyone know which version is current?)
- Manually paste it into the new switch
- Hope you have all the customer cross-connects documented
- Realize the new switch has a different MAC, so DHCP snooping bindings need updating
- 4 hours later, you're done. Customers were down.

With preparation:
1. Automated daily backups → known-good config in git
2. NetBox tells you which interfaces should be cabled where, which IPs go on which port
3. ZTP (Zero Touch Provisioning) deploys the config based on the switch's serial number
4. Validation tests run before traffic flows
5. 25 minutes from "switch installed" to "service restored"

This lab builds the backup half. Lab 54 (NetBox) is the source-of-truth half. Together they make recovery boring.

## Goal

- Automated daily backup of every device's running config to git
- Diff alerts on unexpected changes (drift detection)
- ZTP procedure documented
- Validated recovery playbook

## Theory primer

### Backup strategy

| Layer | What to back up | Frequency | Storage |
|---|---|---|---|
| Running config | `show running-config` output | Daily + on commit | Git (with offsite mirror) |
| Startup config | `show startup-config` | Daily | Git |
| Device facts | Serial, model, software version | Weekly | NetBox / CMDB |
| EOS images | The actual NOS binary | Per-version, manual | File server |
| Licenses | License file | At install + yearly | Vault/safe storage |
| EVPN / BGP state | (optional) for forensic post-DR | Pre-incident only | Telemetry archive |

### What "DR" means for a network device

Unlike servers, network device DR is *mostly* config + image:
- Hardware is replaceable (RMA, hot spare)
- State you actually need is small: config + interface mappings + cabling + tenant data
- ZTP makes the config-push step automated

The pieces that are hard to recover:
- Customer/tenant cross-connects (which port goes to whom) → NetBox
- Per-device unique identifiers (license, certificates) → vault
- Live BGP/EVPN learned state — comes back when the device rejoins the fabric

### ZTP (Zero Touch Provisioning) — Arista flavor

When an Arista switch boots without a startup config:
1. It DHCPs on all interfaces
2. The DHCP response includes a "bootfile" URL (TFTP/HTTP)
3. The switch downloads a config (or a small script that generates config based on its serial)
4. Boots into that config

To make this work:
- DHCP server returns a config-URL keyed off MAC or DHCP client ID
- Backup server hosts per-serial configs (or templates the config from NetBox at request time)
- Pre-stage the configs for any devices you might need to replace

### Drift detection

A daily diff between the in-repo backup and a fresh `show running-config` reveals:
- Authorized hand-edits not yet pushed back to git
- Unauthorized changes (someone bypassed the pipeline)
- Configs that "rolled back" themselves (rare, but happens with bad upgrades)

Alert on any non-trivial diff. Either the human-edit gets committed to git, or the device gets re-applied from git.

### What to test after recovery

Before announcing the device "back":
1. Interface counts match expected
2. BGP peers all Established
3. EVPN VTEP discovered by other leaves
4. ACLs in place (count match)
5. End-to-end ping for sample tenants
6. No errors in last 1 hour of logs (post-boot)

Automate. The on-call engineer doesn't remember the checklist at 03:00.

## Your task

1. Read `solutions/backup-configs.sh`. Understand each step.
2. Set up a cron job (on the backup server in the lab) to run it daily.
3. Modify the switch config; rerun backup; observe the git commit.
4. Sketch your own recovery runbook. Reference the runbook template in `docs/practice/templates/`.

## Recovery procedure (the runbook)

```
== Switch Replacement Procedure ==

PRE-WORK (during incident triage):
1. Confirm device is genuinely dead (out-of-band ping, console, peer's LLDP)
2. Identify spare in inventory
3. Pull last config from git: backup-server:/backups/configs/<device>.cfg
4. Pull cabling map from NetBox: which interfaces go where
5. Pull tenant list affected for status updates

PHYSICAL:
6. Pull old switch from rack
7. Install spare; connect to:
   - OOB mgmt
   - Console
   - Power
   - Data links AS NETBOX SPECIFIES (don't guess)

CONFIG LOAD:
8. ZTP: spare boots, fetches config from backup-server (auto)
   OR manual: copy <device>.cfg via OOB to startup-config, reload
9. Verify hostname, primary IP, SSH access from mgmt network

VALIDATION (before re-cabling data interfaces if hot-stage was used):
10. Run pytest /lab/post-recovery-tests.py --device=<name>
   - Interface up counts
   - BGP peers all Established
   - EVPN VTEPs discovered
   - ACLs counted
11. Sample tenant ping

ANNOUNCE:
12. Status update: "service restored"
13. Schedule postmortem within 48h
```

## What's missing (deliberately)

- **Live ZTP server** (DHCP + HTTP + per-serial config generator)
- **Hot-spare warm config testing** — staging without traffic
- **Certificate/identity recovery** — TPM, RadSec creds, etc.
- **Multi-device cascade** (what if 3 leaves die at once? capacity planning)

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
