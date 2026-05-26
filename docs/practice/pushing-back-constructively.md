# Pushing Back Constructively

> The senior engineer or architect on your team proposes something you think is wrong. The CTO wants to do something fast that you think will hurt later. A peer's design has a flaw you'd bet money on. How do you push back without becoming "that engineer who's always negative" — and without rolling over when you have something legitimate to say?

## Why this is hard

The fear: pushing back looks like insubordination, makes you a "difficult" team member, costs you the next promotion.

The reality: not pushing back when you should *also* costs you — slowly, by making you complicit in bad decisions, and quickly when those decisions break and someone realizes nobody objected.

The skill is **how**, not whether.

## When to push back

A useful triage:

| Situation | Push back? |
|---|---|
| You disagree on style/preference, no clear "wrong" | No. Disagree and commit. |
| Decision will be reversed in <1 week with low cost | No. Let it play out; learn from the result. |
| Decision is hard to reverse and you see a concrete risk | **Yes.** State the risk specifically. |
| Decision will cause customer impact | **Yes — strongly.** |
| Decision is against your professional ethics / safety standards | **Yes — and stay firm.** |
| You don't have full context and the senior probably does | Ask first. Push back only if the answer is unsatisfactory. |
| The decision affects you personally (workload, role) | Yes — but frame it that way; don't disguise it as technical. |

If you find yourself pushing back on everything, you're probably the problem. If you find yourself pushing back on nothing, you're probably the problem in a different way. Healthy engineers do it occasionally and meaningfully.

## The structure of a good push-back

The pattern that works:

```
1. Acknowledge what you understand of the proposal.
2. State your concern specifically.
3. Show evidence (data, prior experience, links to docs).
4. Propose an alternative (or alternative path to evaluating).
5. Make explicit what you'd need to be convinced.
```

This pattern:
- Shows you actually listened (step 1)
- Avoids "I just don't like it" vibes (step 2-3)
- Gives the other person something to work *with*, not just against (step 4)
- Names your update criteria (step 5) — if they meet it, you're committed

### Example (good)

> Re: the proposed VLAN flatten across all access switches —
>
> I understand the goal is to simplify the L2 design and reduce VLAN sprawl in our IPAM.
>
> My concern: collapsing to one big L2 domain across all five access switches will give us a broadcast domain of ~600 hosts. Our last broadcast storm (March 2024 incident, ticket NET-447) took down a 200-host segment for 12 minutes; tripling the blast radius makes the same failure 3× worse.
>
> Data: pps measured during the March storm peaked at ~80k pps. Storm-control thresholds we'd need to safely handle the bigger domain would be aggressive enough to false-positive on legitimate broadcast events (DHCP, ARP cache warmup).
>
> Alternative: keep VLANs per access switch but consolidate the *L3 design* — fewer SVIs, anycast gateway, EVPN if we're going there anyway. That gets the simplification benefit without the L2 blast radius.
>
> What would change my mind: if storm-control thresholds can be set per-VLAN with hysteresis we haven't explored, or if you've seen this scale work elsewhere with hard numbers I can study.

That's a complete push-back. Specific, evidence-based, offers a way forward, names what would change your mind.

### Example (bad)

> "I don't think this is a good idea. We tried something similar before and it didn't work."

Why bad: no specifics, no data, no alternative, no path to resolution. Pure friction.

## Tactical tips

### Push back in writing when stakes are real

For low-stakes verbal disagreements: just say it in the meeting and move on.

For high-stakes ones: write it down. Email, ticket comment, ADR comment, doc — somewhere durable.

Why writing:
- Forces you to be specific
- Gives them time to process without face-saving pressure
- Creates a record if the decision goes ahead and breaks
- Removes voice/tone reactivity from the equation

### Pick your moments

Bringing up a concern five minutes before a deadline is much weaker than bringing it up two weeks before. Even legitimate concerns get dismissed when timing makes them feel obstructive.

When you notice a problem early, **say so early**. Don't sit on it until the last possible moment.

### Lead with the goal, not the problem

Instead of "this won't work because X", try "we both want Y. I'm worried we won't get Y because of X."

You're now on the same side (both wanting Y), just disagreeing about how to get there. Different conversation than "you're wrong."

### Separate the technical and the personal

If you're frustrated with a person and the technical disagreement is the closest available target, you'll write a technically-fine push-back that lands like an attack. Pause; figure out which it is.

If it's actually a person thing: name it separately, in a different conversation. "I noticed you didn't loop me in on the design discussion — I think I'd add value next time" is a different conversation than "the design is wrong."

### Don't push back in front of an audience first

When the senior makes a decision in a meeting full of people, your immediate reflex might be "I disagree." Better: "I want to think about this — can we discuss after the meeting?"

You avoid putting them in a face-save position in public. They appreciate it. Your push-back lands better one-on-one.

(Exception: if the decision is about to do immediate harm — speak up immediately.)

### Recognize "disagree and commit"

You voiced your concern. The senior heard it. They still chose the other path. **Now you commit.** Genuinely. Stop sniping in side-channels. Help the chosen plan succeed.

If you can't commit, you can't continue half-engaged. Either resign from the project, escalate, or accept and execute. Half-engaged is the worst of all worlds.

A clean exit from "disagree and commit":

> "I voiced my concern about X. I think we're going the wrong way, but I respect the call. I'm in. What do you need from me?"

Then deliver. If you turn out to be right, you can revisit later — with evidence — without the "I told you so" being odious.

### Document your dissent (sometimes)

For decisions you believe are seriously wrong and likely to fail:

- Write your concern in an ADR (Architecture Decision Record). The ADR captures the decision *and* the dissenting view.
- Or comment on the ticket / RFC where the decision is made.
- Or send a brief email summary: "Just to record where I am: I think X is risky because Y. I'll execute Z as decided. Wanted this on the record."

This isn't CYA-for-CYA's-sake. It's: if the decision breaks in 6 months and someone digs through the history, they'll see the conversation. Future-you doesn't get unfairly blamed; future-team learns from the pattern.

Don't do this for every disagreement — it makes you look paranoid. Do it for the ones where the stakes are high and you've thought hard.

## When you should NOT push back

Some signals you should reconsider:

- **You're pushing back on style/aesthetics.** "I prefer this naming convention." Not a hill to die on.
- **You're pushing back without doing your homework.** "I have a bad feeling." Don't air feelings; investigate first.
- **You're pushing back on a domain you don't own.** The DBA team made a database decision. You can ask about it, but you don't get to override.
- **You're pushing back because you've already invested in the other path.** Sunk-cost dressed up as technical concern.
- **You're pushing back to prove you're smart.** Status play, not technical contribution. Resist.
- **You're pushing back because you didn't get listened to last time.** Old wound, current target. Address the relationship instead.

## When the senior is wrong AND won't listen

Sometimes despite a perfectly delivered push-back, the senior or lead just steamrolls. What now?

1. **Make sure you really delivered well.** Re-read your push-back. Was it actually clear and specific?
2. **Try one more time, in writing, calmly.** "I want to revisit X. Can we set 30 minutes next week?"
3. **Bring data they can't dismiss.** A specific failure scenario, a benchmark, a prior incident parallel.
4. **Escalate carefully.** If their lead/manager exists, you can ask "would it be appropriate to get [next level up]'s input on this?" Don't go around them; ask first.
5. **Document and execute.** If you can't change the decision, document your concern (see above) and do the work well anyway.
6. **Last resort: leave that project, or leave that company.** If you're consistently overruled on serious things and your concerns turn out to be right repeatedly, you're at the wrong place.

## When you're the one being pushed back on

Worth flipping the perspective. When a colleague or junior pushes back on *your* decision:

- **Treat it as a gift.** They cared enough to risk friction with you.
- **Listen to the actual content,** not your defensive instinct.
- **Acknowledge what they got right** before responding.
- **Address the specific concern,** don't dismiss it generically.
- **Update your view if warranted.** Not updating because of ego is the most expensive mistake you can make.

If you're known as someone who handles push-back well, you'll get more (and better) push-back, which makes your decisions better over time. The senior engineers who get the best work out of teams are the ones who reward dissent rather than punish it.

## A note on power dynamics

Pushing back is easier when:
- You're senior+ in your career
- You have an existing trust relationship with the person
- The person you're pushing back on is psychologically secure
- The org culture explicitly rewards dissent

Pushing back is harder when:
- You're junior or new
- The person you're pushing back on has authority over your career
- The culture punishes dissent (visible or invisible)

The "harder" cases don't mean don't do it — they mean do it more carefully. Get advice from a peer first. Test the waters. Build trust first via being competent and reasonable on smaller things, then exercise dissent on the bigger one.

If your environment makes constructive push-back impossible: that's information about the environment.

## TL;DR

- Push back when stakes are real, decision is hard to reverse, or concerns are specific.
- Use the pattern: acknowledge → specific concern → evidence → alternative → update criteria.
- Write it down for serious push-backs. Forces specificity, creates a record.
- Don't push back to prove you're smart.
- After dissent: commit fully or escalate. Don't snipe from the sidelines.
- When pushed back on yourself: treat it as a gift.

---

**Story-arc references**:
- Phase 1-2: rarely the right move yet; you're still learning the system. Listen and ask.
- Phase 3-4: you'll start seeing things that experienced engineers miss. Practice the pattern on small, low-stakes things first.
- Phase 5+: this is daily-driver senior work. The senior engineers others respect are the ones who push back constructively and accept push-back gracefully.
