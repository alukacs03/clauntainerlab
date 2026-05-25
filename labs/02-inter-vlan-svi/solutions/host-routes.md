# Host default-gateway routes (lab 02 solution)

Run these from the VM after sw1's SVIs are configured. Each host gets a route to the *other* VLAN's subnet via its SVI gateway on sw1.

```bash
# Hosts in VLAN 10 (h1, h3) → reach VLAN 20 via 10.10.10.254
docker exec clab-inter-vlan-svi-h1 ip route add 10.20.20.0/24 via 10.10.10.254
docker exec clab-inter-vlan-svi-h3 ip route add 10.20.20.0/24 via 10.10.10.254

# Hosts in VLAN 20 (h2, h4) → reach VLAN 10 via 10.20.20.254
docker exec clab-inter-vlan-svi-h2 ip route add 10.10.10.0/24 via 10.20.20.254
docker exec clab-inter-vlan-svi-h4 ip route add 10.10.10.0/24 via 10.20.20.254
```

Why a specific route and not `default via`: the hosts already have a default route via `eth0` for the containerlab management network (`172.20.20.0/24`). Overriding the default would lose mgmt connectivity. A specific `/24` route to the other VLAN is more precise and keeps everything else intact.
