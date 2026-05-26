# Career Growth — What "Senior" Actually Means, and How to Get There

> Most engineers stall at the junior-to-mid or mid-to-senior transition not because they lack technical skill but because nobody told them what changes at each level. This is the honest map.

## The titles, and what they're really measuring

Titles vary wildly by company. The underlying levels don't. Here's what they typically measure, in roughly increasing scope of impact:

| Level | Primary job | Time horizon | What "good" looks like |
|---|---|---|---|
| **Junior** | Execute tasks, learn the tooling | Days to a week | Closes their own tickets, asks good questions |
| **Mid** | Own a service / area | Weeks to a month | Trusted with on-call; runs incidents without a senior in the room |
| **Senior** | Design and lead | A quarter | Owns architecture for an area; mentors juniors; called in for hard problems |
| **Staff / Tech Lead** | Multiply other engineers | A year | Sets standards; resolves cross-team technical disagreements; owns the team's tech strategy |
| **Principal / Architect** | Shape the company's technical direction | Multi-year | Influences hiring, vendor relationships, large-scale strategy; the CTO's brain trust |

The progression is **scope of impact**, not "more advanced commands". A junior optimizes their own throughput; a senior optimizes the team's; a staff engineer optimizes the org's.

## What changes between each transition

### Junior → Mid

What stops you:
- Inability to debug independently. Always asks "what should I do?" instead of "I tried X, here's what I saw, my hypothesis is Y, can I verify it like Z?"
- Doesn't yet have the muscle memory for the basics — every command requires looking up syntax.
- Hasn't yet been the on-call for a real outage.

What lands you the promotion:
- Closes tickets without supervision.
- Writes good incident notes (even if not yet IC).
- Has been on-call enough to know the team's recurring failures.
- Started to push back gently when asked to do something risky.
- Can be left alone for a week and the area doesn't catch fire.

Typical time: 12-24 months in role.

### Mid → Senior

This is **the hardest jump** in most engineering careers. It's where engineers stall longest because the skill set fundamentally changes.

What stops you:
- Stays in execution mode. Does excellent work on assigned tasks but doesn't *choose* what to work on.
- Doesn't write things down. Designs exist in their head; team can't review or improve.
- Avoids leadership: prefers to fix bugs solo rather than mentor someone through fixing them.
- Doesn't communicate effectively up or sideways. Surprises managers with status.
- Can't say no. Takes everything; burns out; quality drops.

What lands you the promotion:
- Owns an area end-to-end, including its roadmap.
- Writes ADRs (lab `docs/practice/adr.md`). Decisions are recorded, not just made.
- Mentors at least one junior in a substantive way.
- Has *strong opinions, weakly held* — argues for designs but updates when shown new info.
- Trusted by management to make calls without escalation.
- Can be relied on to flag risks upstream rather than absorbing them silently.
- Writes for the team: runbooks, postmortems, design docs.

The senior shift in one sentence: **you start being measured by the team's output, not just yours.**

Typical time: 2-4 years at mid.

### Senior → Staff/Tech Lead

What stops you:
- Doesn't influence beyond their direct area.
- Doesn't develop other engineers.
- Avoids cross-team work.
- Plays favorites with technologies (the "my hammer" problem).

What lands you the promotion:
- Sets standards the team adopts (the team's MOP template is yours, the ADR practice is yours).
- Resolves cross-team disagreements through technical leadership, not political maneuvering.
- Multiple juniors became seniors at least partly because of your mentoring.
- Trusted with vendor relationships, hiring, technical strategy.
- The team functions noticeably better when you're around than when you're not — *not because you do more work, but because you raise the bar*.

Typical time: 3-5 years at senior.

### Staff → Principal/Architect

This level is rare and political. Not everyone wants it (the trade-offs are real). What it requires beyond Staff:

- **Strategic vision**: not "what should we do this quarter?" but "where should we be in 3 years?"
- **Influence across orgs**: you're trusted by VPs, not just engineers.
- **External visibility**: speak at conferences, contribute to standards bodies, represent the company in vendor councils.
- **Architecture across business units**: you've designed something the whole company relies on.

Not everyone should aim here. The IC track at most companies maxes out at Staff/Principal, and the further you go, the more your job looks like management even though you're still on the IC track.

## The IC vs Management split

At Senior+ you'll be asked which track you want. The trade-offs:

| | IC track (Staff → Principal) | Management track (EM → Director) |
|---|---|---|
| Day-to-day | Designs, technical strategy, mentoring | People mgmt, hiring, performance, roadmap, stakeholder mgmt |
| Skill you optimize | Technical depth + judgment | Communication + organizational dynamics |
| Reward structure | Often slower to top compensation | Generally faster path to senior compensation |
| What you give up | Less direct authority; harder to drive change without influence | Less coding/design; you become a multiplier through others |
| What you get | Stay close to the tech; build deep expertise | Bigger impact through team-building |

**Pick the one you'd be happier doing 80% of**. Both are legitimate. The mistake is going management because "that's how you grow" if you actually love the IC work — you'll be miserable and probably worse at it.

You can switch later. People do it. It's not a career-defining choice; it's a 2-3 year commitment.

## Skills that compound across all levels

Some skills are valuable at every level, getting more valuable as you climb:

### Writing well

Every senior+ promotion has writing as a hidden prerequisite. Engineers who can't articulate their thinking in writing top out. Engineers whose docs are clear, succinct, and helpful get the next opportunity.

Practice: write a postmortem, an ADR, or a design doc per quarter at minimum. Get feedback from someone whose writing you admire.

### Saying no, kindly

The junior trap: yes to everything, burns out.

The senior skill: "I can do X by Tuesday, but it'll delay Y. Which matters more?" — surfacing the trade-off without being adversarial.

The staff skill: "We shouldn't do Z, because [substantive reason], and here's the alternative I'd recommend." — disagreeing with leadership while remaining a constructive partner.

### Asking good questions

Bad question: "BGP isn't working, help?"

Good question: "BGP session between A and B is stuck in OpenConfirm. I've verified TCP/179 reachability (both directions), MD5 password match, and ASN config. I suspect a capability mismatch or MTU issue. How would you bisect?"

Senior engineers help the second person and ignore the first. Train yourself to write questions in the second style — first for others, then for yourself.

### Managing your manager

Underrated skill. Your manager has a job: to know what you're working on, what's at risk, and what you need. Make that easy for them.

- **Weekly 1:1**: come prepared. Don't make them ask "so what are you working on?" — say it.
- **Surface risks early**: "I'm worried about X; I don't need help yet but you should know." Managers hate surprises.
- **State what you want**: explicit growth goals get explicit support; vague ones don't.
- **Be loyal upward**: disagree privately, support publicly. The reverse will end your relationship.

### Building social capital

You'll need favors. Other teams will rescue you in incidents; vendors will prioritize your tickets; your manager will defend you in promo discussions. None of this is automatic — it accumulates through small acts over time.

Specific patterns that build capital:
- Help when asked, even outside your area, when you can.
- Credit people in public.
- Take blame in public (then privately, accurately distribute it).
- Show up to others' on-call disasters even if you don't have to.
- Send the appreciation email that wasn't required.

This isn't politics; it's the operating system of a team.

## What doesn't get measured but matters

A few things that influence careers but rarely appear in performance reviews:

- **Reliability**: do people *count on* you? Do they know that what you say you'll do, gets done?
- **Calm under pressure**: incidents reveal who panics and who doesn't. The latter get the next big project.
- **Curiosity**: engineers who self-direct learning into adjacent areas (you're a network engineer; do you know storage? security? application layer?) become more valuable than those who optimize within their lane.
- **Tact**: you can be technically correct AND not a person nobody wants to work with. Both are required.

## What gets measured (and shouldn't define you)

Things performance reviews track that are partly noise:

- **Lines of code / configs**: bad proxy for impact. A senior who deleted 10,000 lines of legacy is more valuable than a junior who wrote 10,000.
- **Tickets closed**: bad proxy for impact. A senior who unblocks five juniors is doing more than the five juniors closing tickets.
- **Hours worked**: bad proxy for output. Stop optimizing for visibility; optimize for actually-good work.

If your company really only measures these, find a better company or build a track record despite them.

## A note on impostor syndrome

Almost every senior engineer has felt — at some point — that they "don't actually know what they're doing" while everyone else seems to. **This is universal.** It's not a sign you're an impostor; it's a sign that the work has gotten complex enough that nobody fully understands every corner.

What helps:
- Recognize it for what it is (a feeling, not evidence).
- Take action while feeling it; don't wait for the feeling to pass.
- Talk about it with peers; you'll find they feel it too.
- Track your concrete accomplishments in a private "brag doc". When the feeling hits, re-read.

## Specific advice by phase of THIS curriculum

### Phase 1-2 (Junior, your first 6 months)
- Goal: be reliable. Things you say you'll do, you do. Things you don't understand, you ask about (clearly, with what you've tried).
- Habit: at the end of every week, write down what you learned. Three months in, you'll see the curve.
- Risk: imposter syndrome hits hard. Push through it.

### Phase 3 (Mid, year 1-1.5)
- Goal: own one area. Become the go-to person for one thing.
- Habit: start writing — runbooks, postmortems, your own notes that you'd want a future-you to read.
- Risk: comfort. The mid-level engineer's main risk is staying mid-level because they're good enough to be useful but not stretching for senior.

### Phase 4-5 (Senior IC, year 2-3)
- Goal: write the ADRs. Mentor someone. Run incidents as IC.
- Habit: have a strong opinion, present it for critique, update it.
- Risk: becoming the "smart asshole" — technically correct, socially destructive. Watch your tone in code review; watch your patience in meetings.

### Phase 6-7 (Senior/Staff/Tech Lead, year 3-5)
- Goal: multiply others. Standards. Mentoring. Vendor and cross-team relationships.
- Habit: write the things the company needs (architecture docs, reference designs).
- Risk: drifting away from the tech and becoming bad at it. Stay close enough that engineers respect you technically, not just organizationally.

## When to leave a company

Awkward to write but important:

- **You've stopped learning** and the org isn't going to give you new challenges → time to move.
- **You can't get promoted past your current level** for reasons unrelated to your skill (politics, lack of headcount, broken process) → time to move.
- **You're carrying for management failure** quarter after quarter → time to move.
- **The company is shrinking or pivoting away from what you do** → start looking before you're forced to.

You don't owe a company more than what's in your contract. Leaving well — proper handoffs, documentation, no scorched earth — is a senior skill in itself. People remember it.

## What this curriculum is preparing you for

By the time you finish this curriculum end-to-end, you will have:
- Technical depth from VLAN basics to multi-site EVPN.
- Operational discipline (MOPs, runbooks, postmortems, ADRs).
- Communication skills (writing for stakeholders, customers, vendors).
- L1 debug instincts (lab + physical-layer guide).
- Monitoring philosophy.
- AI-usage discipline.

That's a Senior network engineer's profile. The labs are the technical depth; the practice docs are the operational maturity; the story arc is the career narrative that ties it together.

If you've done all the labs, read all the practice docs, and applied them at work — you are no longer a junior. The career is then about scope (Staff, Principal) or direction (IC vs Management), which are personal choices, not skill gaps.

---

**Story-arc references**:
- This document spans all phases. Read it once at Phase 1 (so you know the landscape), again at Phase 3 (when the mid-to-senior decisions arrive), and again at Phase 6 (when the IC-vs-management question lands).

## TL;DR

- Senior = scope of impact, not "more advanced commands".
- The hardest jump is mid → senior. It's about ownership, not skill.
- Pick IC vs Management based on what you'd genuinely enjoy doing daily.
- Compound-interest skills: writing well, saying no kindly, asking good questions, managing your manager.
- Imposter syndrome is universal. Act through it.
- Leave a company well, when it's time.
