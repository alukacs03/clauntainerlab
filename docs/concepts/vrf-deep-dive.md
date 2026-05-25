# VRF Deep-Dive

> A VRF is "a routing table". Easy. But understanding *why* you'd run more than one routing table on a single box — and how they interact, or deliberately don't — unlocks management VRF, multi-tenant DC, MPLS L3VPN, EVPN, and more.

## The single-routing-table assumption

A normal router has one routing table. Every interface contributes a connected route. Every static or dynamic route lands in the same table. Lookups: source IP irrelevant, destination IP determines next-hop. Simple.

This breaks when you need:

- **Management traffic** that mustn't share fate with data (lab 08).
- **Multiple customers** whose IP spaces overlap (Customer A and Customer B both use `10.0.0.0/8`).
- **Service chaining** where the same flow needs different routing on different segments.
- **Migration scenarios** where two networks must coexist before merging.

A single routing table can't model these. VRFs can.

## What a VRF actually is

A **VRF (Virtual Routing and Forwarding)** instance is everything a router needs to be a router, but instantiated multiple times in the same box:

| Component | Per-VRF? |
|---|---|
| Routing table (RIB) | Yes |
| Forwarding table (FIB) | Yes |
| ARP / neighbor cache | Yes |
| Connected routes (from interfaces) | Yes |
| Static routes | Yes |
| Routing protocol instances (OSPF/BGP/etc.) | Yes — each VRF can run its own OSPF process, BGP address-family, etc. |
| MAC table | **No** — L2 is independent of L3; MAC tables are per-VLAN or per-bridge, not per-VRF |
| Interface assignment | An interface belongs to **exactly one VRF** at a time |

A device with 5 VRFs is functionally **5 independent virtual routers** sharing the same physical hardware.

## The default VRF

There's always a default VRF. If you don't explicitly put anything in a named VRF, it's in the default VRF. Default VRF is named differently on different platforms (Cisco: `default`, Arista: `default`, sometimes just unnamed).

Traffic in the default VRF cannot reach VRF A by default. They're isolated.

## Inter-VRF communication

Two VRFs on the same box can talk only if you explicitly allow it. Mechanisms:

### 1. Static routes pointing across VRFs

```
ip route 10.20.0.0/24 vrf MGMT next-hop-vrf DATA 10.10.0.1
```

"In VRF MGMT, route 10.20.0.0/24 via 10.10.0.1 in VRF DATA." Crude but works.

### 2. Route leaking with route-targets

In BGP-based VRF designs (VPNv4 / MPLS L3VPN / EVPN), each VRF has:

- **Route Distinguisher (RD)** — prefix that makes the VRF's routes globally unique in BGP. Customer A's `10.0.0.0/24` becomes `RD-A:10.0.0.0/24`; Customer B's `10.0.0.0/24` becomes `RD-B:10.0.0.0/24`. Now BGP can carry both without collision.
- **Route Target (RT) — export** — when this VRF announces a route, it tags it with this RT.
- **Route Target (RT) — import** — this VRF accepts routes tagged with this RT.

To leak Customer A's routes to a "shared services" VRF:
- Customer A VRF exports RT `64512:100`
- Shared services VRF imports RT `64512:100`

The shared services VRF now sees Customer A's routes in its own RIB.

This is the **mechanism behind all modern VRF route leaking**. Same scheme for MPLS L3VPN and for EVPN VRFs.

### 3. Stitching at L4 (firewalls, load balancers)

A firewall with one interface in VRF A and another in VRF B effectively bridges them at the policy layer. Common in shared-services designs.

## RD vs RT — clearing up the confusion

Both are 8-byte values, both look like `ASN:NUMBER`, both relate to VRF identity in BGP.

- **RD makes a prefix globally unique** in BGP. Without RD, Customer A and B's overlapping `10.0.0.0/24` would collide.
- **RT controls which VRFs see which routes**. Independent of RD. Many VRFs can share an RT.

Common pattern: RD per VRF (unique), RT shared across VRFs that should see each other's routes.

## Common VRF designs

### Management VRF

One named VRF (e.g. `MGMT`) for the device's management interface and all management services (SSH, SNMP, NTP, syslog, AAA). Everything else stays in default VRF.

**Why**: data-plane mistakes can't kill the management session. See lab 08.

### Customer VRFs (multi-tenant)

One VRF per customer. Each customer's interfaces and routes live in their own world. Overlapping IPs are fine. Inter-customer leaking only via explicit route policy.

Used by every cloud/hosting provider that offers VPC-like isolation.

### Internet VRF + Internal VRF

Public-facing interfaces in one VRF (`INTERNET`), internal/private in another (`INTERNAL`). NAT bridges them. Cleaner than a single table with `ip vrf forwarding` boundaries.

### VRF-Lite vs MPLS L3VPN vs EVPN VRFs

| | VRF-Lite | MPLS L3VPN | EVPN VRFs |
|---|---|---|---|
| Multi-device VRFs | Yes, via static or per-VRF protocol instance | Yes, via MP-BGP with VPNv4 | Yes, via MP-BGP with EVPN family |
| Underlay | Whatever you have | MPLS LSPs | Routed IP (with VXLAN/MPLSoUDP/SR) |
| Scale | OK for small numbers of VRFs | Service-provider scale | Datacenter scale, replacing MPLS L3VPN in DC |
| Complexity | Low | Medium-high | Medium |

**VRF-Lite** = "VRFs on standalone devices, no fancy BGP signaling, just configure each device". Fine for a few VRFs.

**MPLS L3VPN** = the classic SP design. PEs run MP-BGP to exchange VPNv4 routes; MPLS labels carry traffic across the core.

**EVPN** = the modern DC equivalent. Uses BGP-EVPN to exchange routes (Type 5 for L3, Type 2 for L2). Same RD/RT concepts.

## VRF-aware services

Every service that sources or terminates traffic needs to know its VRF:

| Service | How to make it VRF-aware |
|---|---|
| SSH server | `management ssh` → `vrf MGMT` block |
| SNMP | `snmp-server vrf MGMT` |
| NTP client | `ntp server <ip> vrf MGMT` |
| Syslog | `logging vrf MGMT host <ip>` |
| RADIUS / TACACS | `radius-server host <ip> vrf MGMT` / `tacacs-server host <ip> vrf MGMT` |
| BGP | `router bgp <asn>` → `vrf <name>` sub-block, with its own neighbors |
| OSPF | `router ospf <id> vrf <name>` |
| Ping/Traceroute | `ping vrf <name> <ip>` |
| DHCP relay | `ip helper-address <ip> vrf <name>` |

Forgetting to specify the VRF → service tries default VRF, fails silently.

## Operational reflex: "which VRF am I in?"

When something doesn't work, the first question is often **which VRF is this on?** Check:

```
show vrf
show ip route vrf <name>
show ip interface vrf <name> brief
show ip arp vrf <name>
```

If the answer is "I forgot to put X in VRF Y", the symptom is usually "X reaches local stuff but not what I expected".

## VRF on Linux (briefly)

Linux supports VRFs too:

```bash
ip link add MGMT type vrf table 10
ip link set dev eth1 master MGMT
ip route add 10.0.0.0/24 dev eth1 vrf MGMT
```

Same concept. Useful for host-based services that need to bind to a specific VRF.

## Common gotchas

- **Moving an interface between VRFs drops its IP.** Always reapply after `vrf forwarding ...`.
- **Per-VRF protocol instances don't share routes by default**. OSPF in VRF A and OSPF in VRF B are entirely separate processes. Route leaking is explicit, never implicit.
- **VRF names are case-sensitive on most platforms.** "Mgmt" ≠ "MGMT".
- **Don't use VRF for QoS or "soft isolation"** — VRFs are a routing concept, not a security or QoS feature. For data-plane policing, use ACLs/QoS policies.
- **Inter-VRF NAT** — possible but tricky. Each direction of the flow lives in different VRFs; NAT must handle both correctly.

## Where this matters in the lab series

- **Lab 08** — Management VRF (foundational use case).
- **Lab 09** — TACACS in mgmt VRF.
- **Lab 10** — Syslog/NTP/AAA all in mgmt VRF.
- **Lab 11** — OOB management built on mgmt VRF.
- **Chapter 6 (BGP)** — Per-VRF BGP, route leaking via RT.
- **Chapter 7 (EVPN)** — Tenant VRFs, distributed anycast gateway per VRF, EVPN Type 5 for L3 overlay.
