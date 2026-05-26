# Lab 58 — Failure Scenario Playbook

> **Format:** Chaos-experiment runbook. Inject failures into a fabric, observe blast radius, follow scripted response. Reference observations in the README itself.
>
> **Story chapter:** Phase 9 · Tech lead · Year 5+. A new junior joined the team. You write a failure playbook they can follow at 3 AM — every common failure, what it looks like, what to do, when to escalate. The junior is the reason; *you* benefit too because you can't expect a senior on call every night. See [`STORY.md`](../../STORY.md).

## Real-world scenario

At 3 AM, a junior gets paged. The on-call rotation has them as primary. They've been on the team 3 weeks. They don't know if "BGP session FlapDetected" is bad. They don't know if losing one spine is an outage. They don't know what to escalate.

The failure playbook fixes that:
- For each common failure type: what it looks like in monitoring, what to check, what to do, when to escalate
- Designed for someone who's competent but new
- Each scenario tested in a lab (this one) so the response actually works

This lab is a fabric where you can inject failures and run through the response.

## Goal

- Experience each of the major failure types
- Follow the suggested response steps
- Calibrate: "how bad is this?" "what's the right action?"

## Failure scenarios in this lab

### S1: Spine fails

**Trigger:**
```bash
docker exec clab-failure-playbook-spine1 shutdown -h now
# Or: sudo containerlab tools kill --node spine1
```

**Observed in monitoring:**
- BGP sessions from leaf1 (10.99.1.1) and leaf2 (10.99.3.1) drop to Idle
- Interface counters on leaf1 Eth1, leaf2 Eth1 → no traffic
- Ping h1 → h2: works via spine2 (ECMP failover); some flows reset
- Alerting: "spine1 unreachable"

**Response:**
1. Confirm with `show bgp summary` on a surviving leaf — only spine2 sessions Established
2. Check capacity: is spine2 alone sufficient? (50% of fabric capacity)
3. If yes → file ticket for hardware replacement (sev2, not sev1)
4. If no → emergency response: degrade non-critical tenants, request expedited replacement
5. Update status page if customer-facing impact

**Escalate to senior if:** spine2 also has issues, or capacity is insufficient, or replacement isn't available within SLA.

---

### S2: Leaf uplink fails (one of two)

**Trigger:**
```bash
docker exec clab-failure-playbook-leaf1 Cli -c "configure" -c "interface Ethernet1" -c "shutdown"
```

**Observed:**
- One BGP session from leaf1 goes down
- Other session still up; traffic continues via remaining path
- ECMP reduces from 2-way to 1-way; latency unchanged

**Response:**
1. Confirm: `show interface eth1` on leaf1 → admin/operational state
2. Was this intentional (someone shutting down for maintenance)? Check change calendar
3. If unintentional: physical inspection (DC remote hands), check cable/SFP
4. Run optical diagnostics if available
5. Track: still redundant, no customer impact, sev3

**Escalate if:** second uplink also down (now isolated), or unable to diagnose physical layer.

---

### S3: BGP session flapping

**Trigger:** simulate via repeated soft-reset
```bash
for i in 1 2 3 4 5; do
  docker exec clab-failure-playbook-leaf1 Cli -c "clear bgp ipv4 unicast 10.99.1.1 soft"
  sleep 20
done
```

**Observed:**
- BGP up/down alerts firing repeatedly
- Routes installing/withdrawing → potential RIB churn
- Customer pings show intermittent loss

**Response:**
1. `show bgp summary` → look at "uptime" — short and resetting
2. `show logging | include BGP` → reason for resets (hold timer? notification?)
3. Common causes:
   - Hold timer mismatch → check both sides' configured timers
   - MTU mismatch on session → packets fragmenting → keepalives lost
   - Active route-map causing notify
   - BFD flap → check BFD state separately
4. If flapping continues and the cause isn't obvious within 10 min → escalate

**Escalate to senior if:** BGP keeps flapping despite investigation; route oscillation observed.

---

### S4: Host loses gateway (route missing)

**Trigger:**
```bash
docker exec clab-failure-playbook-leaf1 Cli -c "configure" -c "no router bgp 65001"
```

**Observed:**
- 10.10.10.0/24 no longer announced
- Other leaf can't reach 10.10.10.0/24
- h1 itself still has local network; only outside reachability broken

**Response:**
1. From a surviving leaf: `show ip route 10.10.10.0` → no route
2. From source leaf: `show ip bgp` → check what we're announcing
3. Determine intent: was BGP supposed to be running? (NetBox)
4. If unintentional config change: rollback (git revert + redeploy via lab 53 pipeline)

**Escalate if:** unclear how config got changed (unauthorized?); compare with git, look at AAA accounting (lab 09).

---

### S5: Entire leaf dies

**Trigger:**
```bash
docker stop clab-failure-playbook-leaf1
```

**Observed:**
- h1 disconnected (no gateway)
- All h1's traffic lost
- Spines lose BGP sessions to leaf1
- 10.10.10.0/24 unreachable from anywhere except h1's direct vicinity

**Response:**
1. Confirm leaf1 down: console fail, ping mgmt IP fails, OOB fails (lab 11)
2. Customer impact: 100% of leaf1's tenants offline
3. Sev1 — page senior, status page update, customer comms
4. Execute the replacement runbook (lab 55)

---

## Your task

1. Bring up the lab.
2. Establish baseline: `h1 ping h2` works.
3. Walk through each scenario above. For each:
   - Inject the failure
   - Observe what changed
   - Follow the response
   - Recover

Write up your observations. Compare to the response steps above. Refine the playbook based on what was actually useful.

## Verification

There's no "verify" step per scenario — the *observation* IS the verification. You're calibrating your sense of "how bad is this" against actual fabric behavior.

## What's missing (deliberately)

- **EVPN failure modes** — different blast radius patterns; lab on top of Ch7 labs
- **Stretched VLAN / DCI failure** — covered conceptually in lab 33
- **Storm/loop scenarios** — covered in lab 04/05
- **Customer service-level failure scenarios** (load balancer down, etc.)
- **Multi-fault scenarios** ("what if spine and a leaf both die") — beyond playbook scope; tabletop exercises

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
