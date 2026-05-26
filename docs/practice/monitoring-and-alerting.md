# What to Monitor & When to Alert

> Most engineers monitor what's easy (interface up/down) and miss what matters (BGP session state, control-plane CPU, error counters trending up). The difference between a junior and a mid-level engineer's monitoring stack is the difference between "we got paged after the outage" and "we got paged before customers noticed."

## The two questions every alert must answer

Before adding any alert, ask:

1. **Is something actually broken or about to break?** (Not "is a value above some threshold")
2. **What should the on-call do about it right now?**

If you can't answer #2 with a specific action, the alert shouldn't page anyone. It might be a dashboard metric, or a daily report, but it's not an alert.

The #1 source of pager fatigue: alerts that fire but have no clear action. The on-call clicks "acknowledge", goes back to sleep, and now the next real alert gets ignored too.

## The monitoring pyramid

A useful mental model: monitoring exists at three levels.

### Level 1: Is the box even there?

The cheapest, most reliable monitoring. "Did the switch respond to a ping in the last 60s?" Answers: is the management plane reachable, is the box powered on, is the OOB working.

Sources: ICMP ping, SNMP heartbeat, gNMI session, or just SSH-test connection.

**Always have this.** Without it, you don't know if a higher-level monitoring failure means "the metric is bad" or "the box is dead and we can't get any metric at all."

### Level 2: Are the protocols up?

Are the things-that-make-the-network-work actually running?

- **BGP session state** per neighbor (not just "is BGP running" — *each session* in Established state).
- **OSPF/IS-IS neighbor adjacencies** (Full state, not just neighbor visible).
- **BFD session state** per peer.
- **MLAG peer link + peer state** (lab 14).
- **VRRP master state** per VRRP group.
- **EVPN session state and route counts** per neighbor.

These tell you "the control plane is healthy or it isn't".

### Level 3: Is data flowing correctly?

- **Interface counters**: traffic rates, error rates, drop rates.
- **MAC table fill** (% of hardware capacity).
- **Route table size** (BGP RIB size, FIB utilization).
- **TCAM utilization** (ACLs, route prefixes — modern switches have limits).
- **Control-plane CPU** (one of the most underused metrics — see below).
- **Memory usage** on the box itself.
- **Power supply state, fan state, temperature** (environmental).

This is the "is it healthy beyond the basics" layer.

## The metrics juniors miss

Time to call them out specifically.

### Control-plane CPU

Why this matters: the data plane forwards in hardware (ASIC), but the control plane (BGP, OSPF, ARP, BFD, mgmt) runs on the box's CPU. Saturating the CPU causes:
- BGP/OSPF session timeouts (Hellos not sent in time).
- BFD false-positive failures.
- SSH sessions becoming unresponsive.
- Cascading outages because everything tries to recompute at once.

A trend graph of CPU% over time is one of the most predictive signals you have. CPU climbing toward 80%+ on a normally-30% box is "investigate now" — even before anything breaks.

### Error counter *deltas*

`show interfaces counters errors` shows cumulative values. Cumulative is mostly useless — what matters is the *rate of change*.

Right metric: `input_errors_per_second` rate, alerted when it's above some small threshold (e.g., 1/s for sustained 5 minutes).

A switch with a slowly-degrading fiber will show errors gradually climbing. With cumulative monitoring, you can't tell. With delta monitoring, you'll see the trend and replace the optic before it blacks out.

### MAC table and TCAM fill

Modern switches have hardware limits. A leaf in a large fabric can have tens of thousands of MACs in TCAM. Once full, new MACs flood (no entry → broadcast every frame). Performance tanks; CPU spikes.

Alert: "MAC table > 80% of hardware capacity". You'd rather know now than during a customer ramp-up.

Same for FIB / route table — once you exceed hardware capacity, prefixes start punting to software. Massive performance hit.

### BFD session flaps

BFD detects fast failures (lab 19), but BFD itself can flap (transient packet loss). A handful of BFD flaps per day is normal noise. *A flap rate that doubled this week* is a real signal — could be marginal cable, congestion, optical issue.

Monitor the rate, alert on the change.

### Route count

If your fabric normally has 50,000 BGP routes and suddenly has 800,000, your peer is leaking (lab 25). If it suddenly has 100, your peer is filtering you (or you broke an outbound policy).

Both directions of the deviation are problems. Alert on both.

### Power and environmental

Yes, really. PSU failures, fan failures, and temperature alerts are vendor-supported and almost always actionable. A failed PSU on a non-redundant switch is a "fix this week" alert. Two failed PSUs on a "redundant" switch is a "fix now" alert.

## The alert tiers

| Tier | Response | Examples |
|---|---|---|
| **Page** (wake someone up) | Immediate human action required, customers affected or about to be | Switch unreachable; BGP session to upstream down; MLAG peer-link down; fan failure on a single-PSU device |
| **Ticket** (looked at next business hour) | Action required but not urgent | Single PSU failed on a dual-PSU device; route count drift; CPU trending up |
| **Dashboard** (no action) | Useful to know, no immediate action | Interface utilization; BGP route counts; capacity trends |
| **Silent** (logged for forensics) | Not alerted; available for post-incident analysis | Detailed traffic logs, flow records |

The biggest junior mistake: putting things on **Page** that should be **Ticket** or **Dashboard**. Result: pager fatigue, real alerts ignored.

The second-biggest junior mistake: putting actionable things on **Dashboard** instead of **Ticket**. Result: nobody looks until a customer complains.

## Alert design rules

### Rule 1: Every alert needs a runbook link

Every paging alert should have, in its definition, a link to the runbook that the on-call should follow. Without it, on-call has to figure out what to do at 3 AM. That's where mistakes happen.

See [`runbooks.md`](runbooks.md).

### Rule 2: Symptoms, not causes

Alert on what users see, not on internal state.

- ✅ "Customer reachability to upstream-1 is degraded" (alert on packet loss / latency / connectivity).
- ❌ "BGP route count from upstream-1 changed by 10%" (alert on something that *might* cause an issue).

The second one is a dashboard metric. The first is a pager alert. The first is also closer to the customer's experience and forces you to think about *impact* rather than *cause*.

### Rule 3: Alert hysteresis

Don't alert on "CPU > 80% for 1 sample". Brief spikes are normal. Alert on "CPU > 80% for 10+ minutes" — that's an actual trend.

Hysteresis: also have a "recovery" threshold lower than the firing threshold (e.g., fire at 80%, recover at 60%). Prevents flapping alerts.

### Rule 4: One alert per cause

A failed link triggering "interface down", "BGP session down", "BFD session down", and "route count changed" should produce **one page**, not four. Group related alerts; suppress downstream cascades.

Easier said than done; many monitoring stacks handle this poorly. At minimum: write your alert names so the on-call recognizes the cluster ("INTERFACE DOWN: et1/sw1" and "BGP DOWN: 10.0.0.1 via et1/sw1" should be obviously related).

### Rule 5: Alert at the right severity

If a paging alert fires and the on-call thinks "this isn't urgent", the threshold is wrong. Lower it (it should be ticket) or rewrite the runbook to explain why it IS urgent.

### Rule 6: Quarterly alert review

Every quarter, review the firing patterns. Alerts that fired and nobody acted → either tune the threshold or remove the alert. Alerts that fired and weren't actionable → fix or remove.

The goal: every paging alert in your stack, looking at last quarter, had a human do something useful in response.

## What to actually deploy (a starter set)

A reasonable minimum set for a modern DC switch fleet:

### Paging (must wake someone)
- Box unreachable from monitoring (60s threshold)
- BGP session to external peer (transit, customer) down (90s threshold)
- BGP session to internal peer (iBGP) down for >5 min
- MLAG peer-link down
- Multiple PSU failure
- Fan failure on a box without redundancy
- Temperature critical
- Interface flapping (5+ flaps in 10 min)
- Storm-control / errdisable triggered
- Sustained 95%+ interface utilization (capacity emergency)

### Ticketing (next-business-hour)
- Single PSU failure
- Single fan failure  
- BFD session flap rate > usual baseline
- Route count deviation > 20%
- CPU sustained > 70%
- Memory > 80%
- Interface error rate sustained
- TCAM/MAC/FIB > 75% utilization
- Configuration drift (running != startup)

### Dashboard / SLO tracking
- Interface utilization trends
- Route count history
- Latency between sites
- Customer prefix announcement coverage
- Per-customer traffic accounting

## Monitoring stack picks

Brief opinion: in a modern DC, **streaming telemetry (gNMI)** beats SNMP polling for high-resolution metrics. SNMP is fine for slow-changing things (uptime, hardware health) but loses resolution for fast metrics. gNMI lets you stream counters at sub-second cadence.

Tools you'll see:
- **Prometheus + Grafana** for time-series.
- **InfluxDB / TimescaleDB / similar** for higher-cardinality storage.
- **gNMI collectors** (gnmic, etc.) to subscribe to streaming telemetry.
- **Alertmanager / PagerDuty / Opsgenie** for the paging layer.

Specific tool choice matters less than the discipline of what you monitor and how you alert.

## Operational discipline

### Alert acknowledgment culture

When an alert fires, the on-call acknowledges it within N minutes (whatever your SLO is — 5 min for sev1, 15 for sev2). Acknowledgment ≠ resolved; it means "I see this, I'm working it." Without acknowledgment culture, alerts get ignored.

### Postmortem-driven alerting

After every postmortem (see [`incident-response.md`](incident-response.md)), ask: "what alert would have caught this earlier?" If the answer is "nothing existed", add one. Over time the alert set evolves to match the failure modes of your network.

### "Alert that never fires" is a code smell

If an alert has never fired in a year, either:
- It's been correctly tuned and the underlying thing genuinely doesn't happen (rare).
- It's misconfigured and will never fire even when the thing happens (more likely).

Periodically *test* alerts you depend on. Synthetic events. Validation that the pipeline still works end-to-end.

---

**Story-arc references**:
- **Phase 3 (`lab 10`)**: after the 3 AM outage where logs had rotated, you also fix the *monitoring* — adding alerts for the failure mode that just bit you.
- **Phase 4-5**: monitoring stack matures from "interface up/down" to "BGP sessions, capacity trends, control-plane CPU".
- **Phase 6-7 (DC fabric)**: streaming telemetry, EVPN-aware monitoring, per-tenant SLO tracking. By now monitoring is a separate engineering project, often with its own owner.

## TL;DR

- Every alert must answer "what should on-call do?"
- Three tiers: page (urgent), ticket (next BH), dashboard (informational).
- Don't miss: control-plane CPU, error counter deltas, MAC/TCAM/FIB fill, BFD flap rate, route count drift.
- Alert on symptoms (customer impact), not on internal causes.
- Every paging alert needs a runbook link.
- Review alerts quarterly. Remove ones that don't drive action.
