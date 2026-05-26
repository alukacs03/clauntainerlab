# Lab 41 — Control-Plane Protection

> **Format:** Hands-on. Lock down management services to trusted networks; apply CoPP to rate-limit traffic to the device CPU. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 7 · Senior · Year 4. Last week an attacker tried to brute-force SSH on edge routers from the public internet. The brute-force itself failed (good passwords + AAA), but the CPU load from processing 100k SSH attempts/sec made the route processor sluggish — BGP started flapping. You realize: the mgmt plane needs to be unreachable from untrusted networks, AND the CPU itself needs DoS protection. See [`STORY.md`](../../STORY.md).
>
> **Syntax verification:** CoPP syntax varies by platform. cEOS has limited CoPP; production hardware (DCS-7280/7500/7800) has richer per-class policing. Verify against EOS User Manual v4.36.0F.

## Real-world scenario

Two threats this lab addresses:

1. **Management plane exposure**: SSH, HTTPS API, NETCONF — anyone who can route IP packets to the router can attempt connection. Default-allow exposes attack surface. Default-deny + explicit allowlist is the right posture.

2. **Control-plane CPU DoS**: even legitimate-looking traffic can saturate the route processor's CPU. ARP storms, BGP UPDATE floods, ICMP redirects, malformed packets — all consume CPU. Rate-limit per traffic class to prevent any one class from monopolizing CPU.

## Goal

- Configure mgmt-plane ACLs to restrict access to management services
- Apply CoPP (Control-Plane Policing) to rate-limit CPU-bound traffic
- Verify legitimate access works; attacker access is blocked

## Theory primer

### Management Plane ACL

Standard ACL applied to the device's mgmt services. Each service (SSH, NETCONF, HTTPS-API) accepts an ACL that filters incoming connection attempts.

Best practice: default-deny. Only explicitly-allowed source networks reach the service.

```
ip access-list MGMT-PLANE-ACL
   10 permit ip <trusted-mgmt-net>/<prefix> any
   20 deny ip any any

management ssh
   ip access-group MGMT-PLANE-ACL in

management api http-commands
   ip access-group MGMT-PLANE-ACL in
```

### CoPP (Control-Plane Policing)

CoPP is policy applied to packets destined to the device itself (the "control plane"). It classifies traffic into traffic classes and rate-limits or drops by class.

Without CoPP, a single attack against, say, the device's ICMP could saturate the CPU and starve other protocols (BGP, OSPF, NDP).

With CoPP:
- BGP gets reserved bandwidth/rate
- OSPF gets reserved
- SSH gets reserved (only from trusted nets)
- ICMP gets a small reserved budget
- Everything else: dropped

When attack traffic hits, only its specific class is rate-limited. Critical protocols stay healthy.

### CoPP on cEOS

cEOS's CoPP capabilities are limited compared to dedicated hardware. This lab uses a simplified ACL-based approach. Production hardware (Cisco IOS-XR, Arista DCS-7280 hardware) has true per-class rate-limiting:

```
class-map type control-plane match-any BGP
   match ip protocol tcp port bgp
class-map type control-plane match-any ICMP
   match ip protocol icmp
!
policy-map type control-plane CPP-POLICY
   class BGP
      police 10000 burst 1500
   class ICMP
      police 1000 burst 200
   class default
      police 100 burst 100
!
control-plane
   service-policy input CPP-POLICY
```

The lab simplification: just use an ACL to drop unwanted traffic; on real hardware, you'd combine with rate-limits per class.

## Your task

1. Create `MGMT-PLANE-ACL` permitting only the trusted mgmt network (10.99.0.0/24).
2. Apply it inbound on the untrusted interface (Ethernet2).
3. Apply it under `management ssh` and `management api http-commands`.
4. Configure CoPP via an inbound ACL on `control-plane` that:
   - Permits BGP (TCP 179), OSPF (proto 89), NTP, SNMP, ICMP
   - Permits SSH and HTTPS only from 10.99.0.0/24
   - Drops everything else

## Verification

### From the trusted mgmt host
```bash
docker exec -it clab-control-plane-protection-mgmt ssh admin@10.99.0.1
# Should succeed
```

### From the attacker
```bash
docker exec -it clab-control-plane-protection-attacker ssh admin@203.0.113.1
# Should fail (connection refused or timeout)
```

```bash
docker exec clab-control-plane-protection-attacker curl -k --max-time 3 https://203.0.113.1/
# Should fail
```

### Verify the ACL is doing work
```bash
docker exec -it clab-control-plane-protection-edge Cli
show ip access-lists MGMT-PLANE-ACL
```

You should see hit counts on the deny rule when the attacker tries.

```bash
show control-plane
```

Shows the CoPP policy's hit counts per class.

## What's missing (deliberately)

- **Per-class rate-limiting on cEOS** — limited; real hardware does it
- **Strict CoPP with deny-by-default for unknown protocols**
- **Mgmt VRF + ACL combination** (lab 08 covers VRF)
- **VTY ACLs** for legacy non-management-plane CLI access
- **AAA-driven ACL enforcement** (lab 09)
- **DoS protection at L2** (storm-control) — covered in lab 06

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
