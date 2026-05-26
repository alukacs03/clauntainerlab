# AI-Assisted Network Engineering

> AI coding assistants (Claude, ChatGPT, Copilot, Cursor, etc.) are becoming part of network engineering. They're a force multiplier when used well and a foot-gun when used badly. This guide is the difference between "uses AI like a junior cheats on homework" and "uses AI like a senior delegates effectively to a fast, capable colleague who needs supervision."
>
> This document was itself co-authored by Claude. The author has been on both sides.

## What AI is genuinely good at

Be honest about the wins. AI assistants today are very good at:

- **Writing boilerplate config**: "give me an EVPN VLAN service instance for VLAN 100 / VNI 10100 with RD and RT". The result is correct 90%+ of the time on common configs.
- **Translating between vendors**: "convert this Cisco IOS BGP config to Arista EOS syntax". Saves an hour of looking up commands.
- **Explaining unfamiliar output**: paste `show ip bgp neighbor` output, ask "why is the session stuck in Idle". Often correct, occasionally wrong-but-confident — verify.
- **Drafting documentation**: runbooks, postmortems, ADRs, MOPs. AI gives you a structured draft to edit, not a finished document.
- **Generating test data and lab topologies**: "give me a containerlab topology with 2 spines, 4 leaves, BGP underlay" — saves significant setup time.
- **Searching documentation faster than you can**: ask "where in this PDF does it describe the syntax for ip virtual-router address" — better than scrolling.
- **Code review on automation scripts**: catches bugs in Python/Ansible/Nornir code, identifies anti-patterns.
- **Brainstorming and rubber-ducking**: when you're stuck on "why does this not work", explaining the problem to AI often surfaces the answer (same effect as explaining to a colleague).

## What AI is bad at — and where you get bitten

Equally important:

- **Confidently wrong on niche or version-specific syntax**. AI training data is heavily biased toward popular vendors and older EOS versions. It will confidently invent a syntax that doesn't exist, especially for EVPN, MLAG, and recently-changed features.
- **Inventing show-command output**. Ask "what does `show vxlan address-table` output look like" — the answer might be made up.
- **Plausibly-wrong RFC details**. AI will quote RFCs incorrectly. Don't trust an AI quote — verify against the actual document.
- **Anything requiring physical-world knowledge**. "Why is this DAC cable not coming up" — AI cannot see your cable. It guesses; the guess is sometimes wrong in expensive ways.
- **Live operational decisions**. AI doesn't know your network's current state, ongoing changes, or political constraints. It can suggest; you decide.
- **Multi-step reasoning over evolving state**. If you describe a complex troubleshooting situation across multiple messages, AI loses track of what's been ruled out.

## Rules of engagement

### Rule 1: Never paste customer data, credentials, or unsanitized configs

Sanitize before sending:

- Replace real public IPs with documentation prefixes (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`, `2001:db8::/32`).
- Replace real ASNs with private (64512-65535 for 16-bit, 4200000000+ for 32-bit).
- Strip any TACACS/RADIUS keys, BGP MD5 passwords, SNMP community strings.
- Replace customer names with placeholders.

This is **non-negotiable** even for "trusted" AI providers. The data goes somewhere; you don't get to specify where.

For models running entirely locally (Ollama, on-prem deployments), the rules relax but don't disappear — still don't bake real credentials into prompts.

### Rule 2: Verify every config block before deploying

The AI says `neighbor X update-source Loopback0`. The vendor docs say `neighbor X local-address Loopback0`. Both look right. Only one works.

For anything you'll commit to production:
- Cross-reference the vendor manual.
- Test in a lab first.
- Don't trust "AI says it works" as evidence.

### Rule 3: Use AI to draft, not to decide

AI is great for "give me a starting point". It is bad for "tell me what to do". The difference:

- ✅ "Draft me an MOP for migrating this VLAN to a new uplink." (you'll edit it)
- ❌ "Should I migrate this VLAN at 2 PM or 10 PM?" (you decide; ask AI for trade-off analysis if you want, but the decision is yours)

The latter delegates judgment, which is exactly the part of your job AI should NOT do.

### Rule 4: Cite AI in your work, internally

If you used AI to draft an ADR, runbook, or postmortem — say so in the document. "Initial draft generated with Claude, reviewed and revised by [you]." This:

- Sets correct expectations for reviewers (they know to verify AI-prone fields).
- Builds organizational trust around AI usage.
- Makes you accountable for the output, not "well, the AI said so."

### Rule 5: Verify against your authoritative sources

For this curriculum, the EOS User Manual PDF is the authoritative source for Arista syntax. For real work:

- Vendor docs (primary)
- RFCs (for protocol behavior)
- Your team's ADRs (for design decisions made in your org)
- Your own labs (for behavior verification)

AI is a search interface to these sources, not a replacement for them.

### Rule 6: Don't let AI bypass your learning

The biggest risk of AI in engineering: **using it to skip understanding**. If you copy-paste an AI-generated config without understanding why each line is there, you can't troubleshoot it when it breaks, you can't extend it when requirements change, and you can't defend it in a design review.

Use AI to **accelerate** learning ("explain why this line is needed"), not to **bypass** it ("just give me the config, I don't care why").

## Concrete patterns

### Good: AI-assisted MOP drafting

```
You: "Draft an MOP for the change of moving customer ABC's tenant
from VLAN 100/VNI 10100 to VLAN 200/VNI 10200 on leaves L3 and L4.
Use our standard MOP template structure. The customer requires
zero downtime. We have a maintenance window of 30 minutes on
Saturday at 02:00 UTC."

AI: [returns a draft with sections filled in]

You: [edit; verify; remove the made-up validation step that doesn't
make sense for our environment; add the missing rollback step]
```

The MOP that ships is yours. AI saved you 20 minutes of structure.

### Good: AI-assisted troubleshooting

```
You: "Here's the output of `show ip bgp neighbor 10.0.0.1` [paste].
The session shows OpenConfirm and never reaches Established.
What should I check?"

AI: "OpenConfirm-stuck sessions are usually caused by:
1. Capability mismatch — check 'show ip bgp neighbor 10.0.0.1 | include capability'
2. Hold-timer mismatch
3. MTU issue on the underlying link (MD5-signed BGP packets get fragmented)
4. ..."

You: [work through the list, find the issue]
```

AI gave you a hypothesis tree faster than you'd build one alone. Verification is yours.

### Good: AI-assisted documentation

```
You: "I just ran a postmortem on yesterday's outage. Here are my
notes [paste timeline]. Help me structure this into our standard
postmortem template."

AI: [returns formatted postmortem]

You: [verify, add nuance, write your own conclusions]
```

### Bad: AI as the decision-maker

```
You: "Should we use OSPF or BGP for our DC underlay?"

AI: "Both are valid options. Considerations include: [generic
trade-offs]..."

You: [copy-paste the AI's text into your ADR without doing the
work yourself]
```

The ADR is now generic. It doesn't reflect *your* network's constraints, *your* team's skills, *your* business priorities. Six months from now, your replacement will read this ADR and learn nothing useful.

### Bad: AI as syntax oracle for production

```
You: "Give me the EVPN multi-site config for cEOS 4.30."

AI: [returns confident-looking config]

You: [paste into production]

[Outage. The syntax was for a different version.]
```

This is the most common failure mode. Verify EVERY config block against vendor docs before production deployment.

### Bad: leaking sensitive info

```
You: "Here's our customer's actual /24 prefix and their ASN, can
you help me draft the BGP policy?" [pastes real customer info]
```

The customer's info now exists in the AI provider's logs (depending on provider and plan). At minimum: privacy violation. Potentially: a regulatory issue.

Sanitize FIRST. Always.

## Setting up AI in your workflow

Some patterns that work:

- **Use AI in the explore/research phase.** When you're learning about a new technology, AI accelerates the "what should I read next" loop.
- **Use AI in the draft/scaffold phase.** New runbook, new MOP, new ADR — AI gives you 70% scaffolding. You finish the last 30%.
- **Use AI in the rubber-duck phase.** Stuck on a problem? Describe it in detail to AI. Even if AI's answer is wrong, the act of writing the problem clearly often reveals the answer.
- **Don't use AI in the decide phase.** Decisions are yours; AI can list trade-offs but should not pick.
- **Don't use AI for memory / authoritative reference.** When you need *the* answer, go to the vendor doc or the RFC.

## A note for your team

If you're a senior+ engineer, your team will use AI whether you sanction it or not. The choice is between informal "everyone does it but doesn't talk about it" and explicit policy.

A reasonable team-level policy:

- **OK**: drafting docs, explaining unfamiliar output, generating boilerplate config (with verification), translating between syntaxes, brainstorming.
- **Verify before production**: any config that will be committed.
- **Sanitize before sending**: no real customer data, no real credentials, no internal-only info to external AI.
- **Cite in deliverables**: if AI substantially contributed to a document, say so.
- **Decide for yourself**: AI doesn't sign change-tickets; you do.

This isn't "AI is dangerous" doom — it's the same hygiene you'd apply to a junior teammate who's fast but inexperienced.

## A note on Claude Code, Cursor, and similar tools

If you're using Claude Code, Cursor, or a tool that has filesystem access:

- **Diff-review every change** before it's written. Don't let the tool just write production configs.
- **Use isolation (worktrees, branches)** when generating speculative work.
- **Don't give the tool credentials** that aren't necessary.
- **Read what it actually did**, not what it claims to have done. AI summaries are sometimes wrong about their own actions.

These tools are productivity multipliers, but the productivity multiplies your mistakes too if you're not careful.

---

**Story-arc references**:
- **Phase 1-2**: use AI to explain unfamiliar concepts and output. You'll absorb faster than reading vendor docs cold.
- **Phase 3-4**: use AI to draft MOPs, runbooks, and explanations for tickets. Edit carefully; don't paste raw.
- **Phase 5-6**: use AI to translate vendor configs, draft ADRs, and accelerate research. Verify every config block.
- **Phase 7 (tech lead)**: you set the team's AI policy. You model good behavior (cite AI in your docs, sanitize before sending, verify before production). Juniors will copy your habits.

## TL;DR

- AI is a force multiplier for drafts, research, and exploration.
- AI is unreliable for live operational decisions, version-specific syntax, and authoritative reference.
- Sanitize sensitive data before sending. Always.
- Verify every config against vendor docs before production.
- Use AI to *accelerate* learning, not to *bypass* it.
- Cite AI in your work when it substantially contributed.
