# TLS & Certificates for Network Engineers

> Every modern management protocol uses TLS. NETCONF, gNMI, gNOI, mgmt-API (HTTPS), syslog-over-TLS, RADIUS over TLS, sFlow over TLS, eventually TCP-AO for BGP. The network engineer who can't comfortably handle certificates blocks themselves out of a lot of modern operations. This doc is the practical minimum.

## Why this matters specifically for network engineers

Cert management used to be a web team problem. Now it's everyone's problem:

- **`netconf` / `gnmi`** — typically TLS-required; switch-side cert + client-side cert for mutual auth
- **Management APIs** — HTTPS only on modern platforms
- **AAA** — RADIUS-over-TLS (RadSec), TACACS+ over TLS for security-conscious deployments
- **Logging** — syslog-over-TLS (RFC 5425) for audit-compliant log shipping
- **Telemetry** — gNMI requires TLS; OpenConfig stack assumes it
- **EVPN over IPsec** — not common but exists at sensitive deployments
- **Inter-DC links** — IPsec tunnels with cert auth (not PSK) for stronger security
- **Console access** — modern console servers use certs
- **Vendor management plane** — Arista CloudVision, Cisco DNA Center, all assume cert infrastructure

Cert expiry is the single most common cause of "everything was working until Tuesday morning" outages. You will deal with this. A lot.

## Cert anatomy — what's actually on the wire

A TLS handshake involves the server (and optionally the client) presenting a **certificate chain**:

```
[Root CA] ── signs ──> [Intermediate CA] ── signs ──> [Leaf cert]
   ^                          ^                            ^
   self-signed              issued by Root            issued by Intermediate
   trusted by               (signed)                  this is what the server
   trust store                                        presents
```

Each cert contains:
- **Subject** — who this cert is for (e.g., `CN=sw1.dc.example.com`)
- **Issuer** — who signed it (the CA above it in the chain)
- **Public key** — the actual key material
- **Valid not-before / not-after** — when the cert is valid
- **Subject Alternative Names (SAN)** — additional hostnames/IPs the cert is valid for
- **Extensions** — Key Usage, Extended Key Usage (Server Auth / Client Auth / etc.)
- **Signature** — the issuer's cryptographic signature on this cert

For trust to work:
1. The leaf cert must be valid (not expired, not revoked)
2. The chain back to a Root CA must be complete
3. The Root CA must be in the verifier's **trust store**

If any link is broken, the connection fails. "It worked yesterday" usually means one of these became invalid overnight.

## The three CA realities

### 1. Public CA (Let's Encrypt, DigiCert, etc.)
For anything that the public internet needs to reach: your customer-facing portals, sometimes your DCI endpoints. Root is in every device's trust store by default. Renewal can be automated via ACME (Let's Encrypt) or manual purchase flow.

For network engineering: rarely directly relevant unless you're doing customer-facing API endpoints.

### 2. Internal CA (your own PKI)
For management plane: gNMI between switches and collector, NETCONF between automation and switches, syslog between switches and SIEM.

You stand up your own CA hierarchy. Devices need your Root CA installed in their trust store. Leaf certs are issued from your CA for each device.

**This is the common case for network engineering.** You operate your own PKI.

### 3. Self-signed certs (no CA at all)
A device generates its own cert and signs it. Trust requires either:
- Manually trusting that specific cert ("certificate pinning")
- Disabling cert verification (a.k.a. accepting the risk)

Self-signed is fine for lab work. **Not fine for production** because there's no revocation story and no scalable trust establishment.

## Internal CA setup — the minimum viable

Most network teams running an internal CA do one of these:

### Option A: HashiCorp Vault PKI
Vault has a PKI secrets engine. You configure a CA, issue certs via API. Rotates well, has ACME support, integrates with automation. Modern default for many orgs.

### Option B: step-ca / smallstep
Open-source CA designed for engineers. Simple to set up, supports ACME natively. Common in mid-size deployments.

### Option C: OpenSSL + scripts
For tiny deployments: a folder of OpenSSL configs and shell scripts. Works but doesn't scale. Renewal becomes a chore.

### Option D: AD Certificate Services / Microsoft PKI
Common in Windows-heavy enterprises. Network teams sometimes get certs from the existing Microsoft PKI rather than running their own.

### Option E: Whatever your org's security team already runs
**Check first.** Don't stand up a new PKI if there's an existing one. Politically and operationally, integrate with what's there.

## Cert lifecycle — the parts that matter

### Generation
A cert is generated from a **CSR (Certificate Signing Request)** that contains:
- The device's public key
- Subject + SAN info
- (optional) requested extensions

The CSR is signed by the CA and you get back a certificate. The private key stays on the device — it's never sent to the CA.

```bash
# Generate private key + CSR on the device
openssl req -new -newkey rsa:2048 -nodes -keyout sw1.key -out sw1.csr \
    -subj "/CN=sw1.dc.example.com" \
    -addext "subjectAltName=DNS:sw1.dc.example.com,DNS:sw1,IP:10.0.0.1"

# Send the .csr to the CA. The CA returns sw1.crt (the signed cert).
```

For network devices (Arista, Cisco, etc.), the device-side commands generate the key + CSR and import the resulting cert. Exact syntax varies; check vendor docs.

### Installation
The device needs three things in its config:
1. **The leaf cert** (signed by your CA)
2. **The private key** (paired with the cert)
3. **The CA chain** (Root + Intermediates) in the device's trust store

If you only give the leaf and forget the chain, clients can't validate. If you only give the chain and forget the leaf, the server can't present its identity.

### Renewal — the operational pain point

Certs expire. Public CAs (Let's Encrypt) issue 90-day certs. Internal CAs typically 1-3 years. Either way, you must renew before expiry — or service stops.

**Automation is non-negotiable.** Manual renewal at scale is how outages happen.

Common renewal patterns:
- **ACME (RFC 8555)**: Let's Encrypt's protocol, also supported by step-ca, smallstep, others. Device or middleware requests renewal; CA validates; new cert is installed automatically. The gold standard.
- **Script + API**: pull certs from Vault/PKI on a cron, push to devices via Ansible/Nornir.
- **Manual + calendar reminder**: small deployments. Don't lie to yourself; calendar reminders fail.

**Monitor cert expiry.** Add to your monitoring stack:
- Cert expiry < 30 days = ticket
- Cert expiry < 7 days = page
- Cert already expired = critical alert

Tools that monitor cert expiry: Blackbox exporter (Prometheus), `ssl-checker`, custom scripts using `openssl s_client`. Build it once; it watches forever.

### Revocation
A cert that's been compromised (private key leaked, device decommissioned) needs to be revoked. CAs maintain **CRL (Certificate Revocation List)** or support **OCSP (Online Certificate Status Protocol)** for real-time check.

Reality check: many internal PKIs don't actually check revocation in production. The cert just sits revoked-but-still-trusted. Make sure your verifiers (gNMI client, syslog collector, etc.) actually check CRL/OCSP if revocation matters to you.

## The CLI tools you'll use most

```bash
# Inspect a cert file
openssl x509 -in sw1.crt -text -noout

# Check expiry only
openssl x509 -in sw1.crt -enddate -noout

# Inspect the cert that a server is presenting
openssl s_client -connect sw1.dc.example.com:6030 -showcerts

# Verify a cert against a CA
openssl verify -CAfile ca.crt sw1.crt

# Test gNMI/NETCONF connection with cert auth
openssl s_client -connect sw1:6030 -cert client.crt -key client.key -CAfile ca.crt

# Generate a private key
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out sw1.key
openssl genpkey -algorithm ED25519 -out sw1.key   # modern, smaller, faster

# Generate a CSR
openssl req -new -key sw1.key -out sw1.csr -subj "/CN=sw1.dc.example.com"

# Self-signed cert (lab only!)
openssl req -x509 -newkey rsa:2048 -nodes -keyout sw1.key -out sw1.crt -days 365 \
    -subj "/CN=sw1.dc.example.com"

# Decode a CSR
openssl req -in sw1.csr -text -noout

# Convert formats
openssl x509 -in sw1.crt -outform DER -out sw1.der   # PEM → DER
openssl x509 -in sw1.der -inform DER -out sw1.crt    # DER → PEM
```

These eight or nine commands cover 80% of what you'll do. Bookmark them.

## Common gotchas

### Clock skew
TLS rejects certs valid in the future or expired. If your device's clock is wrong by an hour, certs may fail validation even if they're correct on the wire. **Always run NTP on every device** (lab 10). Cert verification breaks instantly when time is off.

### Missing intermediate certificate
The leaf is presented but the chain to the root is incomplete. Browser/client says "untrusted issuer". Fix: bundle the intermediate cert(s) in the chain, not just the leaf.

```bash
# A proper chain bundle
cat sw1.crt intermediate.crt > sw1-chain.crt
# Server presents sw1-chain.crt; client has Root CA in trust store
```

### Hostname mismatch
Cert says `CN=sw1.dc.example.com`, client connects to `10.0.0.1`. TLS may reject because the cert isn't valid for that name. Fix: include the IP in SAN, or use the hostname.

Modern TLS requires SAN (SubjectAltName), not just CN. Always include SANs.

### SNI confusion
A server hosts multiple TLS services on the same IP+port. **SNI (Server Name Indication)** in the ClientHello tells the server which cert to present. If clients don't send SNI (or send the wrong name), the server presents the default cert — which might not match what the client expects.

Less common in network management but does happen.

### Wrong key for cert
You re-imported a cert but kept the old key, or vice versa. TLS fails immediately. Check that `crt` and `key` files were generated together.

### TLS version mismatch
Old gear (or old clients) might still want TLS 1.0/1.1, which is being phased out. Modern minimum is TLS 1.2; preferred is TLS 1.3. Mismatch = no handshake.

### Long cert lifetime in production
Certs valid for 10 years feel convenient but become an operational time bomb. When that cert expires (and the person who generated it left the company 8 years ago), recovery is painful. **Prefer shorter lifetimes + reliable renewal**, not longer lifetimes.

### Certificate pinning that you forgot about
A client (often legacy automation) was hardcoded to trust ONE specific cert by fingerprint. You rotate the cert. Client breaks. Find pinning before you rotate.

### Backups of private keys
A private key has the same security value as a root password. Backup, but securely (encrypted, access-controlled). Lose the key with no backup → can't decrypt anything that used it → service interruption while rebuilding.

## TLS in specific network contexts

### NETCONF over TLS (RFC 7589)
Replaces NETCONF over SSH for environments wanting cert-based mutual auth instead of password/key.

```
management api netconf
   protocol https
   no shutdown
```

Server presents its cert; client must present a valid client cert signed by a CA the server trusts.

### gNMI / gNOI
TLS is essentially required for gNMI. Without TLS, only the laxest test setups work. Production: cert auth (mutual TLS) between collector and devices.

```
management api gnmi
   transport grpc default
      ssl profile <profile-name>
      no shutdown
   ssl profile <profile-name>
      certificate <leaf-cert>
      private-key <leaf-key>
      trust certificate <ca-cert>
```

### RadSec (RADIUS over TLS, RFC 6614)
Replaces UDP-based RADIUS with TLS-over-TCP. Solves the shared-secret weakness of plain RADIUS. Less common but growing.

### TACACS+ over TLS (RFC 8907)
Newer TACACS+ standard adds TLS as transport. Modern Arista, Cisco, Juniper support it. Strong recommendation over plain TACACS+ for new deployments.

### Syslog over TLS (RFC 5425)
Encrypted log shipping. Useful where logs go cross-network or contain sensitive info.

```
logging vrf MGMT host 10.99.0.50 protocol tls trustpoint MyCA
```

### sFlow / IPFIX over TLS
Some platforms support encrypted flow export. Useful when flows traverse untrusted networks.

## A 30-minute internal PKI sketch for a small DC

If your network team needs to start managing internal certs and there's no PKI yet:

1. Install **step-ca** on a hardened host. Generate a root + intermediate.
2. Document the root CA's fingerprint somewhere durable (wiki, secret manager).
3. Distribute the Root CA to every network device's trust store. Automation via Ansible.
4. Set up ACME on step-ca. Devices request certs via ACME (where supported) or via your automation pulling from the API.
5. Set leaf cert lifetime to 30-90 days.
6. Monitor cert expiry via your Prometheus / monitoring stack.
7. Test the entire renewal pipeline by manually expiring a cert in a lab; verify auto-renewal works.

That's an MVP. It will need to grow (HA, audit logging, key ceremony, revocation discipline) — but it gets you off "self-signed everywhere" or "no cert management at all" without months of work.

## What this doc deliberately doesn't cover

- **Web TLS / browser-facing certs** — different audience.
- **Code signing certs** — different problem.
- **PKI deep cryptography (X.509 bit-level details, algorithm choice)** — useful but a separate course.
- **HSM / FIPS / regulated environments** — niche; consult specialists when needed.
- **Mutual TLS authentication design at scale** — touched on; deeper deployment patterns are advanced.

## TL;DR

- Every modern management protocol uses TLS. Network engineers handle certs daily now.
- Cert chain = leaf → intermediate(s) → root. All must be present and valid.
- Internal CA is the common case for network ops. Standardize on one (Vault PKI, step-ca, whatever).
- **Automate renewal.** Manual is how you build a future outage.
- **Monitor expiry.** Alert before things break.
- Common gotchas: clock skew, missing intermediates, hostname mismatch, wrong key, pinned-and-forgot.
- Know your 8-9 openssl commands by heart.

---

**Story-arc references**:
- Phase 3 (lab 10): you set up NTP. Without accurate time, TLS breaks instantly. The link between these is real.
- Phase 5 (BGP operations, lab 26): TCP-AO is an option for BGP session auth — uses keying material similar to TLS in spirit. Not commonly deployed yet, but coming.
- Phase 6 (DC fabric): gNMI streaming telemetry to a collector — TLS-required in any production deployment. Lab 46 / lab 50 in the roadmap touch this.
- Phase 7-9 (planned ops chapter): TACACS+ over TLS, syslog over TLS, RadSec — all moving from "interesting" to "expected".
