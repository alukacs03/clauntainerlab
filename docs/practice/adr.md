# ADRs — Architecture Decision Records

> Why did we choose eBGP over OSPF for the underlay? Why VARP over HSRP? Why this DC layout? In two years, nobody will remember unless you write it down. ADRs are how senior engineers leave breadcrumbs for their future selves and their successors.

## The problem ADRs solve

You make a non-trivial technical decision. Six months later, a teammate asks "why is the fabric using BGP unnumbered instead of regular /31 transit IPs?" You remember the reason but it's fuzzy. Two years later, your replacement asks the same question. By then, you might not even be there.

Without ADRs, the org loses every architectural decision the moment the person who made it leaves. The result: things get re-litigated, replaced, then replaced back when the original reason is rediscovered.

**An ADR is a short document recording one decision, its context, the alternatives considered, and the consequences.** Five to fifteen minutes to write. Saves cumulative hours to days of future re-decision-making.

## What an ADR is

An ADR is **not**:
- Documentation of how something works (that's a runbook or architecture doc).
- A spec (that's a design doc).
- A justification written after the fact to defend a decision (that's politics).

An ADR **is**:
- A snapshot of a decision at the moment it's made.
- Lightweight (1-2 pages, max).
- Immutable after acceptance — you don't edit it later. If circumstances change, you write a *new* ADR that supersedes the old one.

## Anatomy of an ADR

The minimum useful sections:

### 1. Title
`ADR-NNNN: Short imperative title`. Example: `ADR-0012: Use BGP-EVPN for the new datacenter fabric`.

### 2. Status
One of:
- **Proposed** — under discussion, not yet decided.
- **Accepted** — the decision is in effect.
- **Deprecated** — no longer recommended for new work; existing deployment unaffected.
- **Superseded by ADR-NNNN** — a new ADR replaces this one.

### 3. Context
What's the situation that requires a decision? What forces are at play? Business constraints, technical constraints, time pressure, existing infrastructure, team skills.

This is the "why now?" section. If a future reader doesn't understand why this came up *at all*, they'll think the decision was arbitrary.

### 4. Decision
The decision itself, stated plainly. One paragraph.

### 5. Alternatives considered
What else did you look at? For each, briefly: what it would have meant, why you didn't pick it.

This section is the most useful for future readers. "We considered X but rejected it because Y" prevents the same X from being raised again as if it were a new idea.

### 6. Consequences
What changes as a result of this decision? Both positive and negative.

- Positive: capacity gain, lower complexity, faster deployment, etc.
- Negative: vendor lock-in, learning curve, retraining cost, etc.

Naming the consequences honestly is what makes the ADR trustworthy. If everything is positive, the ADR looks like marketing.

### 7. References
Links to anything that supports the decision: vendor docs, benchmarks, RFCs, related ADRs, the meeting where this was discussed.

## When to write an ADR

Write an ADR for any decision that:
- Is hard or expensive to reverse.
- Affects multiple teams or services.
- A new engineer might reasonably question and need to understand the rationale for.
- Involves choosing between viable alternatives where the reasons matter.

Don't write an ADR for:
- Trivial implementation details ("we used `ip route` instead of `ip route vrf default`").
- Decisions someone else already documented.
- Things that are not actually decisions ("we'll use the vendor's default" — unless the choice to use the default *was* the decision).

## ADR examples from this curriculum

Hypothetical ADRs that would exist if this learning fabric were real:

- `ADR-0001`: Use Arista cEOS as the lab platform (versus FRR, SR Linux, Cisco IOSv).
- `ADR-0002`: Use eBGP for the underlay instead of OSPF.
- `ADR-0003`: Use BGP unnumbered for new fabric builds.
- `ADR-0004`: VARP for MLAG L3 active/active (versus VRRP).
- `ADR-0005`: EVPN with symmetric IRB for multi-tenant L3 overlay.
- `ADR-0006`: Back-to-back EVPN for multi-site (instead of Multi-Site Border Gateway, given current scale).
- `ADR-0007`: Mgmt VRF as the default for all switch deployments.

Each one explains *why* the path was chosen and what was considered.

## ADR lifecycle

ADRs are immutable after acceptance, but they're not eternal. If circumstances change:

1. Write a **new ADR** (with a new number) that supersedes the old one.
2. Update the old ADR's status to `Superseded by ADR-NNNN`.
3. Leave the old ADR's content unchanged — it's the historical record of why the decision made sense at the time.

This means the ADR repository grows over time but never gets "edited". Future readers can trace the lineage: "ADR-0006 was superseded by ADR-0023 when we hit scale Y."

## Where to store ADRs

Most teams put them in a `docs/adr/` folder in their primary repo, numbered sequentially. Some tools generate them; you can also just write Markdown.

Important: they're discoverable. A README at the top of the folder listing each ADR with title and status. Searchable.

## Common ADR failure modes

- **Bikeshedding the format**. Engineers debate ADR structure for weeks instead of writing ADRs. The format doesn't matter as long as Context/Decision/Alternatives/Consequences are present. Just start.
- **Writing ADRs months after the decision was made**. By then, the context is fuzzy. Write the ADR at the time of decision, even if it's rough.
- **"Decision was made, ADR is for show"**. If the ADR is written to justify a decision rather than to record it, it loses its value. Acceptable: writing it during the decision-making process. Not acceptable: writing it weeks later to look process-mature.
- **ADRs that read like marketing**. Honest consequence sections (including negatives) are the difference between a useful ADR and a CYA document.
- **No status updates when things change**. A decision is "superseded" eventually; the old ADR should reflect that.

## A short example

```markdown
# ADR-0004: Use VARP instead of VRRP for inter-VLAN gateway redundancy

## Status
Accepted (2026-04-15)

## Context
The new MLAG-paired distribution switches need redundant gateway IPs for tenant
VLANs. Both peers should ideally forward L3 traffic to maximize hardware
utilization. Two viable options were considered: VRRP (active/standby) and
VARP/anycast gateway (active/active).

We have two MLAG peer pairs at each site; each pair serves ~50 VLANs.

## Decision
Use VARP (Arista anycast gateway) on every MLAG peer pair.

## Alternatives considered
- **VRRP**: well-understood, multi-vendor. Rejected because only one peer is the
  active gateway at a time, leaving 50% of L3 capacity idle. Acceptable for non-
  MLAG designs but suboptimal here.
- **HSRP**: Cisco-specific; we have Arista switches.

## Consequences
- **Positive**: both peers actively route, doubling effective L3 throughput per
  pair. No master/backup state, no failover delay (instant on peer failure).
- **Negative**: requires a shared virtual MAC across peers — strict config
  discipline. Cross-vendor migration (if we ever leave Arista) would need
  reconfiguration.
- This decision applies only to MLAG-paired switches. Non-MLAG L3 redundancy
  continues to use VRRP.

## References
- Lab 15 demonstrates VARP on MLAG.
- Concept doc: docs/concepts/first-hop-redundancy-comparison.md
- Arista EOS User Guide v4.36.0F, section on Virtual ARP.
```

That's 250 words. Five minutes to write. Future readers know exactly why VARP, exactly what was considered, and exactly what the trade-off was.

---

**Story-arc references**:
- Phase 5+: as you make architectural decisions on the BGP edge and DC fabric, every non-trivial choice gets an ADR. The CTO will start asking to see them before architectural reviews.
- Phase 7 (tech lead): you'll mandate ADRs for your team's significant decisions, and you'll mentor juniors on writing them.

**Template**: [`templates/adr-template.md`](templates/adr-template.md)
