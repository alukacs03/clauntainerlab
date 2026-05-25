# Postmortem: `[short incident name]`

> Blameless postmortem. Focus on systemic factors, not individuals.
> See [`../incident-response.md`](../incident-response.md) for guidance.

---

## Header

- **Incident ID**: `[INC-YYYY-NNN]`
- **Date / time of incident**: `[YYYY-MM-DD HH:MM TZ start – HH:MM TZ end]`
- **Severity**: `[Sev1 / Sev2 / Sev3]`
- **Duration of impact**: `[NN minutes]`
- **Incident Commander**: `[name]`
- **Scribe**: `[name]`
- **Postmortem author**: `[name]`
- **Postmortem date**: `[YYYY-MM-DD]`
- **Status**: `[Draft / Reviewed / Action items in progress / Closed]`

## Summary

`[2-3 sentences. Plain English. What broke, who was affected, how long, how it was resolved. The TL;DR.]`

## Impact

- **Customers affected**: `[number or %, optional names]`
- **Services degraded**: `[list]`
- **Revenue impact** (if known): `[$/€/currency]`
- **SLA breach** (if applicable): `[which SLA, by how much]`
- **External-facing communications**: `[status page updates, customer emails, etc.]`

## Timeline

All times in [TZ]. Be precise — pull from chat logs, monitoring, the scribe's notes.

| Time | Event |
|---|---|
| `HH:MM` | `[detection: alert fired / customer reported]` |
| `HH:MM` | `[on-call paged]` |
| `HH:MM` | `[incident declared at Sev N, IC = X]` |
| `HH:MM` | `[first status update sent]` |
| `HH:MM` | `[hypothesis 1 tested: X — result: Y]` |
| `HH:MM` | `[hypothesis 2 tested: X — result: Y]` |
| `HH:MM` | `[root cause identified]` |
| `HH:MM` | `[mitigation applied]` |
| `HH:MM` | `[service restored — validated by Z]` |
| `HH:MM` | `[incident closed; all-clear sent]` |

## Detection

- **How did we find out?**: `[monitoring alert, customer report, internal observation]`
- **Time to detect**: `[from "first impact" to "we knew about it"]`
- **Could we have detected sooner?**: `[honest answer]`
- **If yes, what monitoring is missing?**: `[action items below]`

## Response

What went well in the response:
- `[concrete examples]`

What was difficult:
- `[concrete examples — not blame, just observations]`

## Root cause

`[The story of what actually happened. Not just the immediate trigger ("Alice typed X") but the system of factors that allowed it.]`

**Contributing factors**:
- `[Factor 1: e.g., the change was made outside a maintenance window]`
- `[Factor 2: e.g., the change had no rollback plan]`
- `[Factor 3: e.g., monitoring did not alert on this failure mode]`
- `[etc.]`

**Five Whys** (optional but often useful):
1. Why did service go down? → `[because X]`
2. Why did X happen? → `[because Y]`
3. Why did Y happen? → `[because Z]`
4. Why did Z happen? → `[...]`
5. Why? → `[the actionable root]`

## Action items

Concrete, owned, dated. "Improve monitoring" is NOT an action item.

| # | Action | Owner | Due | Status |
|---|---|---|---|---|
| 1 | `[Add alert on BGP session down for upstream-1 in PagerDuty]` | `[name]` | `[date]` | `[Open / In Progress / Done]` |
| 2 | `[Update MOP template to require rollback validation]` | `[name]` | `[date]` | |
| 3 | `[Write runbook for BGP session black-hole at upstream]` | `[name]` | `[date]` | |

## What went well

(Don't skip this section. Reinforces good behaviors.)

- `[example: IC was declared within 5 minutes of detection]`
- `[example: status update cadence was followed]`
- `[example: rollback procedure existed and worked]`

## Lessons

Forward-looking takeaways for the team:

- `[e.g., "We need to test rollback procedures, not just write them"]`
- `[e.g., "Silent link failures are now a known failure mode — runbook X covers it"]`

## References

- Slack incident channel: `[link]`
- Monitoring graphs at the time: `[link]`
- Related ADRs (if any): `[link]`
- Related runbooks (created or modified): `[link]`
- Customer comms sent: `[link]`
