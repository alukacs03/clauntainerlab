# Runbook: `[Symptom or alert name]`

> See [`../runbooks.md`](../runbooks.md) for guidance.
> Runbooks are **living documents**. Update after each use.

---

## Triggers

This runbook applies when ANY of these occur:

- `[Alert name in PagerDuty / monitoring]`
- `[Customer-reported symptom]`
- `[Manual: command output X showing Y]`

## Severity / response time

- **Default severity**: `[Sev1 / Sev2 / Sev3]`
- **Expected response time**: `[N minutes]`
- **Expected MTTR**: `[N minutes for typical case]`

## Prerequisites

You need:

- `[Access: e.g., SSH to edge1/edge2 via OOB jumphost]`
- `[Knowledge: e.g., understanding of BGP at lab-26 level]`
- `[Tools: e.g., TACACS account with privilege 15]`
- `[On-hand info: e.g., upstream NOC phone number from vendor contacts page]`

## Quick check (is this really the right runbook?)

Sometimes the alert misfires or the symptom matches multiple runbooks. Quick sanity:

1. `[A 1-line command to confirm this runbook applies]`
2. `[Expected output that confirms applicability]`

If the quick check doesn't match: this isn't the right runbook. See [`runbook index`].

## Steps

### Step 1: `[concise action description]`

```
[exact command]
```

**Expected**: `[what the output should show]`

**If different**: `[what to do — branch number, escalate, etc.]`

---

### Step 2: `[concise action description]`

```
[exact command]
```

**Expected**: `[what the output should show]`

**If different**: `[what to do]`

---

### Step 3: `[concise action description]`

```
[exact command]
```

**Expected**: `[what the output should show]`

**If different**: `[what to do]`

---

`[Add as many steps as needed. Each step has: action, command, expected, branch on divergence.]`

## Branches

### Branch A: `[scenario description, e.g., "TCP not connecting"]`

`[Steps specific to this branch]`

### Branch B: `[scenario description]`

`[Steps specific to this branch]`

## Resolution check

How do you confirm the incident is actually fixed?

| # | Check | Command | Expected |
|---|---|---|---|
| 1 | `[symptom is gone]` | `[command]` | `[expected output]` |
| 2 | `[downstream service confirms]` | `[command or check]` | `[expected]` |

Once both pass: close the incident.

## Escalation

If the steps above don't resolve within `[N minutes]` OR the symptoms diverge from anything documented here:

- **Page**: `[on-call person / team]` via `[channel]`
- **What to tell them**: which steps you've tried, what you saw, the time you started.
- **Vendor escalation** (if applicable): `[contact + how to open TAC case]`

## Post-incident

After the runbook is used:

- [ ] Note any deviation from documented steps in the incident channel.
- [ ] If the runbook needed adjustment, update it now (don't wait).
- [ ] If this was a new failure mode, schedule a postmortem (use [`postmortem-template.md`](postmortem-template.md)).
- [ ] If the alert was noisy / unnecessary, tune the threshold.

## Related

- `[Links to related runbooks]`
- `[Links to relevant ADRs]`
- `[Links to monitoring dashboards]`
- `[Last review date / reviewer]`
