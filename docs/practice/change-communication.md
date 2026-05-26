# Communicating Network Changes to Stakeholders

> A change you executed perfectly is still a failed change if half the affected people didn't know it was happening. This is the discipline of *who needs to know what, when, on which channel, in what level of detail*. It pairs with the MOP (which handles the change *process*) — the MOP says "send a comm at T-24h"; this doc is about who that comm goes to and what it says.

## Why this matters — the failure mode

Classic disaster pattern:

- Friday afternoon: network team plans a migration over the weekend. Migration is well-designed, MOP is solid, technical execution is flawless.
- Saturday: migration happens. Monitoring is green. Network team goes home satisfied.
- Monday 9:00 AM: the office walks in. Their access ports moved to a new subnet because of the migration. Their pre-configured SMB shares stop mounting. The build servers they SSH to are at different IPs. The CI pipeline that depended on a hardcoded gateway breaks.
- Monday 9:15 AM: chaos. Slack lights up. The network team's lead is now writing emergency documentation in real-time *while* fielding panicked questions from dev/finance/support.
- Monday 10:30 AM: things are mostly working but trust is bruised. "Why didn't you tell us?" gets asked 12 times.

The technical change was correct. **The communication was the failure.** And communication failures cost more than technical ones in repair — because trust is harder to rebuild than configs.

## The core insight: identify EVERYONE who's affected

The single most common cause of bad change-comms: assuming the impact is smaller than it actually is.

When the network team plans a change, the obvious affected parties are:
- The network team itself
- The on-call rotation
- Anyone using a service the change directly touches

What's easy to miss:
- App teams whose deployment pipeline uses network paths
- Dev/QA teams whose dev environments depend on the affected segment
- Customer support teams who'll receive complaints if customers see anything weird
- Sales/account teams who'll get questions from customers
- Finance/IT operations teams whose backup jobs or scheduled tasks cross the affected path
- External partners (third-party VPNs, vendors monitoring our endpoints)
- The customers themselves, if there's any chance they'll notice

Before any non-trivial change, **make a list**. Force yourself to write the list down. The act of writing surfaces stakeholders you wouldn't have thought of.

A discovery prompt that helps:

> "If I shut down this segment for 2 minutes during business hours, who would notice? Who would file a ticket? Who would call?"

Anyone on that list needs a comm, even if the actual change is planned for off-hours.

## Stakeholder tiers

Not everyone gets the same comm. Different audiences need different content, depth, and timing.

| Tier | Who | What they need | Cadence |
|---|---|---|---|
| **Operators** | Network team, on-call, NOC | Full technical detail: what, when, MOP, rollback, who to call | Earliest. Active participation. |
| **Adjacent ops** | App/dev/devops/SRE/security teams | Technical-ish: what's changing, when, what to expect, what to test on their side | T-3d to T-1d before |
| **Business stakeholders** | Engineering managers, product, customer success | Plain-language: what's happening, what impact, what's already in place to mitigate | T-1d to T-2h before |
| **Affected end users** | Internal employees, devs, etc. | "Here's what to do / not do", calendar invite for downtime, status page | T-1d to T-0 |
| **External customers** | If applicable | Status page, customer comms, account-manager-driven for major customers | Per SLA + buffer |
| **Leadership** | CTO, VP Eng, executive sponsors | Pre-change brief (1 paragraph): scope, risk, fallback. Post-change brief: outcome. | T-1w for major; T-1d for medium |

## What goes in a change-comm

The minimum information for any change-comm:

1. **What** is happening (in their language, not yours)
2. **When** it's happening (date, time, time zone, expected duration)
3. **What impact** they may see (what works, what might not, what to do if confused)
4. **Who** is the contact during/after the change
5. **Where** to get more info (link to MOP if technical audience, link to status page, etc.)

That's it. Five things. You don't need a memo.

### A bad change-comm

```
Subject: Maintenance Friday night
Hi team,
We're doing maintenance Friday night. Should be transparent. Reach out if issues.
Thanks
```

What's wrong: no specifics on time, no specifics on what could break, no contact, no clear scope. The reader can't decide whether to care.

### A good change-comm (to adjacent ops team)

```
Subject: [Network change] Office VLAN migration — Saturday 2026-06-13, 22:00–02:00 CET

Hi devs,

This Saturday night (22:00 CET) we're migrating the office network from VLAN 100
(10.10.10.0/24) to VLAN 200 (10.20.20.0/24). Most things will be transparent
because we use DHCP, but here's what to watch:

WHAT TO EXPECT
- During the change: ~5 minutes of office network unavailability around 22:30.
- After the change: machines will get NEW IPs from the new range. Anything
  hardcoded to a 10.10.10.x address will break.

WHAT TO DO BEFORE
- If your dev machine has hardcoded IPs anywhere (your code, your /etc/hosts,
  CI config, dev shortcut scripts), update them or be ready to update Monday.
- If any of your CI/build infra connects to office workstations directly, flag
  this to me TODAY.

WHAT TO DO MONDAY
- If anything weird, ping me on Slack #netops, NOT the on-call channel.
- Common fix for "can't reach X" issues: `ipconfig renew` on Windows /
  `sudo dhclient eth0` on Linux. Most cases solve themselves.

CONTACT
- During the change: me, via Slack DM or +36-...
- Status page: status.thecompany.example
- Detailed MOP (technical): wiki/MOP-2026-06-13-vlan-migration

— [you]
```

Length: ~200 words. Has all 5 elements. Different audiences read it differently — the dev who has hardcoded IPs scans for "hardcoded" and gets the message; the dev who doesn't reads two lines and moves on.

## Channel selection

Where you send the comm matters as much as what's in it.

| Channel | Good for | Bad for |
|---|---|---|
| **Email** | Durable record, formal notification, async | Real-time updates, urgent comms |
| **Slack #channel** | Real-time team awareness, ongoing updates | "Make sure they read it" — gets buried |
| **Slack DM** | Personal notification to a key person | Mass announcement |
| **Calendar invite** | "Block this time / be aware of this time" | Detail-heavy content |
| **Status page (internal)** | Anyone who self-checks | Pushing notification to specific people |
| **Status page (external)** | Customer-facing | Internal coordination |
| **All-hands meeting** | High-impact major change | Routine changes |
| **Ticket / change record** | Permanent log, technical audience | First-touch communication |

**Rule of thumb**: for any change with non-trivial impact, use AT LEAST TWO channels. Email + Slack. Calendar invite + email. The redundancy means more people see it.

For really big changes: announce in the all-hands, send email, post in Slack channels, put a status page entry, and add a calendar entry to the affected teams' shared calendars. Yes, all of them. Information loss between channels is real.

## Timing — when to send what

For a non-emergency change of any significance:

| When | What |
|---|---|
| **T-1w to T-2w** | Initial heads-up. Mostly for major changes — affected teams can flag conflicts (other planned work, business-critical days). |
| **T-3d** | Confirmed announcement: date locked, scope locked. Most stakeholders see this. |
| **T-1d** | Reminder. "Tomorrow night, here's what to expect." Final ask to flag concerns. |
| **T-1h** | "Starting in an hour." Acknowledgment from on-call ready. |
| **T-0** | "Starting now." Status page goes to "in progress". |
| **During** | Periodic updates, especially for sev-1 visibility. "Still in progress, current step is X." |
| **T+done** | "All clear." Status page back to green. Brief summary if anything notable happened. |
| **T+1d to T+3d** | If anything was unexpected: short post-change note. "Here's what happened, here's the impact, here's what we learned." |

For emergency / unplanned changes: same structure, compressed timeline. Even an "I have to do this in 30 minutes" change deserves a heads-up to the affected people. Five minutes of writing saves an hour of confused responses.

## What NOT to say in change-comms

- **"This will be transparent"** — say what people might see, not what you hope they'll see. Promises that don't hold create distrust.
- **Internal jargon** — non-network audiences don't know what an SVI is. Use plain language.
- **Excessive technical detail** — non-technical audiences zone out. Link to detail for the curious; lead with what affects them.
- **"Please trust us, it'll be fine"** — replace with specifics. Show the rollback plan exists.
- **Hedging that lets you off the hook** — "We don't expect issues" is fine; "We don't *think* there will be issues *but you never know*" is undermining.
- **Apologies for things that aren't your fault** — "Sorry for the inconvenience" once is fine; repeated apologies make the audience suspect bigger problems.

## Different change types, different patterns

### Maintenance during a window
Standard pattern. T-1w / T-1d / T-1h / T-0 / T+done.

### Emergency change (something is broken, need to fix now)
Skip the long-lead pre-notifications, but do brief everyone affected fast. Even a "I'm about to do X, will take 5 min, here's why" Slack message in #netops makes a difference.

### Customer-impacting change
Pre-coordinate with customer success / account team. They drive the customer-facing comms; you drive the technical content. Customer should hear from their account contact, not from you directly (unless there's no account team).

### "Quiet" maintenance (no expected impact)
Even if zero impact is expected, send the comm. The risk-free assumption is wrong often enough that the heads-up is cheap insurance.

### Multi-day / phased change
Don't send one comm and assume people remember. Each phase gets its own announcement.

### Change someone else needs to do (request to a team)
You're asking app team to update their config because you're changing networks. The communication is now a *request*, not a *notice*. Give them lead time, explain why, offer to help, follow up.

## The "I forgot to tell X" mid-change failure

Almost every operator has the "oh shit" moment mid-change when they realize there's an audience they didn't notify.

What to do:
1. **Don't pause the change** unless impact would be severe. Continue the technical work.
2. **Send the missed comm immediately**, even though it's late. Apologize briefly. Explain what's happening NOW.
3. **In the post-change retro / postmortem**, add the missed group to your stakeholder list. Update your standard list so this doesn't happen next time.

Stakeholder lists drift. You only catch them by reviewing them.

## A reusable pattern: the "stakeholder map"

For any change-prone team, maintain a living document:

```
Service: <name>
Owner: <team / person>
Customers (internal teams that depend on this): <list>
Customers (external, if applicable): <pointer to account team>
Adjacent ops: <list>
Notification channels: <list>
Notification lead time: <typical lead time required>
```

Reference this when planning a change. Update it when you learn a new dependency exists. Over months, it becomes a remarkably accurate map of who-uses-what.

## Pair this with: the MOP doc

Mechanics overlap. The [`migration-planning.md`](migration-planning.md) doc treats comms as a section in the MOP template (T-24h email, T-1h status page, etc.). This doc is about **the principles** — who, what level of detail, why. They go together.

A good way to use both:
- Write the MOP. It already has a "Communications" table — fill it in with stakeholder tiers from this doc.
- Before executing: cross-check the stakeholder list against the MOP comm plan. Did anyone get missed?
- During execution: comms happen per the MOP timeline.

## Common operational mistakes

### "We sent it in #netops"
Posting in a channel only the network team monitors doesn't notify the dev team. Channel-only notification is not notification.

### "Just put it in the calendar"
Calendar invites in shared calendars often get auto-declined or hidden. Calendar should accompany email, not replace it.

### Sending so much info that key points are buried
A 5-page email with the key impact buried on page 3 is worse than a clear 1-paragraph email. Lead with what matters; link to detail.

### Vague time zones
"This Friday at 10 PM" — your time? UTC? Customer's time? Always include timezone abbreviation (CET/UTC/etc.).

### No post-change comm
The change finished. Did anyone notice? If you don't send "all clear", anxious stakeholders refresh status pages all night.

### Different comms saying different things
You wrote a calendar invite saying "expected 30 min". You wrote an email saying "expected 1 hour". Now stakeholders don't know what to expect. Sync the content across channels.

## When the change happens WITHOUT your knowledge

Sometimes you're on the receiving end — a change was made and you weren't told. What you do in the moment:

1. **Investigate, don't accuse.** Figure out what changed and what's broken.
2. **Document the impact in real-time.** Photos, screenshots, exact error messages.
3. **Identify the change author**. Don't shame them publicly; reach out directly.
4. **Restore service first**, then learn afterwards.
5. **Postmortem the comms failure.** Not in anger — but the missing comm IS the lesson. The technical change might be totally fine; the comm gap is what broke trust and consumed time.

The user's example from the conversation that motivated this doc — Monday morning, mass confusion because a network change went unannounced — is a classic. The right response wasn't to blame the change author; it was to *generalize* the lesson so the team's comm process catches the next one.

---

**Story-arc references**:
- Phase 1-2: you're affected by other teams' poor comms. Notice the patterns; remember them when you're the one communicating.
- Phase 3-4: you're now executing your own changes. Build the comm discipline.
- Phase 5+: you set the comm standards for your team. Build the stakeholder map; review it quarterly.

## Pair with

- [`migration-planning.md`](migration-planning.md) — the MOP template has a comms table; this doc explains how to fill it in.
- [`incident-response.md`](incident-response.md) — incident comms are a related but distinct discipline. Many of the same principles, much tighter timeline.
- [`runbooks.md`](runbooks.md) — runbooks may include a "comms checklist" at the appropriate point.

## TL;DR

- Identify EVERYONE affected, even those you wouldn't expect. Write the list down.
- Different audiences get different comms; tier your stakeholders.
- Minimum content: what, when, impact, contact, link-to-more.
- Send via AT LEAST two channels (email + Slack, calendar + email, etc.).
- Timing: pre-change cadence, in-flight updates, post-change closure.
- Plain language for non-technical; technical detail behind a link.
- After-the-fact retro is just as important — update your stakeholder list when you discover gaps.
