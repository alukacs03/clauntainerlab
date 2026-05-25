# The L2 Security Binding Table

> One table, three features. Understanding the DHCP snooping binding table makes DHCP snooping, Dynamic ARP Inspection, and IP Source Guard click as a single mechanism rather than three separate ones.

## What the binding table is

The **DHCP snooping binding table** is a list of entries the switch maintains by watching DHCP traffic on each access port. Each entry records:

```
MAC address     IP address      VLAN    Port           Lease expiry
aa:bb:cc:11:22  10.10.10.123    10      Et3            2024-08-15 14:32:00
```

The table is built passively — the switch doesn't grant or deny leases, it just **observes** the legitimate DHCP exchange between client and server and records the outcome.

## Why this table is the foundation

Three different L2 anti-spoofing features all rely on the same binding table:

```
                    ┌─→ DHCP Snooping
                    │   (drops server messages on untrusted ports;
                    │    populates the binding table)
                    │
DHCP snooping ──────┼─→ Dynamic ARP Inspection (DAI)
binding table       │   (validates every ARP packet on untrusted ports
                    │    against the binding table)
                    │
                    └─→ IP Source Guard (IPSG)
                        (validates source IP of every IP packet on
                         untrusted ports against the binding table)
```

Each feature adds a filter on a different traffic class (DHCP server msgs, ARPs, IP source addresses), all consulting the same `(MAC, IP, port)` truth.

## How an entry appears

1. **DHCPDISCOVER** — client (MAC `aa:bb:cc:11:22`) on port Et3 broadcasts request. Switch sees the source MAC + ingress port + VLAN.
2. **DHCPOFFER** — server (on trusted port, e.g. Et1) replies with `10.10.10.123` lease for 12 hours. Switch sees the IP being offered.
3. **DHCPREQUEST → DHCPACK** — exchange completes. **Now the switch installs the binding**: `MAC=aa:bb:cc:11:22, IP=10.10.10.123, VLAN=10, Port=Et3, Expires=12h`.

The binding remains while the lease is valid. Renewals reset the timer. DHCPRELEASE removes the entry.

## How the entry is used

### By DHCP snooping itself
The binding table isn't *used* by DHCP snooping for its primary job (filtering rogue server messages). Snooping is a forward-only filter on ports. The binding table is a **side-product** of snooping — but it's the side-product that makes DAI and IPSG possible.

### By DAI

Every ARP packet on an untrusted port is examined:
- **ARP sender's claimed `(MAC, IP)` pair** is extracted from the ARP body.
- That pair is looked up in the binding table for this port + VLAN.
- **Match** → forward the ARP normally.
- **No match** → drop the ARP, log it, optionally err-disable the port.

This stops ARP spoofing: a host on port Et3 (bound to `10.10.10.123`) cannot send a gratuitous ARP claiming to own `10.10.10.1` (the gateway), because no binding for that MAC/IP exists.

### By IPSG

Every IP packet on an untrusted port:
- The source IP (and optionally source MAC) of the packet is checked.
- Lookup in binding table for this port: does any entry exist with `IP=<packet's source IP>` and (if MAC checking is on) `MAC=<packet's source MAC>`?
- **Match** → forward.
- **No match** → drop.

Result: a host bound to `10.10.10.123` cannot send packets sourced from `10.20.20.50` (a server's IP). Source IP spoofing is blocked at the access layer.

## Trust model

The binding table only contains entries for **untrusted** ports — i.e., access ports where clients live. Trusted ports (server-facing, inter-switch trunks) skip both DAI and IPSG inspection entirely.

The trust model:
- **Trusted ports**: DHCP servers, uplinks to other switches, anything you administratively control end-to-end.
- **Untrusted ports**: end-user access ports, customer ports, "wall jacks". Where attackers might appear.

## Static entries — when DHCP isn't used

Some hosts have **static IPs** (servers, network gear, IoT devices). They never make DHCP requests, so no binding gets created automatically. With DAI/IPSG on their port, ARPs and traffic would be blocked.

Solution: add **manual binding entries**:

```
ip source binding aa:bb:cc:99:88:77 vlan 10 10.10.10.250 interface Ethernet5
```

This tells the switch "trust this MAC/IP/port combination as if it came from DHCP". DAI accepts the host's ARPs and IPSG accepts its traffic.

Best practice: maintain manual bindings in your config-management system, not ad-hoc.

## Persistence — surviving reboots

The binding table is **runtime state** — it's lost on switch reload. After a reboot, no bindings exist; legitimate DHCP-leased hosts can't pass traffic until they renew (which can take minutes to hours, depending on lease duration).

Mitigations:

- **Persist the binding table to flash**:
  ```
  ip dhcp snooping database flash:dhcp-snooping.db
  ```
  The switch saves the binding table to local storage every few minutes. After a reboot, it's reloaded.

- **TFTP/FTP backup** — for redundancy, save the binding DB to a network location.

Without persistence, planning maintenance windows means scheduling them when most leases will renew soon — which is usually not possible.

## Sizing & operational concerns

- **Table size limits** — every platform has a maximum binding count. Access switches with thousands of clients can approach the limit. Check the data sheet.
- **DHCP renewal load** — every renewal updates the binding. High lease churn → high CPU. Tune lease duration appropriately.
- **DAI rate-limiting** — a single host can ARP at packet rates that exhaust the switch's CPU for DAI lookups. Default rate limits err-disable noisy ports; tune for legitimate high-ARP scenarios (routers, network appliances).
- **Multi-VLAN ports (trunks)** — bindings are per-(VLAN, port). A trunked port can have bindings in many VLANs.

## How this maps to IPv6

IPv6 has the same problem (rogue RAs, ND spoofing, IP source spoofing), solved by an analogous family of features built on a parallel **IPv6 binding table**:

- **DHCPv6 snooping** — same idea as DHCP snooping.
- **IPv6 ND inspection** — equivalent of DAI but for IPv6's NDP.
- **IPv6 Source Guard** — equivalent of IPSG.
- **RA Guard** — blocks rogue Router Advertisements (no v4 equivalent because there's no RA in v4).

Same trust model, same binding-table foundation. Configure both v4 and v6 in modern dual-stack environments.

## Common gotchas

- **Enabling DAI/IPSG before DHCP snooping** → no binding table exists → everything drops or everything allows (depending on default). **Always enable snooping first**, let the table populate, then turn on DAI and IPSG.
- **Forgetting trust on the DHCP server port** → server's DHCPOFFER messages get dropped → no leases issued → no binding entries → cascading failure.
- **Forgetting trust on inter-switch trunks** → ARPs and traffic from clients on the other switch get inspected without a local binding → all dropped.
- **Static hosts without manual bindings** → break under DAI/IPSG. Document all static hosts.
- **Voice phones (CDP/LLDP-discovered)** → typically need bindings for both PC MAC (DHCP-acquired) and phone MAC (static or DHCP-acquired in voice VLAN). Two bindings per port.
- **Binding table loss on reboot** → enable persistence.

## Where this matters in the lab series

- **Lab 07** — the trifecta in action.
- **IPv6 deployment lab (Ch 8)** — DHCPv6 snooping + ND inspection + IPv6 Source Guard + RA Guard.
- **802.1X / NAC** (future) — replaces the DHCP-based identity assumption with explicit per-port authentication.
