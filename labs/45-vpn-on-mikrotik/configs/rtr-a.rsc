# Starter: site A MikroTik. WAN on ether3, LAN on ether2.
# Your task: build a WireGuard tunnel to rtr-b and route 10.20.20.0/24 over it.

/system identity set name=rtr-a

/ip address
add address=198.51.100.1/30 interface=ether3 comment="WAN"
add address=10.10.10.1/24   interface=ether2 comment="LAN"

/ip route
add dst-address=0.0.0.0/0 gateway=198.51.100.2 comment="default via WAN"

# ── Your tasks: ──
# 1. Create a WireGuard interface "wg-to-b" with a fresh private key
# 2. Add peer for rtr-b (its public key, endpoint 198.51.100.2:51820,
#    allowed-addresses 10.20.20.0/24 and the wg link transport network)
# 3. Address the wg interface (172.16.0.1/30)
# 4. Add a route for 10.20.20.0/24 via the wg interface
# 5. (Optional) Build an IPsec site-to-site as an alternative — config in
#    the solutions/ shows both
