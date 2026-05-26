# Reference solution — site A.
# Shows both: (1) WireGuard, (2) IPsec site-to-site as an alternative.
# In production you'd pick ONE. WireGuard is preferred for new deployments;
# IPsec is shown here because that's what 99% of legacy partner connections use.

/system identity set name=rtr-a

/ip address
add address=198.51.100.1/30 interface=ether1 comment="WAN"
add address=10.10.10.1/24   interface=ether2 comment="LAN"

/ip route
add dst-address=0.0.0.0/0 gateway=198.51.100.2 comment="default via WAN"

# ════════════════════════════════════════════════════════════════
# Option 1 — WireGuard (preferred for new deployments)
# ════════════════════════════════════════════════════════════════

# Generate a keypair (RouterOS generates one automatically on iface create)
/interface wireguard
add name=wg-to-b listen-port=51820 \
    private-key="REPLACE_WITH_GENERATED_PRIVATE_KEY"
    # In practice: `add name=wg-to-b listen-port=51820` and RouterOS
    # auto-generates the key. Then `/interface wireguard print` to read
    # the public key; share that with the other side.

# IP on the transport
/ip address add address=172.16.0.1/30 interface=wg-to-b

# Peer (the other side's public key — get from rtr-b's output)
/interface wireguard peers
add interface=wg-to-b \
    public-key="REPLACE_WITH_RTR_B_PUBLIC_KEY" \
    endpoint-address=198.51.100.2 \
    endpoint-port=51820 \
    allowed-address=172.16.0.0/30,10.20.20.0/24 \
    persistent-keepalive=25s

# Route to remote LAN via the tunnel
/ip route
add dst-address=10.20.20.0/24 gateway=172.16.0.2 comment="to site B LAN"

# Firewall: allow WG UDP/51820 inbound
/ip firewall filter
add chain=input action=accept protocol=udp dst-port=51820 in-interface=ether1 comment="WireGuard"

# ════════════════════════════════════════════════════════════════
# Option 2 — IPsec site-to-site (IKEv2, PSK)
# Shown for completeness; comment out Option 1 if using this.
# ════════════════════════════════════════════════════════════════

# /ip ipsec profile
# add name=site-to-b enc-algorithm=aes-256 hash-algorithm=sha256 dh-group=modp2048
#
# /ip ipsec peer
# add name=rtr-b address=198.51.100.2/32 profile=site-to-b exchange-mode=ike2
#
# /ip ipsec identity
# add peer=rtr-b auth-method=pre-shared-key secret="LONG-RANDOM-PSK-HERE"
#
# /ip ipsec proposal
# add name=site-to-b enc-algorithms=aes-256-gcm pfs-group=modp2048
#
# /ip ipsec policy
# add peer=rtr-b src-address=10.10.10.0/24 dst-address=10.20.20.0/24 \
#     tunnel=yes proposal=site-to-b
#
# /ip firewall filter
# add chain=input action=accept protocol=udp dst-port=500,4500 in-interface=ether1
# add chain=input action=accept protocol=ipsec-esp in-interface=ether1
