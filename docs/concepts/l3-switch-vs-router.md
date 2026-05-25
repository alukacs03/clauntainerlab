# L3 Switch vs. Router

> When does an L3 switch stop being a switch and start being a router? Honest answer: it's a spectrum, and modern hardware has blurred the line into a smudge. Here's the mental model that actually helps.

## The textbook distinction (still useful, but dated)

The classical separation:

| Aspect | L2 switch | L3 switch | Router |
|---|---|---|---|
| Primary job | Forward frames inside a broadcast domain | Forward frames *and* route between VLANs / subnets in the LAN | Route between networks, typically across boundaries (WAN, internet, branch) |
| Forwarding plane | L2 ASIC (MAC table lookups) | L2 ASIC + L3 lookup tables (often in hardware) | CPU-driven or specialized routing ASIC, optimized for variety over raw speed |
| Port density | High (24, 48, 96+) | High (same as L2) | Low (2–8 is common) |
| Cost per port | Low | Low–moderate | High |
| Interface types | Ethernet only | Ethernet only | Ethernet + historically serial, T1/E1, ATM, dialer, tunnels, MPLS-tagged links, GRE, IPsec virtual… |
| Feature set | MAC learning, VLANs, STP | + Static routing, OSPF/EIGRP, SVIs, VRFs (basic) | + Deep NAT, advanced ACLs, IPsec/VPN, BGP at internet-edge scale, policy routing, MPLS-VPN, QoS classes, traffic-shaping |
| Typical role | Access layer | Distribution / core / DC top-of-rack | Edge / WAN / internet gateway |
| "Up" model for L3 interfaces | n/a | SVIs (per-VLAN) + routed ports | Physical L3 interfaces + virtual (tunnels etc.) |

## Where the distinction comes from historically

In the 1990s, switching and routing were genuinely different things on genuinely different boxes:

- **Switches** were L2 ASIC engines: fast, dumb, MAC table only. Cheap silicon, one job.
- **Routers** were general-purpose CPUs running software (think Cisco IOS on a MIPS chip). Slower per packet, but they could do anything you could write in code: NAT, encryption, exotic protocols.

When customers wanted "ping between VLANs without buying a router for every closet", vendors built **L3 switches**: take a switch's L2 ASIC and bolt on a (limited) L3 lookup table in hardware. The result: line-rate IP forwarding for the common case (LAN, simple routes), but missing the router's flexibility (no NAT/IPsec/policy stuff, or only basic versions).

So historically:
- **L3 switch** = "switch that can route a bit, very fast, in the LAN"
- **Router** = "general-purpose packet processor, flexible, at the network edge"

## What changed: hardware blurred the line

Modern devices have eroded this neatly:

- **L3 switches got smarter.** A modern Arista 7280/Cisco Catalyst 9500 / Nexus 9000 runs BGP at internet-scale, holds full DFZ routing tables (~1M routes), does VXLAN/EVPN, advanced QoS, and sits at the actual internet edge of large DCs. By the textbook, it's "a switch"; by function, it's a router.
- **Routers got switch-like density and speed.** Cisco Catalyst 8000 series, Juniper MX series — these are "routers" with 100G/400G ports and switch-like throughput. They keep router-grade feature depth (MPLS, IPsec, NAT at scale) but no longer feel slow or low-density.
- **Both run the same protocols.** OSPF, BGP, IS-IS, VRRP — every L3 device speaks them. There's no protocol that says "router only".

So the modern question isn't "router or switch?" but **"what mix of features and forwarding behavior does this box implement?"**

## Practical signals: which one is this thing, really?

Forget the badge on the front. Ask:

1. **What's its forwarding silicon optimized for?**
   - "Lots of MAC entries, line-rate L2/L3 between VLANs, but limited deep-packet features" → switch ancestry.
   - "Rich per-packet processing, NAT/IPsec/QoS classes, but lower aggregate Gbps" → router ancestry.

2. **What lives on it in production?**
   - VLANs, SVIs, VXLAN, EVPN, MLAG → switch role.
   - NAT, IPsec tunnels, BGP peering with ISPs, MPLS L3VPN PE → router role.
   - Both → modern hybrid; the labels stop helping.

3. **Where is it in the topology?**
   - Inside a building/DC, with lots of end hosts hanging off it → switch role.
   - At the boundary between administrative domains (your network ↔ ISP, branch ↔ HQ) → router role.

4. **What interface zoo does it support?**
   - Only Ethernet variants → almost certainly a switch.
   - Cellular, serial, ADSL, tunnels, dialers → definitely a router.

## A useful definition

> An **L3 switch** routes between subnets/VLANs *inside a Layer-2 fabric it also runs*. Its job is moving traffic around the LAN at wire speed, with routing as an integrated feature.
>
> A **router** routes between *distinct networks*, often across administrative boundaries, applying policy (NAT, ACLs, encryption, QoS) as it does so. Its job is being the deliberate, feature-rich gateway between domains.

Most concrete boxes do both to some degree. Which one we *call* it depends on the role it plays in the design, not the silicon inside.

## Back to your lab

In lab 02, sw1 has:
- VLANs and trunks (switching)
- SVIs with IPs, `ip routing` enabled (routing between VLANs)
- No NAT, no tunnels, no BGP, no WAN-style interfaces

That's a textbook **L3 switch** role. If you bolted a public IP, a NAT rule, and an IPsec tunnel to your branch office onto the same box, it would start *acting like* a router as well. Same hardware, different role.

## TL;DR

- Historically: switches = fast & cheap L2, routers = flexible L3 + features. Clear separation.
- Today: modern boxes do both. The hardware distinction has blurred.
- Mental model: think **role**, not **product category**. A device is a "router" when it's gateway-ing between networks with policy. It's an "L3 switch" when it's mainly moving LAN traffic with routing as an integrated convenience. Many devices do both at once.
- In labs: a single cEOS node running `ip routing` + SVIs is functionally a router for our purposes. We call it an L3 switch because that's the role it plays in this topology (inside-LAN inter-VLAN routing) — not because the silicon is fundamentally different from a "real" router.
