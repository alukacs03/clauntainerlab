# Reference solution — site B (mirror).

/system identity set name=rtr-b

/ip address
add address=198.51.100.2/30 interface=ether1
add address=10.20.20.1/24   interface=ether2

/ip route
add dst-address=0.0.0.0/0 gateway=198.51.100.1

# ── WireGuard ──
/interface wireguard
add name=wg-to-a listen-port=51820 private-key="REPLACE_WITH_GENERATED"

/ip address add address=172.16.0.2/30 interface=wg-to-a

/interface wireguard peers
add interface=wg-to-a \
    public-key="REPLACE_WITH_RTR_A_PUBLIC_KEY" \
    endpoint-address=198.51.100.1 \
    endpoint-port=51820 \
    allowed-address=172.16.0.0/30,10.10.10.0/24
    # Both ends public here, so no keepalive. Add `persistent-keepalive=25s`
    # only if this end is behind NAT (see rtr-a solution for the rationale).

/ip route
add dst-address=10.10.10.0/24 gateway=172.16.0.1

/ip firewall filter
add chain=input action=accept protocol=udp dst-port=51820 in-interface=ether1
