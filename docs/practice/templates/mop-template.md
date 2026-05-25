# MOP — Method of Procedure

> Copy this file, fill in every section, get a peer review, then execute.
> See [`../migration-planning.md`](../migration-planning.md) for guidance.

---

## Identity

- **Title**: `[short description, e.g., "Migrate sw1-sw2 trunk from VLAN 10 to VLAN 20"]`
- **Change ticket**: `[ticket ID or N/A]`
- **Author**: `[your name]`
- **Reviewers**: `[at least one peer name]`
- **Scheduled window**: `[YYYY-MM-DD HH:MM – HH:MM TZ]`
- **Expected duration**: `[N minutes]`
- **Change category**: `[ Trivial / Standard / Major ]`

## Goal

`[One sentence in business-readable language. "Move VLAN 20 customer traffic onto the new uplink so we can decommission the old one next week."]`

## Scope

**Devices affected**: `[list]`

**Interfaces affected**: `[list]`

**Services affected**: `[customer-facing or internal services that may be touched]`

**Services explicitly NOT affected**: `[anything ruled out — useful when scoping comms]`

## Risk assessment

- **Blast radius**: `[what's at stake if this goes wrong — which customers, which services]`
- **Worst-case impact**: `[honestly — duration of likely worst-case outage]`
- **Reversibility**: `[can we roll back? In how long?]`
- **Concurrent changes**: `[any other changes scheduled in the window — there should not be]`

## Pre-checks

Run BEFORE starting the change. All must pass.

| # | Check | Command | Expected | Result (filled in at execution) |
|---|---|---|---|---|
| 1 | `[example: BGP session to upstream-1 is Established]` | `show ip bgp summary \| include upstream-1` | State = a time | |
| 2 | | | | |
| 3 | | | | |

## Change steps

Numbered, exact commands, expected outcome per step.

| # | Action | Command(s) | Expected output | Actual (at execution) |
|---|---|---|---|---|
| 1 | `[example: enter config mode on sw1]` | `configure terminal` | `(config)#` prompt | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |

## Validation

How do we know the change worked? Run these AFTER all change steps.

| # | Validation | Command | Expected | Result |
|---|---|---|---|---|
| 1 | `[example: traffic flowing on new uplink]` | `show interfaces Port-Channel2 counters rates` | non-zero packets/sec | |
| 2 | | | | |

## Rollback

If validation fails, OR if any change step produces unexpected output:

| # | Action | Command(s) | Expected outcome |
|---|---|---|---|
| R1 | `[example: undo step 4]` | `[exact command]` | `[expected state]` |
| R2 | | | |
| R3 | | | |

**Rollback validation**: `[how do you know rollback worked — specific commands and expected outputs]`

## Communications

| When | Audience | Channel | Message template |
|---|---|---|---|
| T-24h | `[NOC, customer success]` | Email | "Maintenance window scheduled..." |
| T-1h | `[on-call team]` | Slack #netops | "Starting maintenance in 1h..." |
| T-0 | `[status page]` | Status page | "Investigating: scheduled maintenance in progress" |
| T+done | `[status page, internal]` | Status page + Slack | "Resolved: maintenance complete" |

## Sign-off

- **Author**: `[your name + date]`
- **Peer reviewer(s)**: `[name(s) + date(s) + 👍 or notes]`
- **CAB / management approval** (if applicable): `[name + date]`

---

## During execution

- Record start time: `_____`
- Record end time: `_____`
- Any deviations from plan: `[note here]`
- Any issues encountered: `[note here]`

## Post-change

- [ ] Validation steps all passed
- [ ] Communications closed (status page back to green, stakeholders notified)
- [ ] Configs backed up
- [ ] Plan archived with actual-time annotations
- [ ] If anything was unexpected: lessons noted in `[location]`
