# Starter: site B MikroTik (mirror of site A).

/system identity set name=rtr-b

/ip address
add address=198.51.100.2/30 interface=ether1 comment="WAN"
add address=10.20.20.1/24   interface=ether2 comment="LAN"

/ip route
add dst-address=0.0.0.0/0 gateway=198.51.100.1 comment="default via WAN"

# ── Your tasks: mirror image of rtr-a. Build the other end of
# the WireGuard tunnel; allowed-addresses includes 10.10.10.0/24
# and the wg transport network. Wg local address 172.16.0.2/30.
