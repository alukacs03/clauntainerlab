# Migration Planning (MOP — Method of Procedure)

> Every change in production should have a written plan, even the trivial ones. The MOP is not bureaucratic theater — it's the document that saves you at 3 AM when you're tired and a step doesn't behave as expected, and it's the document a peer reviews to catch the mistake you didn't see.

## Why every change needs a written plan

Three reasons, in order of how often they save your job:

1. **Writing the plan forces you to think about what could go wrong.** The act of writing down "step 5: shut Et3" makes you ask "what depends on Et3?" The blank page asks better questions than your head does at 4 PM on a Friday.
2. **A peer can review it before you run it.** Network changes have non-local consequences. The change that looks fine on your switch can hose someone else's setup. Peer review catches this *before* the change starts.
3. **It's the script you follow when stressed.** When the change is going sideways and the CTO is in your DM, the MOP tells you exactly what step you're on and what to do next. You don't have to think; you execute.

A fourth reason for organizations: it's an audit trail. After an outage you can reconstruct "what was changed, when, by whom, with what plan and what approval."

## What's in a MOP

The minimum useful sections:

1. **Identity**: title, author, change request ID, scheduled window, expected duration.
2. **Goal**: one sentence on what this change is trying to achieve. Business-readable.
3. **Scope**: which devices, which interfaces, which services are affected (and which are NOT).
4. **Risk assessment**: what's the blast radius if this goes wrong? What's the impact on customers?
5. **Pre-checks**: what state must be true before you start. "BGP session to upstream-1 must be Established", "no active incidents". Run these and record results.
6. **Change steps**: numbered, copy-pasteable. Each step has a single command (or small block) and an expected outcome.
7. **Validation**: how do you confirm the change worked. NOT "ping should respond" — specific commands and specific expected outputs.
8. **Rollback**: literal commands to undo the change, including how to detect that rollback succeeded. **A change with no rollback is not a planned change.**
9. **Communications**: who gets notified before, during, and after. What channels (status page, email, Slack).
10. **Sign-off**: who reviewed, who approved.

The template at [`templates/mop-template.md`](templates/mop-template.md) has all of this with placeholders.

## Sizing the MOP to the change

Not every change needs 4 pages. Three tiers:

### Trivial change (single device, no traffic impact)
Examples: adding a description to an interface, enabling a logging option, adding a static `ip name-server`.

MOP can be a paragraph in your change ticket — but it MUST still contain the actual commands you'll paste, expected output, and how to undo. Don't write "I'll add a name server" — write `ip name-server 10.0.0.1` and the matching `no ip name-server 10.0.0.1`.

### Standard change (multi-device, possible brief impact)
Examples: deploying a new VLAN, applying a route-map, adding a BGP neighbor.

Full template. Peer review required. Schedule a maintenance window even if you don't expect impact (your expectation is sometimes wrong).

### Major change (production traffic moves, multiple teams)
Examples: replacing a core switch, migrating to MLAG, adding a new transit provider.

Full template plus:
- Architecture diagram before/after
- Per-step time estimates
- Decision points marked ("if X happens, branch to Y")
- Dedicated incident commander if the change is large enough
- Pre-change run-through on staging if available
- Communications plan with stakeholders, not just NOC

## Common MOP failure modes

Reviewers should look for these specifically:

### Validation that doesn't actually validate
"Verify the BGP session is up." That's vague. The validation should be: `show ip bgp summary | include 10.0.0.1` and the expected text in the output. If the validation passes but the change is broken, your validation is broken.

### Rollback that won't actually roll back
Writing `no ip route 10.0.0.0/8 1.1.1.1` next to your change as "rollback" is the easy 80%. The hard 20%: did the change trigger state changes downstream that won't auto-recover? E.g., shutting an interface causes peer ARP entries to age out, MAC tables to flush, neighbor relationships to flap. The rollback may need explicit steps to recover that state.

### "Should be fine" assumptions
Anything you "expect to be fine" is a step you didn't actually verify. Run it. Document the verification. Or admit you're guessing and add a check.

### Missing pre-checks
Every MOP should answer: what state must be true before I start? Running a change when the network is already degraded turns a planned change into an incident.

### No downstream impact analysis
"This change only affects switch X." Check: who depends on X being up? Is it on the path between two important services? Is the change going to flap a BGP session that another team is monitoring? Document the blast radius, even if it's "none expected".

### Wrong people in the comms list
Telling NOC and forgetting customer success means customers call NOC during the change asking what's happening. NOC didn't know to warn them. Bad day.

## Approval process

Different orgs have different processes. Common bones:

- **Self-approval** for trivial changes — you write the MOP, you do the change.
- **Peer review** for standard changes — at least one teammate reads the MOP and signs off in writing before you execute.
- **CAB (Change Advisory Board)** for major changes — formal review by ops/security/management with a decision before execution. Sometimes considered overhead; usually justified for things that touch customer-facing services.

If your org doesn't have a process, **establish a lightweight one yourself**. Even "I write the MOP and Slack it to a teammate; they 👍 it before I execute" is dramatically better than nothing. The act of someone else reading it catches 30%+ of problems.

## Pattern: "the dry run"

For major changes, do a dry run:
- Read through the MOP front to back as if you were executing.
- For each step, ask: do I actually know what this will output? If not, run it as a read-only `show` first to see.
- For each rollback step, ask: have I tested this rollback? Even a small one in a lab — does the syntax work, does the device accept it?

A 20-minute dry run before a 2-hour maintenance window has saved more careers than I can count.

## After the change

- **Update the MOP with what actually happened.** Did step 3 take 30 seconds or 3 minutes? Did validation step 7 actually catch the thing it was supposed to? File these notes — your next change will be calibrated by them.
- **Close communications**: status page back to green, stakeholders notified that the window is closed.
- **Backup the post-change configs.** Goes without saying.
- **If anything was unexpected, write a brief retrospective.** Not a postmortem (the change succeeded), but a "lessons" note for the next time you do something similar.

## Where MOPs live

- During the change: in a shared doc / wiki / change ticket — somewhere your team can see in real-time.
- After: archived alongside the change ticket for audit + future reference. Searchable by change ID and by affected service.
- Templates: in your team's runbook repo (this repo's [`templates/`](templates/) for example).

---

**Story-arc references**:
- Phase 4 (multi-site rollouts): every site addition becomes a major-change MOP.
- Phase 5 (BGP edge): every transit-provider configuration is a major-change MOP — wrong move and you're offline.
- Phase 6 (DC fabric): MLAG/EVPN migrations are *career-defining* MOPs. They need full team review.

**Template**: [`templates/mop-template.md`](templates/mop-template.md)
