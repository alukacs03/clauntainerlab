# Runbooks

> At 3 AM, the on-call engineer should be able to follow a step-by-step procedure to recovery. Not "here's how I would debug this" — but "click this, paste this, expect this output, if not goto step X." That's a runbook.

## What a runbook is

A **runbook** is a procedure document for a specific operational situation. It:

- Has a clear trigger (an alert, a symptom, a customer report).
- Lists concrete steps in order.
- States expected outputs/results at each step.
- Branches when behavior diverges from expected.
- Ends with either "resolved", "escalated to X", or "still investigating, here's what we tried".

It is **not** a tutorial. It is not an explanation of how a system works. It assumes the reader is competent but stressed, tired, or unfamiliar with this particular incident type.

## What a good runbook looks like

Structure:

### 1. Title and triggers
What alert/symptom does this runbook apply to? Specifically:
```
Triggers:
- PagerDuty alert "BGP session down to upstream-1"
- Customer report "internet down"
- Manual: show ip bgp summary shows upstream-1 in Idle/Active for >5 min
```

### 2. Severity / response time
What sev is this? How fast should the on-call respond?

### 3. Prerequisites
What access, tools, or context does the responder need? E.g., "SSH access to edge1/edge2", "BGP knowledge at lab-26 level", "TACACS account with privilege 15".

### 4. Steps
Numbered. Each step has:
- The action (a command, a check, a decision).
- Expected output / state.
- What to do if behavior diverges.

Example:
```
1. SSH to edge1: `ssh admin@10.0.0.1`. 
   Expected: prompt within 5s. 
   If not: try edge2 (10.0.0.2). If neither: jump to "escalation" below.

2. Check BGP session status: `show ip bgp summary | include upstream`.
   Expected: One line per upstream, state should be a time (Established).
   If state is Idle/Active/OpenSent: continue to step 3.
   If state is Established: this runbook does not apply, re-check alert source.
```

### 5. Branches / decision tree
If the runbook has multiple paths, label them clearly:
```
If step 3 shows TCP not connecting → Branch A (network-layer issue)
If step 3 shows BGP not negotiating → Branch B (BGP-layer issue, possible config drift)
```

### 6. Resolution check
How do you confirm the incident is fixed? Specific commands and outputs.

### 7. Escalation path
If the runbook doesn't resolve it: who do you wake up, what do you tell them.

### 8. Post-incident
- Did this work? Add notes to the runbook for next time.
- Was the alert noisy? Maybe tune the threshold.
- Recurring? Postmortem time.

## Prose vs procedure — the most common runbook mistake

Bad runbook (prose):
```
If BGP is down, you should investigate the session. Usually it's a TCP issue,
sometimes a config issue. Check the logs and the neighbor state. If it's a
network issue, you might need to check upstream.
```

That's not a runbook — that's vague advice. At 3 AM, the on-call needs to type commands, not parse intentions.

Good runbook (procedure):
```
1. show ip bgp summary | include upstream-1
   Expected: state = a time. If Idle/Active, continue.
2. show ip bgp neighbors 198.51.100.2 | include "Last reset"
   Expected: a reason text.
   "Notification received" = peer ended the session → check their side too.
   "TCP_TIMEOUT" = network path broken → ping the peer's IP.
3. ping 198.51.100.2
   Expected: replies. If no replies, check interface and underlying transport.
   If replies, the session can't form for non-network reasons (config, MD5 mismatch).
4. show ip bgp neighbors 198.51.100.2 | include password
   Verify MD5 config matches the peer. If unsure, contact upstream NOC.
```

Each step has a command, an expected output, and a branch. The reader doesn't need to think; they execute.

## When to write a runbook

After every incident that took longer than 30 minutes to diagnose, ask: "if this happens again at 3 AM, can the on-call resolve it without paging me?" If the answer is no — write the runbook now while the steps are fresh.

A team metric to watch: incidents resolved without escalation. Climbs as runbook coverage improves.

## Runbook hygiene

Runbooks are **living documents**. They go stale:
- The underlying system changes (you migrate from OSPF to BGP — old OSPF runbook is wrong).
- New failure modes are discovered (the runbook covers cases 1-3 but a new case 4 keeps biting).
- Commands change (vendor updates rename `show` outputs).

Set a review cadence: every 6 months, every runbook gets read and validated. Or: every time the runbook is *used*, the user notes any drift in a "next time" section.

Stale runbooks are worse than no runbook — they create false confidence and waste critical incident time.

## Where runbooks live

- In a **shared, searchable** location — wiki, dedicated repo, knowledge-base tool.
- **Linked from every alert**: when PagerDuty fires, the on-call should see "Runbook: [link]" in the alert text. Reduces fumble time at 3 AM.
- **Discoverable by symptom**, not just by service name. The on-call won't always know which service is misbehaving — they'll know what they're seeing.

## Anti-patterns

- **Runbook = the engineer's brain**: works only if that engineer is reachable. Defeats the purpose.
- **Runbook = a list of links to other docs**: at 3 AM, the on-call wants commands, not a treasure hunt.
- **Runbook with no expected output**: "run `show ip bgp summary`" — then what? If you don't tell them what to expect, you haven't helped them.
- **Runbook covering one specific incident, never updated**: usable once. Try to write them at slightly higher abstraction — "BGP session not coming up" rather than "BGP session to ISP-X not coming up on 2026-04-15".
- **No escalation path**: every runbook needs a "if this doesn't work, do X" exit. Otherwise the on-call hits a wall and panics.

## How runbooks reduce incidents

Three direct effects:

1. **Faster resolution**: known incidents have known fixes. On-call goes straight to the fix.
2. **Junior empowerment**: a well-written runbook lets a junior engineer handle incidents that previously required a senior.
3. **Fewer escalations**: senior engineers don't get paged for things juniors can handle from a runbook.

Indirect effects:

- Writing runbooks makes engineers think about failure modes proactively.
- Runbooks become onboarding material for new hires.
- Patterns across runbooks reveal architectural weaknesses to fix.

## Pattern: "the dry run on Tuesday"

Schedule a regular "runbook dry-run" — pick a runbook, walk through it in a test environment as if responding to an alert. You'll find:
- Commands that no longer work.
- Steps that are now unnecessary.
- Gaps where the runbook ends but the problem isn't actually resolved.

20 minutes once a week. Massive payback.

## Pattern: "post-incident runbook write"

Workflow after any nontrivial incident:
1. Service is restored.
2. Take a 5-minute break.
3. While the incident is fresh, capture the resolution steps as a draft runbook.
4. File it in the runbook collection.
5. The next incident-like-this benefits from your work.

Even rough runbooks are vastly better than re-deriving from scratch.

---

**Story-arc references**:
- Phase 3 (`lab 11`, `lab 10`): after the worst-of-year outage, you write your first runbook for "data plane down, OOB still up — recovery procedure".
- Phase 4-5: as the network gets bigger, runbook count grows. Most on-call incidents now resolve from a runbook.
- Phase 7 (tech lead): you mandate runbook coverage for every alert. New hires onboard from runbooks. Runbook reviews are part of the team's quarterly rhythm.

**Template**: [`templates/runbook-template.md`](templates/runbook-template.md)
