# Lab 10 — Logging, NTP, and Baseline Hardening

> **Format:** Hands-on. Two switches + a combined NTP/syslog server. Your job is to make every switch ship logs centrally, sync time, and apply a baseline hardening profile that ought to be on every device from day one. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 3 · Mid-level · Month 10. A 03:00 outage. By 07:00, when you arrived, the switch's local log buffer had already rotated and the relevant lines were gone. The audit log lookup across three switches was meaningless because timestamps disagreed by up to four minutes. Also: the same auditor from lab 03 came back and flagged "no login banner, no idle timeout, HTTP enabled." See [`STORY.md`](../../STORY.md).

## Real-world scenario

Three issues from last quarter's post-mortems:

1. **The 03:00 outage.** Something broke. By 07:00, when the on-call engineer looked, the switch's local log buffer had rotated and the relevant lines were gone. There was no remote log. Root cause: never identified.
2. **Timestamps don't line up.** sw1 says `13:42:01`, sw2 says `13:39:48`, the firewall says `13:48:12`. Tracing a request across devices is guesswork because nobody's clock agrees. Some devices had drifted by minutes since their last reboot.
3. **The "default settings" audit finding.** Auditor flagged: no login banner, no idle timeout on SSH sessions, HTTP server enabled, default timeouts on console. None of these is a critical CVE; together they're an embarrassment.

You need a **baseline hardening profile** every switch gets the moment it's racked. NTP + remote syslog + sensible defaults — small effort, massive payoff.

## Goal

By the end you should be able to answer:

- Why is **central syslog** non-negotiable for any production network?
- What syslog **severity levels** exist, and which should you forward?
- Why does NTP matter for security and operations, not just clocks?
- What's in a **baseline hardening profile** and why does each item belong there?
- What's the difference between **`logging trap`**, **`logging buffered`**, and **`logging host`**?

## Topology

```mermaid
graph LR
    sw1[sw1<br/>10.99.0.1] --> br0
    sw2[sw2<br/>10.99.0.2] --> br0
    br0["services br0<br/>10.99.0.10<br/>chrony NTP + rsyslog"]
```

Both switches are wired to the `services` container, which bridges its two
switch-facing interfaces (`eth1` + `eth2`) into a single Linux bridge `br0`.
The server IP `10.99.0.10` lives on that bridge, so it sits on **one shared
L2 segment** that *both* sw1 (10.99.0.1) and sw2 (10.99.0.2) can reach — they
all share the `10.99.0.0/24` subnet. The `services` container runs both an NTP
server (chrony) and a syslog collector (rsyslog). In a real deployment these
would be separate boxes (or part of larger telemetry stacks).

> **cEOS note:** `network-multitool` is an Alpine image, so the lab installs
> chrony/rsyslog with `apk` and starts the daemons directly (there is no
> Debian `service` wrapper or init system in the container). All of that is
> handled by the topology's `exec:` block — you don't need to touch it.

## Theory primer

### Syslog 101

Syslog is the de-facto log protocol for network devices. Every event the device wants to record gets tagged with:

- **Facility** — what subsystem (kernel, auth, daemon, local0–local7)
- **Severity** — how important (0=emergency through 7=debug)

| Sev | Name | Forward? |
|---|---|---|
| 0 | Emergency | yes |
| 1 | Alert | yes |
| 2 | Critical | yes |
| 3 | Error | yes |
| 4 | Warning | yes |
| 5 | Notice | yes |
| 6 | Informational | usually yes |
| 7 | Debug | usually no — high volume |

Production rule of thumb: forward severity 6 (informational) and up. Skip debug unless you've enabled it for a specific troubleshooting session.

### Three log destinations

Most platforms have three independent logging "targets":

- **Console** — printed to anyone logged in via serial console. Set to severity 4 (warning) and up; otherwise console floods. (On cEOS there is no real serial console, so `logging console` is accepted but has little observable effect in the lab — the buffered and host targets are the ones you'll actually watch.)
- **Buffered (in-memory)** — `show logging` ring buffer. A few thousand lines locally for quick inspection. Set to severity 6.
- **Host (remote syslog)** — shipped to one or more central servers. Set to severity 6 minimum.

A switch losing power loses its buffered log. Only the remote log survives. **If you're not shipping to a remote, you have no logs.**

### NTP — why it matters beyond clocks

- **Forensics**: when an event happens, the timestamps across all your devices must agree to within a second. Without NTP they drift apart, sometimes hours over months.
- **Certificate validity**: TLS depends on time. A clock 2 years off → all your cert validations fail.
- **Kerberos / AAA tokens**: time skew breaks ticket validation.
- **Scheduled events**: cron-like local schedulers fire at the wrong time.

Always at least two NTP sources. Inside a DC, often you have local stratum-2 servers that sync from public stratum-1 sources upstream.

### What's in a baseline hardening profile

The "bare minimum" config items every production switch should have, separate from the protocol/topology configs:

1. **Login banner** — legal notice ("authorized access only") visible *before* authentication. Required for evidence in many jurisdictions.
2. **MOTD banner** — short operational message after login (which device, which environment, "managed by team X").
3. **Idle timeout** — SSH/console sessions that go quiet for N minutes auto-disconnect. 10 minutes is a sane default. Forgotten sessions are a security hole.
4. **Brute-force lockout** — lock an account after N failed logins for a cooldown window. Slows credential-stuffing. (EOS does this via an AAA *lockout* policy, not a per-SSH-session retry counter.)
5. **Disable insecure protocols** — Telnet (yes, still defaults to on on some platforms), HTTP, SNMPv1/v2c if SNMPv3 is available.
6. **TLS for management API** — if you must use HTTP, force HTTPS.
7. **NTP** — sync from known sources.
8. **Remote syslog** — ship logs centrally.
9. **AAA** — TACACS/RADIUS (lab 09).
10. **Management VRF** — separation (lab 08).

All ten go on every device at provisioning. Add to your golden config template.

## Your task

On both sw1 and sw2:

1. Configure NTP client with `10.99.0.10` as the server.
2. Configure logging:
   - Send logs to `10.99.0.10`
   - Severity 6 (informational) for buffered and trap
   - Source from the management interface (Ethernet1)
3. Apply a login banner (legal warning) and an MOTD banner.
4. Set SSH and console idle timeouts to 10 minutes.
5. Enforce a brute-force lockout: lock an account after 3 failed logins.
6. Disable HTTP management; force HTTPS only.
7. Set timezone to UTC (or your local TZ).

## Hints

```
clock timezone UTC
ntp server 10.99.0.10 prefer

logging host 10.99.0.10
logging trap informational
logging buffered 16384 informational
logging source-interface Ethernet1

banner login
legal text here
EOF
# (EOS reads the body verbatim until a line containing only EOF —
#  there is NO Cisco-style ^ delimiter; any prefix becomes banner text.)

banner motd
operational text here
EOF

management ssh
   no shutdown
   idle-timeout 10

management console
   idle-timeout 10

# Brute-force lockout is an AAA policy, not a management-ssh knob:
aaa authentication policy lockout failure 3 window 60 duration 300

management api http-commands
   no shutdown
   protocol https
   no protocol http
```

Verification:

```
show ntp associations
show ntp status
show clock
show logging
show logging hosts
show users detail
```

## Deploy

```bash
cd ~/containerlab/labs/10-logging-ntp-baseline
sudo containerlab deploy
```

Wait ~60 seconds — the `services` container needs to install/start chrony and rsyslog.

## Verification

> **Verify BOTH switches.** The task is symmetric across sw1 and sw2, and
> both share the `10.99.0.0/24` segment via the server's `br0` bridge. Where a
> step below uses `10.99.0.1` (sw1), repeat it against `10.99.0.2` (sw2) too.

### 1. Server-side: confirm the bridge is up and the daemons are listening

```bash
# Both switch links should be enslaved to br0, which carries 10.99.0.10:
docker exec clab-logging-ntp-baseline-services ip -br addr show br0
docker exec clab-logging-ntp-baseline-services ss -lnup | grep -E '514|123'
docker exec clab-logging-ntp-baseline-services ss -lntp | grep 514
```

`br0` should show `10.99.0.10/24`. You should see `udp 514` (syslog),
`tcp 514` (syslog over TCP), and `udp 123` (NTP / chrony) listening. Both sw1
and sw2 should be able to `ping 10.99.0.10`.

### 2. NTP sync

After applying NTP config, wait ~30 seconds, then (do this for sw1 *and* sw2):

```bash
docker exec -it clab-logging-ntp-baseline-sw1 Cli
# then, in a second pass:
docker exec -it clab-logging-ntp-baseline-sw2 Cli
```

```
show ntp associations
show ntp status
show clock
```

The status should eventually show "synchronised to NTP server 10.99.0.10". `show clock` should match the host clock within seconds. Because both switches sync to the *same* source, their clocks now agree with each other — which was the whole point of the 03:00-outage story.

### 3. Remote syslog

Generate a log event on each switch by logging in (just SSH and `exit`):

```bash
docker exec -it clab-logging-ntp-baseline-services ssh admin@10.99.0.1   # sw1
docker exec -it clab-logging-ntp-baseline-services ssh admin@10.99.0.2   # sw2
# log in, then exit, for each
```

Then check the syslog server:

```bash
docker exec clab-logging-ntp-baseline-services tail /var/log/network.log
```

You should see log lines from **both** sw1 and sw2 showing login/logout events. **This is the audit trail that survives power-cycling the switch.**

### 4. Banner displayed

SSH to a switch and confirm the banner appears *before* the password prompt:

```bash
docker exec -it clab-logging-ntp-baseline-services ssh admin@10.99.0.1   # sw1
docker exec -it clab-logging-ntp-baseline-services ssh admin@10.99.0.2   # sw2
```

The legal warning should display. After login, the MOTD appears. Note that
the banner text shows **verbatim** — there should be no stray `^` characters
in front of each line (EOS has no caret delimiter; whatever you type between
`banner login` and the closing `EOF` is shown literally).

### 5. Idle timeout (SSH)

SSH in, type nothing for 10 minutes. The session should drop. (Or shorten the timeout to 1 minute temporarily to verify in less time: `idle-timeout 1` under `management ssh`, then test, then revert.)

> **cEOS note:** There is no serial console on a containerized switch, so
> `management console idle-timeout` is *config-accepted but not meaningfully
> exercisable* here — you can't time out a console that doesn't exist. The
> **SSH** idle-timeout above is the one you can actually observe. On real
> hardware both apply.

### 6. Brute-force lockout

The AAA lockout is enforced by EOS. Confirm the policy is present:

```bash
docker exec -it clab-logging-ntp-baseline-sw1 Cli -c "show running-config section aaa"
```

You should see `aaa authentication policy lockout failure 3 window 60 duration 300`. (To see it bite, fail the SSH password 3 times within 60s — the account is then locked for 300s. Use a throwaway login; locking out `admin` will lock you out too.)

### 7. HTTP is off, HTTPS is on

```bash
docker exec clab-logging-ntp-baseline-services curl -k -m 3 http://10.99.0.1/
docker exec clab-logging-ntp-baseline-services curl -k -m 3 https://10.99.0.1/
```

HTTP should be refused (connection refused or rejected). HTTPS should respond with the EOS management API. Repeat for `10.99.0.2` (sw2) — after the fix, sw2 also disables HTTP and forces HTTPS.

## Peek at solution

- [`solutions/sw1.cfg`](solutions/sw1.cfg), [`solutions/sw2.cfg`](solutions/sw2.cfg)

## Concepts cheat-sheet

- **Syslog severity** — 0 (emergency) through 7 (debug). Production: forward sev 6 and up, skip debug.
- **Logging destinations**: console (4+), buffered/local (6+), host/remote (6+). Remote is the only one that survives a reboot.
- **`logging source-interface`** — ensures every log packet leaves from a known, stable source IP — important for source-based ACLs at the syslog server.
- **NTP** — at least two sources; sync within seconds across all devices; time matters for security, TLS, AAA, and operations.
- **Baseline hardening profile** — banners, idle timeout, disable insecure services, AAA, NTP, remote logging, mgmt VRF. Apply on every device at provisioning, not later.

## Production deployment notes

- **Two syslog servers, two NTP servers.** Single points of failure don't belong in your visibility pipeline.
- **Centralized syslog goes to a SIEM**, not just a log file. Splunk, ELK/OpenSearch, Loki, Wazuh — pick one. Cold storage for old logs is fine; hot search of the last 30 days isn't optional.
- **Don't log debug to remote** — high volume, low signal, costs you in SIEM ingestion fees.
- **Source-interface choice** — pick a stable loopback or the management interface; never an interface that might flap.
- **Rate-limit logs** at the switch (`logging rate-limit`) to prevent a busy port from drowning your collector during a storm.
- **Test ageing-out scenarios** — what happens when the syslog server is unreachable? The switch buffers locally; if buffers fill, oldest lines are lost. Tune buffer sizes.
- **Time** — if you have GPS in your facility, use it as a stratum-1 source. Otherwise sync to a known-good public pool (`pool.ntp.org`, NIST, your country's metrology institute).

## What's missing (deliberately)

- **Streaming telemetry (gNMI / OpenConfig)** — modern alternative for high-volume operational data. Covered in lab 38.
- **AAA-driven access control** — lab 09.
- **Mgmt VRF for these services** — see lab 08 for the VRF pattern; in real configs you'd add `vrf MGMT` to `ntp server`, `logging host`, etc.
- **Log retention policy** — organizational, not a switch config.

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
