# Lab 36 — CGNAT (Carrier-Grade NAT)

> **Format:** Hands-on. One CGN box NATs many subscribers (in RFC 6598 100.64.0.0/10 space) to a small pool of public IPs. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 7 · Senior · Year 4. The Company's /22 of IPv4 is running out. New customers can't get individual public IPs anymore. CGN (Carrier-Grade NAT) lets you share a few public IPs across many customers. See [`STORY.md`](../../STORY.md).
>
> **Syntax verification:** Production CGN runs on dedicated hardware (ASR1000, MX, A10). cEOS approximates the mechanism for learning. Verify against EOS User Manual v4.36.0F section 9.3.1 for production deployment.

## Real-world scenario

IPv4 exhaustion is real. New customers in 2026 can't easily get a /29 or even a single public IP — RIPE/ARIN ran out years ago. Existing /22-blocks are precious.

**CGN (NAT444)** is the answer for ISPs/hosting providers that need to onboard new customers without giving each a public IP:
- Customer assigned an IP from `100.64.0.0/10` (RFC 6598 "shared transition address space" — purpose-built for CGN, NOT RFC 1918)
- CGN box translates many customers' source IPs to a shared pool of real public IPs

It's "double NAT": customer might NAT themselves (RFC 1918 → 100.64.x.x) and then your CGN NATs again (100.64.x.x → public IP). Hence "NAT444" (3 sets of 4-octet IPs).

## Goal

- Understand RFC 6598 (100.64.0.0/10) vs RFC 1918 (10/8 etc.)
- Configure CGN-style pool NAT with overload
- Recognize the per-subscriber port allocation problem (for logging/compliance)
- Know the gotchas: shared public IP = shared reputation; some apps don't work behind CGN

## Theory primer

### RFC 6598 (100.64.0.0/10)
The "shared transition" range — `100.64.0.0/10` (100.64.0.0 to 100.127.255.255). Reserved for CGN use. Customers' devices get IPs from this range. It is **not** RFC 1918; it's specifically for ISP-to-customer connectivity.

Why not just use 10/8? Some customers ALSO use 10/8 internally. If their gateway is 10.0.0.1 (theirs) and your CGN-side is also 10.0.0.1, conflicts everywhere. 100.64/10 was created to avoid this.

### Port allocation
Modern CGN allocates a **range of ports** per subscriber (e.g., 1000-1100 for subscriber A, 1101-1200 for B). This is required for two reasons:
1. **Logging / Compliance**: when law enforcement asks "who was at 203.0.113.10:54321 at 14:23?", you need a deterministic answer
2. **Performance**: dynamic port allocation has high state churn at CGN scale

Hardware CGN devices implement this efficiently in silicon. cEOS doesn't have this exact mechanism, so this lab uses dynamic PAT with the assumption that production would handle allocation properly.

### NAT pool sizing
Rule of thumb in CGN: 1 public IP per ~64-128 subscribers (assuming ~500 concurrent connections per subscriber, ~65K ports). At ~1000 subs per IP, port exhaustion becomes likely.

### CGN gotchas (in production)

- **Shared reputation**: if one bad actor abuses the IP, the whole pool's reputation suffers (anti-spam blocklists, etc.)
- **Geolocation breaks**: a service trying to geolocate the IP sees the CGN's location, not the subscriber's
- **Port-forwarding impossible**: subscribers can't host services because they don't have a public IP
- **Performance**: stateful NAT requires lots of CPU/memory; production needs purpose-built CGN hardware
- **NAT-unfriendly protocols** (SIP, P2P, FTP): work poorly behind CGN

## Your task

1. Configure 2 secondary outside IPs (`203.0.113.10`, `203.0.113.11`) for the CGN pool.
2. Configure `ip nat enable` on every interface.
3. Configure a NAT pool: `CGN-POOL`, `203.0.113.10` to `203.0.113.11`.
4. ACL matching `100.64.0.0/10`.
5. Apply `ip nat source list ... pool ... overload`.
6. Verify all 3 subscribers can ping the internet, and that they're being NATed.

## Verification

```bash
docker exec clab-cgnat-sub1 ping -c 2 203.0.113.1
docker exec clab-cgnat-sub2 ping -c 2 203.0.113.1
docker exec clab-cgnat-sub3 ping -c 2 203.0.113.1
```

On the CGN:
```
show ip nat translations
```

You should see each subscriber's traffic NATed to one of the two pool IPs.

## What's missing (deliberately)

- **Deterministic per-subscriber port allocation** — needs hardware CGN
- **CGN logging** for compliance (every NAT translation logged via Netflow/sflow)
- **NAT64 + CGN combinations** — common in IPv6-transition scenarios
- **CGN HA** (active-active or active-standby pair of CGN boxes)
- **DS-Lite** (Dual-Stack Lite — IPv6-tunneled NAT44, common at ISPs)

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
