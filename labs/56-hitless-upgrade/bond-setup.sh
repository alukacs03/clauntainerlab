#!/bin/bash
# Host-side setup for lab 56.
#
# Bond eth1 + eth2 into bond0 (active-backup). This makes the host a single
# logical L2 endpoint with one MAC and one IP, dual-homed to leaf1 and leaf2.
# active-backup uses whichever member link is currently up — no LACP / no
# switch-side port-channel required — so when one leaf is drained (its access
# port shut), the bond fails over to the other member and the ping survives.
set -e

modprobe bonding 2>/dev/null || true

ip link add bond0 type bond mode active-backup miimon 100 2>/dev/null || true

ip link set eth1 down
ip link set eth2 down
ip link set eth1 master bond0
ip link set eth2 master bond0
ip link set eth1 up
ip link set eth2 up
ip link set bond0 up

ip addr add 10.10.10.10/24 dev bond0
ip route add default via 10.10.10.1
