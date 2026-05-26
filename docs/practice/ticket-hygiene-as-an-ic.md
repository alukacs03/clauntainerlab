# Ticket Hygiene as an IC

> Whatever your team uses — Jira, Linear, Shortcut, GitHub Issues, Zendesk — the discipline of working tickets well is its own skill. This is about *using* the system, not setting it up. The difference between an engineer whose tickets close out cleanly and one whose tickets become 47-comment archaeology projects is mostly habit.

## Why this matters

Ticket hygiene is one of those things that's not glamorous but separates competent from sloppy ICs.

- **Your tickets are your work history.** When promotion time comes, your manager looks at what you closed. Cryptic one-liner "fixed it" tickets don't help your case.
- **Tickets are how non-engineers see you.** Sales, support, and project managers read tickets to understand what's happening. If your ticket comment makes them feel like they need to translate, you're creating friction.
- **Tickets are searchable institutional memory.** Three months from now somebody will hit a similar issue and search the ticket system. If your closed tickets are useful, they save the next person hours. If they're junk, that work has to be redone from scratch.
- **Your manager judges your throughput and quality** partly by your ticket flow. They notice when tickets sit, when they're well-handled, when they're abandoned.

This isn't about ticket bureaucracy. It's about treating your work as a series of named, tracked outcomes — and the system records the quality of how you operate.

## The lifecycle of a ticket from the IC side

### Opening a new ticket (yours, voluntarily)

When you start work on something that's worth tracking — even if no one asked you to — open a ticket. Examples worth tracking:
- Investigating a weird behavior that's not yet a customer-facing incident
- Refactoring a config that's been bugging you
- Following up on an audit finding
- A small infra improvement that takes 2+ hours

Why open a ticket for your own work: gives you a place to put notes as you go, signals to your team that this is happening, creates a trail.

What a good "I'm starting work on this" ticket has:
- Clear title (what, not how)
- Brief description: what's the problem, what's the hypothesis
- Acceptance criteria: how will you know it's done
- Effort estimate (even if rough): "couple hours" or "1-2 days"

What it doesn't need: a perfectly formal spec. Get to work; refine the description as you go.

### Picking up an existing ticket

Before claiming a ticket, read it. The whole thing — title, description, comments, attached files. If something is missing or ambiguous, ask in a comment first.

Common rookie mistake: claim a ticket, then realize halfway through that the requirements were unclear, do something else, leave a confused trail.

Once you've read it and understand it:
- Assign yourself
- Move it to "In Progress" (or whatever your team uses)
- Add a comment: "Starting on this; my read is X; I'll start by Y; expecting Z."

The "starting comment" is a small habit with outsized value. It:
- Shows the requester their thing is happening
- Documents your understanding (catches misinterpretation early)
- Gives you a checkpoint for "what did I think this was about?"

### Working on it — updates as you go

While working, leave updates **at least daily** on tickets that span more than a day. Even just "Spent today on X. Hit issue Y. Plan tomorrow: Z."

This is for:
- Your manager / lead, who can see status without interrupting you
- The requester, who's wondering whether their ask is dead
- Your future self, who in two weeks won't remember what Tuesday was about

Don't write a novel; one paragraph is plenty. The bar is *something useful*, not *complete documentation*.

If you get stuck for more than ~30 minutes, write what you're stuck on as a comment. Sometimes the act of writing surfaces the answer. Sometimes a colleague reading later jumps in. Either way, future-you in this situation again will find your note.

### When you discover the ticket is wrong

You started, and the problem isn't what was described. Three options, in order of preference:

1. **The work is still useful, just different from what was asked.** Comment: "While digging in, I found X was actually Y. The originally-requested fix doesn't apply. Here's what I think the right fix is — please confirm before I continue."
2. **You should do something else first.** Comment, then split out a new ticket for the new work, link them, switch to it.
3. **The ticket is wrong / not your problem.** Comment with what you found, reassign or send back to the requester, don't close it silently.

The silent ghost — comment-free abandonment — is the worst. Even if you're 90% sure the ticket is bogus, write the comment that says so. Otherwise nobody else can pick it up usefully.

### Closing a ticket

A ticket close should answer three questions for anyone reading it months later:

1. **What was the actual problem?** (Sometimes different from the title)
2. **What did you do?** (The commands, configs, changes — link the diff/MR if applicable)
3. **How did you verify it's fixed?** (What test confirmed the change worked)

If applicable:
- What else you noticed but didn't fix (open follow-up tickets)
- What documentation you updated
- Any "if this comes back, do X" tip

**Bad close**: "Fixed."

**Bad close**: "It's working now."

**Good close**: "Root cause: customer's port-channel had inherited an MTU of 1500 from a stray base-config remnant after the migration. Fix: explicit `mtu 9214` on Port-Channel20 (commit abc123). Verified: 8000-byte ping with DF set now passes h1→h2; before the fix it was being dropped. Note: opened follow-up ticket NET-1234 to lint our config templates for the missing-MTU pattern."

The good close took 90 extra seconds and saves the next investigator 30+ minutes when something similar happens.

### When NOT to close immediately

If you fixed something but there's a follow-up — a doc to write, a config template to update, a monitoring alert to tune, a postmortem to schedule — **open the follow-up ticket(s) before closing**. Link them in the original ticket's close comment. Then close.

If you don't, the follow-ups die because nobody's tracking them.

## Comment hygiene

Comments are how you signal status to humans. They should be:

- **Skimmable**: most readers scroll the comment thread. Lead with the headline ("blocked — waiting on X").
- **Specific**: "tried it again, still broken" is useless. "Re-tested with sw1's config from running-config after the change; same packet loss between h1 and h2 — see attached capture" is useful.
- **Polite to future readers**: assume the next reader doesn't know what was said in chat. Don't say "as we discussed" — say what you discussed.
- **Free of inside jokes and frustration**: not because you're not frustrated, but because the ticket outlives the frustration. Future you will be embarrassed.

A comment template that works well:

```
[Status] — one word or short phrase
[What happened since last comment] — 1-2 sentences
[Current understanding] — what you now believe
[Next step] — what's happening next (and who's doing it, if not you)
[Ask, if any] — explicit blocker / question for the requester
```

You don't need this every time. But for any ticket where 2+ people are watching, this structure prevents miscommunication.

## Common anti-patterns

### "Status: in progress" — for two weeks
Move tickets to a non-In-Progress state when you're not actively working on them. "Blocked", "Waiting on X", "Paused", "Needs Review" — whatever your workflow has. The state of every ticket should be honest at all times.

### Hoarding tickets
Assigning yourself to 12 tickets you're not actively working on. Your queue should reflect reality. Re-assign or de-assign things that aren't truly yours right now.

### Reopening dead tickets
Don't reopen a 6-month-old closed ticket because something *similar* happened. Open a new ticket, link to the old one as related. Closed tickets are part of history; treat them as such.

### Closing because the requester stopped responding
"They didn't reply, so I closed it" — bad pattern. Open a comment asking explicitly, with a deadline ("If I don't hear back by Friday, I'll close this and you can reopen if needed"). Then close, and put it in the comment.

### Resolving in code/configs without commenting
You merged the config change and forgot to comment in the ticket. The change-tracking system says "done"; the ticket still says "in progress." Link them. Always.

### Padded effort logs
"This took 8 hours" when it actually took 2. Nobody benefits. Your manager will figure it out, and your future self loses calibration on how long things actually take.

### Bikeshedding ticket templates
Spending two hours arguing about whether the "Severity" field should be a dropdown or a number, while real work waits. Get to working tickets; refine the template later.

## Reading tickets from outside your team

Sometimes you're CC'd or watching a ticket from another team. Different rules apply:

- **Don't grab tickets that aren't your team's** unless explicitly handed to you.
- **Comment helpfully when you have relevant info**, but don't take over the conversation.
- **If you think the other team is wrong**, comment your view, but defer to their judgment on their domain.
- **If you think it'll bite your team**, comment with the specific concern and link to ticketing-system-of-record for *your* team if needed.

## Working tickets from non-engineers

Sales, support, product, finance, customers (if you face them directly) — they file tickets in their own language. Some patterns:

- **They describe symptoms, not causes.** "Network is slow" might be DNS, ISP congestion, an ACL change last Tuesday, or a bug. Don't accept their diagnosis at face value.
- **They've often tried things they didn't tell you about.** Ask: "Before I dig in, can you tell me what's already been tried?"
- **They want a status update before they want a fix.** Acknowledge first, investigate second. Five-minute response with "I see your ticket, looking now" beats a 30-minute silence followed by a fix.
- **They use vague time language.** "It started this morning" might mean "started 30 minutes ago" or "started at 4 AM". Pin down the exact time — that lets you correlate with logs.
- **Translation matters.** Your close comment shouldn't have "applied no-shut to Po10" without context. "Restored the bonded uplink on the office switch — the cable's redundant pair was failed-over after Friday's power blip; reactivated it" is better.

## Your own ticket-reading reflex

When you sit down at the keyboard:

1. **Open your queue.** Anything new since you last looked?
2. **Look at in-progress tickets.** Did you leave them with a clear next step? Are you actually still working on them, or did they drift?
3. **Look at blocked tickets.** Is the blocker resolved? Can you unblock anything else?
4. **Look at watcher tickets.** Are you supposed to chime in anywhere?

Five minutes at the start of the day, five minutes before logging off. Becomes muscle memory.

## How tickets, MOPs, runbooks, ADRs, and postmortems relate

Different artifacts, different jobs. They reference each other.

| Artifact | When | Where it points |
|---|---|---|
| **Ticket** | Any tracked work | Links to all related artifacts |
| **MOP** | Planned change | Linked from the ticket; runs the change |
| **Runbook** | Repeating procedure | Linked from incident tickets that match |
| **ADR** | Significant tech decision | Linked from the ticket where decision was made |
| **Postmortem** | After significant incident | Linked from the original incident ticket |

When closing an incident ticket, the close comment should link the postmortem (if one was opened). When closing a ticket where you made a significant decision, link the ADR. The ticket is the spine; everything else hangs off it.

## Quick checklist before closing any ticket

- [ ] Title and description still accurately describe what was done
- [ ] What was actually wrong (not just what was claimed) is documented
- [ ] What was done is documented (with links to commits / configs / MRs)
- [ ] How it was verified is documented (specific check, expected result, actual result)
- [ ] Follow-up tickets opened and linked if any
- [ ] Relevant docs updated (runbooks, ADRs, NetBox entries, etc.)
- [ ] Requester notified if they're someone who needs explicit closure

---

**Story-arc references**:
- Phase 1-2: develop the habit early. The mid-level engineer who closes tickets cleanly stands out from those who don't.
- Phase 3+: as you take on more complex work and on-call, ticket discipline is what keeps your work history navigable.
- Phase 5+: when you're senior, your tickets are also onboarding material for the next person.

## TL;DR

- Read the whole ticket before touching it.
- Leave a "starting" comment when you pick it up.
- Daily updates while in progress.
- Close with: what was wrong, what you did, how you verified.
- Open follow-ups before closing if there are loose ends.
- The state of every ticket should be honest at all times.
