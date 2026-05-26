# The Network from an Attacker's Perspective

> A defender who has never thought like an attacker builds defenses that look reasonable but miss real-world attack vectors. This doc is the inversion: what an attacker tries against a typical network, in roughly the order they'd try it. Each section ends with "what defends against this" so you can map back to the curriculum.

This isn't an offensive security guide. It's a defender's mental model.

## Why network engineers should think like attackers

Three reasons:

1. **Defense designs are only as good as the threat model behind them.** If you've never explicitly enumerated what you're defending against, you're defending against your assumptions.
2. **Real attacks don't look like vendor marketing.** Vendors sell "DDoS protection", "next-gen firewall", etc. — but attackers don't read vendor brochures. Knowing actual attack patterns separates good defenders from compliance-checkbox defenders.
3. **Incident response is faster when you recognize attack patterns.** "We're seeing weird BGP updates" + "this matches a route leak pattern" = focused response. Without the pattern recognition, you flounder.

This is not about becoming an offensive specialist. It's about having enough attacker fluency to defend competently.

## The attack lifecycle in network terms

Most successful attacks follow a recognizable pattern. Mature security teams call this the **kill chain** or the **MITRE ATT&CK framework**. Network-relevant phases:

1. **Reconnaissance** — what's on this network?
2. **Initial access** — how do I get in?
3. **Lateral movement** — once in, how do I move?
4. **Persistence** — how do I stay?
5. **Privilege escalation** — how do I get more?
6. **Exfiltration** — how do I get data out?
7. **Impact** — what do I do (DoS, ransomware, sabotage)?

Each phase has network-specific tactics. Defenders care about visibility (can I detect this?) and prevention (can I stop this?) at each phase.

## Phase 1: Reconnaissance

What an attacker tries to learn before doing anything noisy.

### Active recon (touches the target)
- **Port scanning** (`nmap`, `masscan`) — discovers open ports, services, versions
- **Banner grabbing** — connect to a service and read what it says about itself
- **Traceroute** — map the L3 path to the target; reveals intermediate routers
- **Network mapping** — combine multiple recon outputs to draw the topology
- **DNS enumeration** — reverse-DNS sweeps, zone transfers, subdomain bruteforcing
- **BGP looking glass** — public tools (RouteViews, RIPEstat, Hurricane Electric) reveal your prefixes, AS-paths, peering relationships

### Passive recon (doesn't touch the target)
- **Public BGP data** — RIPE, RouteViews — reveals your topology
- **Certificate transparency logs** — reveals hostnames you've issued certs for
- **WHOIS data** — ASN ownership, contacts, IP allocations
- **Shodan / Censys** — search engines for exposed services
- **Social engineering** — LinkedIn for engineer names, public talks for tech stack

### What defends against recon

- **Banner sanitization** — don't expose vendor/version in default banners
- **Mgmt-plane ACLs** — restrict who can reach management services (covered in lab 41, planned)
- **DNS hygiene** — don't allow zone transfers; minimize reverse-DNS leaks
- **No public mgmt interfaces** — OOB management network (lab 11)
- **Operational awareness** — accept that recon is mostly unblockable; focus on detection (alert on excessive scan patterns)

What you can't prevent: someone reading public BGP data. Accept it.

## Phase 2: Initial Access

How an attacker gets a foothold.

### Common network-side initial-access vectors

- **Exposed mgmt interface with weak/default password** — telnet/SSH/HTTP open to internet, password `admin/admin`
- **VPN credentials** — phished, brute-forced, leaked
- **Misconfigured BGP peer** — accepting routes from someone you shouldn't
- **Compromised customer** — attacker takes over a customer's hosting account; now they're "inside" your access network
- **Rogue device** — physical access to a wall jack with no port-security
- **Vendor backdoor or vulnerability** — CVE in your switch firmware, unpatched
- **Insider threat** — disgruntled employee, contractor with too much access

### What defends against initial access

| Vector | Defense | Lab |
|---|---|---|
| Exposed mgmt | OOB network, mgmt-plane ACL, no public mgmt | 08, 11 |
| Default creds | AAA (TACACS+), no shared accounts | 09 |
| Rogue device | PortSec + BPDU Guard + 802.1X | 05, 06 |
| Compromised customer | Per-customer isolation (VRFs, EVPN) | 31, 32, 33 |
| Vendor CVE | Patch management, EOS upgrade discipline | (planned Ch 9) |
| Misconfigured BGP | Prefix-list filtering, max-prefix, RPKI | 23, 25 |

The biggest gaps in most networks are credential hygiene and patch management. Both boring; both essential.

## Phase 3: L2 attacks (lateral movement at Layer 2)

Once attacker has access to a network segment, what they try inside the broadcast domain.

### MAC table exhaustion (MAC flooding)
Attacker sends frames with millions of random source MACs. Switch's MAC table fills up. Once full, the switch reverts to **flooding** (the MAC table doesn't have entries, so every frame is broadcast). Attacker can now sniff traffic that wasn't intended for them.

**Defense**: Port security (lab 06) limits MACs per port.

### ARP spoofing / poisoning
Attacker sends gratuitous ARP claiming to be the gateway. Hosts believe it; their traffic now goes to attacker. Classic MITM.

**Defense**: DAI (Dynamic ARP Inspection) — lab 07.

### DHCP starvation + rogue DHCP
Attacker exhausts the legitimate DHCP server's pool (sends thousands of DISCOVER messages). Then sets up a rogue DHCP that answers new requests, becoming the gateway and DNS for new hosts.

**Defense**: DHCP snooping — lab 07.

### VLAN hopping (double-tag attack)
Attacker on a port in the native VLAN crafts a frame with two 802.1Q tags. The outer tag is stripped by the first switch (native VLAN, untagged on egress). The inner tag — for a different VLAN — is honored. Attacker just sent a frame into a VLAN they shouldn't be in.

**Defense**: Move native VLAN off VLAN 1 to an unused VLAN; tag all frames with `vlan dot1q tag native` — lab 03.

### STP attacks
Attacker plugs a switch in claiming to be root bridge. Wins the election if its priority is lower. Now most traffic in the segment goes through the attacker's switch. MITM at scale.

**Defense**: BPDU Guard on access ports; Root Guard on trunks — lab 05.

### CAM table sniffing on misconfigured trunk
Attacker on an access port that's accidentally also forming a DTP trunk. Now they see ALL VLANs.

**Defense**: `switchport mode access`, never `dynamic`. Explicitly disable DTP. (Lab 03 covers trunk hygiene.)

### Yersinia and friends (the attacker's toolkit)
- **Yersinia**: L2 attack toolkit — automates STP, DTP, CDP, DHCP attacks
- **Ettercap**: ARP spoofing + MITM
- **Bettercap**: modern replacement
- **Scapy**: build any custom packet

If a pen tester or attacker shows up on your network with these, your L2 security trifecta (lab 07) is what they're testing.

## Phase 4: L3 / routing attacks

Beyond the local segment.

### BGP hijacking
Attacker (or compromised peer) announces prefixes they don't own. If accepted by transits/peers, traffic destined for those prefixes is redirected through the attacker. Classic case: the 2008 Pakistan/YouTube hijack.

**Defense**: prefix-list filtering, RPKI (lab 25), IRR validation, max-prefix limits — lab 23, 26.

### BGP route leak
Customer announces routes from one transit to another. Becomes free transit (or unintentional MITM). Recent example: Verizon/Cloudflare 2019.

**Defense**: Gao-Rexford routing policy on every BGP edge — lab 25.

### ICMP redirects
Router sends "go this other way instead" to a host. Attacker on the segment can spoof ICMP redirects, redirecting host traffic through themselves.

**Defense**: Disable ICMP redirects on routers facing untrusted networks. Modern Linux hosts also ignore them by default.

### Source routing
Older IP feature allowing the sender to specify the path. Attacker can route packets through a specific intermediate (themselves) to MITM.

**Defense**: Drop source-routed packets at network edges. Most modern devices do this by default.

### IP spoofing for amplification attacks
Attacker sends UDP queries to amplifiers (DNS, NTP, memcached, SSDP) with spoofed source IP = victim. Amplifier replies to victim with much larger packets. Result: DDoS by amplification.

**Defense**: BCP38 / uRPF (Unicast Reverse Path Forwarding) — only accept packets whose source IP matches the expected ingress interface. Best deployed at every network edge.

### Tunneling attacks
Attacker establishes a covert tunnel (DNS tunnel, ICMP tunnel, HTTPS tunnel) for command-and-control or data exfiltration. Hard to detect because it looks like legitimate traffic.

**Defense**: monitoring + anomaly detection on traffic patterns (high DNS query volume to weird domains, persistent low-bandwidth ICMP traffic to external IPs, etc.). Touched on in monitoring doc; deeper at SIEM layer.

## Phase 5: Management plane attacks

Even with strong perimeter, attackers target your management plane.

### SNMP enumeration (v1/v2c)
SNMPv1/v2c uses plain-text community strings. Default `public` / `private` reveal device config to anyone who can reach the SNMP port.

**Defense**: SNMPv3 only (encrypted, authenticated). Disable v1/v2c. Mgmt ACL on UDP/161.

### Telnet
Plain-text credentials. Anyone sniffing the management plane sees them.

**Defense**: Disable telnet entirely. SSH only.

### Old SSH ciphers / weak keys
DES, RC4, MD5 HMACs. Crackable. Some legacy gear still defaults to these.

**Defense**: Configure modern cipher suites only. Audit periodically.

### TACACS/RADIUS shared secret theft
If the secret is weak or shared insecurely, attacker can impersonate the AAA server or decrypt accounting data.

**Defense**: Strong shared secrets (long, random). Per-device unique secrets if possible. Moving to TLS-protected AAA (lab 09 covers basics; lab 41 — planned — covers control-plane protection).

### Console port physical attack
Someone with a serial cable + the right password can configure anything via console. No network attack needed.

**Defense**: Physical access control. Console authentication enforced. Console-line idle timeout.

### Privilege escalation via misconfig
Attacker has a low-privilege account; finds a misconfigured TACACS rule that lets them run a privileged command.

**Defense**: Audit TACACS rules. Test edge cases. Least-privilege everywhere.

## Phase 6: Exfiltration

Getting data out without being detected.

### DNS tunneling
Encode data in DNS queries (`<base64-data>.attacker.com`). Looks like normal DNS traffic. Every DNS server in the path resolves it.

**Defense**: Monitor DNS query volume per source, alert on unusual patterns. DNS query length monitoring.

### ICMP / ICMPv6 tunneling
Encode data in ICMP echo payloads. Looks like ping.

**Defense**: ICMP rate limiting. Anomaly detection on ICMP payload sizes.

### HTTPS tunneling
Standard web traffic; impossible to inspect without breaking TLS (and breaking TLS has its own costs — corporate MITM proxies do this).

**Defense**: monitoring metadata (destination IPs, traffic volumes, timing patterns). Block known malicious destinations via DNS sinkhole / firewall.

### Slow data exfiltration
Trickle data out at very low rates, mixed with legitimate traffic. Hard to detect with rate-based alerts.

**Defense**: Behavioral baselining + anomaly detection. SIEM-layer concern.

### Egress filtering
Default-deny outbound traffic from internal segments to internet, with explicit allow-lists for required destinations. Massively reduces exfil options.

**Defense**: Egress firewalling per segment. Often overlooked in "internal" environments.

## Phase 7: Impact (DoS, sabotage)

If the attacker's goal is disruption.

### Volume-based DDoS
SYN flood, UDP flood, ICMP flood. Saturates links or exhausts state on edge devices.

**Defense**: RTBH (Remote Triggered Black Hole), BGP Flowspec, upstream scrubbing services — lab 40, planned.

### Application-layer DoS
Slowloris, HTTP request floods. Looks legitimate, exhausts server resources.

**Defense**: Web application firewall layer. Not strictly network.

### Control-plane DoS
Flood the management plane with packets that punt to CPU (BGP, ICMP, ARP storms targeted at the router itself). Router CPU saturates; routing destabilizes.

**Defense**: Control-plane policing (CoPP) — lab 41, planned. Mgmt-plane ACLs.

### Misconfiguration as a weapon
An insider deliberately misconfigures something — wrong route, broken ACL, disabled monitoring — to cause delayed damage. Often the hardest to detect because it looks like a mistake.

**Defense**: Configuration change auditing. Two-person review for sensitive changes. Backup configs to a system the changer doesn't control.

## Internal vs external attackers

The above mostly assumes an attacker reaching from the internet. Reality: many real-world breaches involve **insiders** or **compromised internals**.

Defenses change:
- Perimeter defenses are useless against insiders.
- **Microsegmentation** — limit lateral movement even within the trusted network. Per-customer VRFs (lab 31). Tenant isolation (EVPN multi-tenancy).
- **Audit logging** — log every config change to a system the changer doesn't own.
- **Privileged access management** — TACACS+ with command authorization (lab 09); session recording for tier-1 access.
- **Zero trust principles** — assume nothing is trusted, even internal. Every connection authenticated and authorized.

Your monitoring stack (lab 50 planned, monitoring-and-alerting doc) is where you detect insider activity. Configuration drift, unusual access patterns, unexpected route announcements — these are insider-attack signals.

## What this maps to in the curriculum

A defender's map of which labs / docs address which attack phase:

| Attack phase | Labs / docs |
|---|---|
| Reconnaissance | 03b (LLDP info leak), 08 (mgmt VRF), 11 (OOB), 41 (control-plane protection) |
| Initial access (L2) | 04, 05 (STP defenses), 06 (port security), 07 (DHCP snooping/DAI/IPSG) |
| L2 lateral movement | 03 (trunk hygiene), 07b (QinQ for tenant isolation) |
| L3/routing attacks | 23 (BGP route policy), 25 (Gao-Rexford), 26 (BGP operations + auth) |
| Mgmt plane | 08 (mgmt VRF), 09 (AAA), 10 (logging), 11 (OOB), tls-and-certificates.md |
| Tenant isolation | 14/15 (MLAG/VARP), 31/32 (EVPN VRFs + anycast gateway) |
| DDoS / impact | 40 (planned: DDoS mitigation), 41 (control-plane protection) |
| Detection | monitoring-and-alerting.md, tcpdump-fluency.md, lab 49 (telemetry), lab 51 (failure playbook) |

A network with most of these in place forces attackers into much narrower options. The remaining gaps (zero-day vendor CVEs, insider with privileged access, advanced persistent threats) require defenses at other layers (security team, app layer, SIEM).

## Tools attackers use (and defenders should know)

Familiarize, don't necessarily install:

- **nmap, masscan** — port scanning. Defenders use them legitimately to inventory their own network.
- **Wireshark, tcpdump** — packet capture. Defensive use is documented in [`tcpdump-fluency.md`](tcpdump-fluency.md).
- **Yersinia, scapy, ettercap, bettercap** — L2 attacks. Don't run on production; useful to understand what they do.
- **hping3, hping** — packet crafting; testing firewall rules legitimately.
- **mitm6** — IPv6 MITM via rogue Router Advertisements. IPv6 deployment introduces these.
- **bgpsimple, ExaBGP** — used legitimately for testing BGP peering. Attacker uses them to inject hostile routes.
- **dnscat2, iodine** — DNS tunneling implementations. Knowing them helps detect them.

If you have a security team that does internal pen testing, ask them which tools they use against you and learn what those tools' output looks like in your monitoring. You'll be much faster at recognizing real attacks.

## Mindset

The most valuable shift is **assume breach**. Defending only at the perimeter is 1990s thinking. Modern defense assumes the attacker WILL get in somewhere, eventually — and designs the network so that "in" doesn't mean "everywhere".

- Microsegmentation reduces blast radius
- Least-privilege reduces what each compromised credential gets
- Logging + monitoring catches attacks in progress, not just after
- Recovery time matters as much as prevention time

A network where one phished password compromises everything is fragile. A network where one phished password gets the attacker into one tenant's VRF with monitored access is resilient.

## What this doc deliberately doesn't cover

- **Offensive techniques in operational detail** — this is a defender's doc; offensive details belong in pen-test training elsewhere
- **Specific CVE exploitation** — vendor / version specific; out of scope
- **SIEM / SOC operational playbooks** — the security team's job
- **Application-layer attacks (XSS, SQLi, OAuth flaws)** — not network engineering
- **Endpoint compromise techniques** — endpoint security domain
- **Cryptanalysis** — different field

If you want depth: OWASP for application security, MITRE ATT&CK for adversary tactics, NSA / CISA / NCSC publications for nation-state TTPs (tactics/techniques/procedures).

---

**Story-arc references**:
- Phase 2 (labs 06-07): the first time you see attacker thinking explicitly applied to the access layer.
- Phase 5 (labs 23-25): BGP route policy is where you defend against route leak / hijack — entire categories of high-impact attacks.
- Phase 7+ (planned ch 8): DDoS mitigation, CoPP, RPKI deployment — large-scale defender work.

## TL;DR

- Attackers follow patterns. Recognize the patterns; defenses become focused.
- **Phases**: recon → initial access → lateral move → persistence → escalation → exfil → impact.
- Each phase has network-specific tactics; each has labs/docs in this curriculum that defend against it.
- **Assume breach.** Microsegmentation, least-privilege, logging, recovery time matter as much as prevention.
- Internal attackers exist. Perimeter defenses alone aren't enough.
- Familiarize with attacker tools. You don't have to run them; you have to recognize their output.
