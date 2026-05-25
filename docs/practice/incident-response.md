# Incident Response & Blameless Postmortems

> Outages are about *following a process*, not heroic engineering. The hero who fixes the outage in 4 minutes but didn't communicate created more chaos than they solved — customers don't know what happened, on-call doesn't know what's been tried, leadership thinks the system is still down. This document is the process.

## Severity levels

Every org defines these slightly differently. Common 4-level scheme:

| Sev | Meaning | Response time | Who's involved |
|---|---|---|---|
| **Sev1** | Production down or significantly degraded; revenue-affecting | Immediate (page on-call) | IC, comms lead, all-hands engineering, leadership notified |
| **Sev2** | Major feature down or significantly degraded; some customers affected | <15 min | IC, on-call team, leadership informed |
| **Sev3** | Minor degradation, workarounds exist, no customer impact yet | Next business hour | On-call investigates, fixes during normal hours |
| **Sev4** | No impact, but something is wrong | Best effort, low priority | Logged for follow-up |

**Sev1 is the dangerous category** — the temptation is to call everything sev2 because sev1 means waking leadership. Don't. If your customers are seeing impact, it's a sev1. The point of sev1 is to mobilize the right response, not to scare the boss.

## The Incident Commander role

In any incident larger than "I'm the only person involved, this takes 5 minutes", **someone is the Incident Commander (IC)**. The IC's job is NOT to fix the problem — the IC's job is to coordinate.

### What the IC does
- Declares the incident at the right severity.
- Pulls in the right people (on-call, SMEs).
- Maintains the timeline: who tried what, when, what the result was.
- Decides when to escalate.
- Owns the comms: gives status updates to stakeholders.
- Calls the shots on go/no-go decisions (e.g., "should we roll back?").

### What the IC does NOT do
- Type into switches. The IC is hands-off the keyboard. If the IC is also the only person who can fix it, *then* they're the technical lead AND IC — but they should hand off IC duties as soon as another person can take them.

### Why a separate IC
Engineers in the middle of fixing a complex outage cannot also be writing status updates. Every interruption breaks their thinking. The IC absorbs the interruptions and lets the technical lead focus.

## Incident roles (more than just IC)

For sev1, typical roles:

- **Incident Commander (IC)**: coordinates, decides, communicates.
- **Technical Lead**: actually fixes the problem. SMEs report to them.
- **Comms Lead**: writes status updates to customers, status page, internal stakeholders. The IC steers, the comms lead writes.
- **Scribe**: keeps a running timeline of events, hypotheses tested, actions taken. Critical for the postmortem later.
- **SMEs**: subject matter experts pulled in as needed (BGP person, storage person, app-team person).

In a small org you might be three of these. That's fine — but recognize the roles and consciously switch between them.

## Status update cadence

Communications discipline during an incident:

- **Sev1**: status update every 15 minutes, even if nothing has changed. "Still investigating. Symptoms: X. Currently testing hypothesis Y. Next update at HH:MM." Silence creates more chaos than honest "we still don't know".
- **Sev2**: every 30 minutes.
- **Sev3**: hourly or on significant state change.

A status update has three parts:
1. Current state of impact (what's broken).
2. What's been tried / what we currently think the cause is.
3. Next step + when the next update will come.

That's it. Three sentences. The temptation is to write a paragraph; resist.

## The "stop fixing, start communicating" trap

Common failure mode in technical orgs:
- 02:00 — engineer notices alert, starts investigating.
- 02:15 — they're deep in a debug session, finding interesting stuff.
- 02:30 — half the company is paged, customers are tweeting, *and the engineer still hasn't sent a status update because "I'm about to figure it out"*.

Rule: **the first thing you do when an incident escalates is communicate it, even if you have nothing to say**. "Investigating an outage on the EVPN fabric, no ETA yet, more in 15 min." Then continue investigating.

## When to roll back vs continue fixing

If you don't know what's causing the outage and a rollback is available, **roll back first, debug afterward**. Customer impact comes first. The "I almost have it" instinct is the one that turns a 10-minute outage into a 2-hour one.

Exceptions:
- If rollback would be more disruptive than the current state.
- If you already know the cause and the fix-forward is faster than rollback.
- If rollback isn't possible (no idempotent reverse for the change you made).

## After the incident

The incident isn't over when service is restored. It's over when:

1. Customers have been notified that service is restored.
2. Status page is back to green.
3. Internal stakeholders have been told.
4. A *placeholder* postmortem has been scheduled (date + scribe + assigned facilitator).

## Blameless postmortem

After every sev1 (and ideally sev2), within a week, run a blameless postmortem.

### What "blameless" means
Not "we pretend nobody made a mistake." It means: the postmortem focuses on **systemic factors** that allowed a human mistake to cause an outage, rather than on the individual who made the mistake.

If an engineer typed the wrong command, the question isn't "why did Alice type the wrong command?" — Alice will not type the wrong command again, but Bob, Carol, and Dave still might. The right question is "why does our tooling allow this command to take down production? Could we have linting, peer review, a confirmation prompt, a smaller blast radius?"

### Postmortem agenda
1. **Timeline** — chronological reconstruction. The scribe's notes are the foundation.
2. **Impact** — customers affected, revenue, duration.
3. **Detection** — when did we know? How? How could we have known sooner?
4. **Response** — what worked, what didn't.
5. **Root cause(s)** — usually multiple contributing factors, not one root cause. Five Whys is a useful tool but don't worship it.
6. **Action items** — concrete, owned, dated. "Improve monitoring" is not an action item. "Add alert on BGP session down to monitoring, owned by X, due Friday" is.
7. **What went well** — don't skip this. Reinforces good behaviors.

### Common postmortem failure modes
- Skipped because "we're too busy" → you'll have the same outage again
- Action items with no owner / no date → never done
- Blame focused on individuals → people stop reporting incidents
- Treated as a one-time event → no pattern recognition

### Postmortem document
Use [`templates/postmortem-template.md`](templates/postmortem-template.md). Store somewhere searchable (wiki, dedicated repo, etc.) so future incidents can find similar past ones.

## Runbooks reduce incidents to checklists

The best response to a recurring incident is a runbook. After a postmortem, ask: "could this be a runbook entry?" If yes, write it (see [`runbooks.md`](runbooks.md)).

## "War stories" — narratives, not anonymized

Once you have ~10 postmortems, share them within the team. Pattern-matching across incidents is the most valuable learning. Senior engineers can read a new incident's first paragraphs and immediately think "this looks like the Tuesday outage in March."

---

**Story-arc references**:
- Phase 3 (`lab 10`): the 3 AM outage where local logs had rotated. That's when IC/runbook/postmortem discipline starts to matter.
- Phase 4-5: incidents get bigger and customer-impacting. Real IC role becomes essential.
- Phase 7 (tech lead): you're now the IC for the team's worst incidents, and you're writing the org's incident response standards.

**Template**: [`templates/postmortem-template.md`](templates/postmortem-template.md)
