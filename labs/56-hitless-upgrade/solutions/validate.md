# Reference runbook + validation — Lab 56

This is the worked reference for the drain → "upgrade" → validate → undrain
exercise. The configs in this directory (`leaf1.cfg`, `leaf2.cfg`, `spine.cfg`)
are what the topology's `configs/` already ship; they're reproduced here as the
reference answer.

## Why the demo is hitless

- **Shared gateway**: both leaves carry `ip virtual-router address 10.10.10.1`
  on `Vlan10` plus the same `ip virtual-router mac-address`. Either leaf will
  ARP-reply for `10.10.10.1` with the shared virtual MAC, so the host's default
  gateway does not depend on a single leaf.
- **One L2 domain**: `Ethernet1` (the peer-link) is an 802.1Q trunk carrying
  VLAN 10, so `leaf1:Eth3` and `leaf2:Eth3` are in the same broadcast domain.
- **Host bond**: the host bonds `eth1+eth2` into `bond0` (active-backup), so it
  presents one MAC/IP and uses whichever uplink is up.

When `leaf1:Eth3` is shut, `bond0` fails over to `eth2` (→ leaf2). leaf2 already
owns `10.10.10.1`, so the host keeps reaching its gateway. Frames that need to
cross between leaves do so over the VLAN-10 trunk on the peer-link.

## PRE — capture pre-state

On a leaf:

```
show ip interface brief        # Vlan10 up, virtual address shown
show ip virtual-router         # 10.10.10.1 active on Vlan10
show vlan                      # VLAN 10 present, trunked on Et1
show ip bgp summary            # peer to spine Established; prefixes exchanged
show interfaces Ethernet3 counters   # baseline packet counts
```

On the spine:

```
show ip bgp summary            # both leaf peers Established
show ip route 10.10.10.0/24    # learned via BOTH leaves (ECMP, maximum-paths 2)
```

> Note: there is **no MLAG and no EVPN** in this lab (gateway redundancy is VARP,
> not MLAG). `show mlag` / `show evpn` are part of the *general* fleet runbook in
> the README and are intentionally out of scope here — they will return nothing.

## STEP A — "upgrade" leaf1

```
# A1. Drain leaf1
leaf1# configure
leaf1(config)# interface Ethernet3
leaf1(config-if-Et3)# shutdown

# A2. Verify host still reaches the gateway (run on the host):
#   ping -i 0.1 10.10.10.1     -> still flowing (bond failed over to eth2/leaf2)

# A3/A4. Save + "reload" (in the lab, restart the container):
leaf1# copy running-config startup-config
#   then from the lab VM:  sudo containerlab restart -n leaf1  (or docker restart clab-hitless-upgrade-leaf1)

# A6. Validate after boot:
leaf1# show ip interface brief
leaf1# show ip virtual-router
leaf1# show ip bgp summary

# A7. Undrain
leaf1# configure
leaf1(config)# interface Ethernet3
leaf1(config-if-Et3)# no shutdown
```

## STEP B — repeat for leaf2

Same sequence, draining `leaf2:Ethernet3`.

## Expected result

`ping -i 0.1 10.10.10.1` from the host loses **0–2 packets per transition**
(one each side of the bond failover). It does **not** stop.
