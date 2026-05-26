# Lab 44 — Load Balancing Patterns

> **Format:** Hands-on. Build network-layer load balancing: three backends each announce the same VIP via BGP, the router installs all three as ECMP paths, traffic is hashed across them. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 8 · Senior+ · Year 4–5. A customer's web service is outgrowing one backend VM. They could buy a hardware load balancer (expensive). Or — since they're already running BGP for their hosted service — they can let the **network** do the load balancing for them via ECMP. This is the same pattern that lets Cloudflare have 1.1.1.1 served from thousands of machines. See [`STORY.md`](../../STORY.md).
>
> **Note:** Uses FRR on the backend hosts (not cEOS) — that's realistic; Linux servers running BGP daemons (FRR, BIRD, GoBGP) is the production pattern.

## Real-world scenario

You have a service that needs to scale horizontally. Three common approaches:

1. **Dedicated load balancer (HAProxy / F5 / NetScaler / Envoy)**: a box (or VM) in front of the backends that does L4 or L7 LB. Stateful, sees every flow, can do health-checks, SSL termination, content rules.
2. **DNS round-robin**: client gets a different A record each query. Cheap but coarse — clients cache, no health checks, fail-over is slow.
3. **Network-layer (this lab)**: every backend announces the same VIP via BGP. Router installs all paths as ECMP. Traffic is hashed (5-tuple) across backends.

When is option 3 the right call?
- **High throughput, low LB intelligence needed**: you don't need L7 routing, just spread traffic.
- **Stateless services**: DNS resolvers, NTP, anycast HTTP CDN edge.
- **The backends already speak BGP**: if you're running BGP for your hosted service, you've already paid the cost.
- **You want to avoid an LB SPOF**: ECMP across N backends is inherently redundant.

When option 3 is wrong:
- **Stateful flows** that must stick to a backend (login sessions): need session affinity. Hard with stateless ECMP unless you do consistent hashing (Maglev, Katran).
- **L7 routing decisions** (path-based routing, header rules): need an L7 LB.
- **Health-check granularity**: BGP session up != backend healthy. The backend can be running BGP fine but serving 500s.

In practice: combine. ECMP across multiple LBs, each LB does L7 in front of its backend pool. That's how Google, Cloudflare, AWS work.

## Goal

- Three backends announce the same VIP `10.99.99.1/32` via eBGP
- Router installs all three as ECMP paths
- Verify traffic distributes across all three
- Verify automatic re-hashing when a backend's BGP session drops

## Theory primer

### ECMP — Equal-Cost Multi-Path

When the routing table has multiple equal-cost paths to a destination, the router can install all of them. For each flow, hash the 5-tuple (src IP, dst IP, src port, dst port, proto) to pick a path. Flows are sticky (same flow → same path), but different flows distribute.

Default Arista EOS will only install one BGP-learned path per prefix. To enable ECMP:
```
router bgp 65000
   maximum-paths 4 ecmp 4
   bgp bestpath as-path multipath-relax    ! for eBGP from different ASes
```

The `multipath-relax` part: by default BGP requires AS-paths to match for multipath. Coming from different ASes (one per backend), that fails. Relax it.

### Health checking via BGP session

The backend's BGP daemon (FRR here) **only announces the VIP if its application is healthy**. Two common patterns:

1. **ExaBGP / GoBGP with health hooks**: the BGP daemon checks (curl localhost, systemd service status) and announces or withdraws.
2. **FRR + service binding**: the VIP is only on `lo` while the service is bound to it (e.g., a script that adds/removes the IP based on systemd state).

Either way: backend dies → VIP withdrawn → router removes that path from ECMP → traffic rehashes. BGP hold timer defaults are 180s/60s — for fast failover, tune to 3s/1s + BFD.

### Hashing & flow stickiness

Hash inputs typically include src IP, dst IP, src port, dst port, proto. A given flow keeps going to the same backend. New flows may pick a different backend.

Risk: hash polarization — if every router in a chain uses the same hash, the same flow lands on the same path at every step. Modern hardware randomizes per-router; not usually a problem.

### Connection draining & graceful removal

To take a backend out of rotation for maintenance:
- Backend stops announcing the VIP (e.g., `network 10.99.99.1/32` removed from BGP config)
- Existing flows finish (or get reset by the backend); new flows go to remaining backends
- Once drained, backend can be rebooted / patched / replaced
- Bring back: re-announce, traffic rebalances

Compare to: HAProxy `set server backend1 state drain` — same idea, different actuation mechanism.

### When you outgrow ECMP-only

Once you need:
- L7 (path / hostname / header routing) → put HAProxy / Envoy in front
- Connection affinity → use consistent hashing (Maglev, Katran, GLB)
- TLS termination → L7 LB (or per-backend)

The pattern: ECMP across L7 LBs, L7 LBs in front of pools. ECMP is the "outer" distribution; L7 does the "inner" smart routing.

## Your task

1. On `router`, configure eBGP to all three backends.
2. Enable ECMP: `maximum-paths 4 ecmp 4` + `bgp bestpath as-path multipath-relax`.
3. Verify all three paths install in the FIB.
4. From the client, generate traffic and verify it distributes.

## Verification

### BGP state
```bash
docker exec -it clab-load-balancing-patterns-router Cli
show ip bgp summary
show ip bgp 10.99.99.1/32
show ip route 10.99.99.1
```

The route should show 3 next-hops.

### Generate traffic and observe distribution
On each backend, capture:
```bash
docker exec -d clab-load-balancing-patterns-backend1 tcpdump -i eth1 -nn 'host 10.99.99.1' -w /tmp/b1.pcap
docker exec -d clab-load-balancing-patterns-backend2 tcpdump -i eth1 -nn 'host 10.99.99.1' -w /tmp/b2.pcap
docker exec -d clab-load-balancing-patterns-backend3 tcpdump -i eth1 -nn 'host 10.99.99.1' -w /tmp/b3.pcap
```

From client (different source ports → different hashes):
```bash
for i in $(seq 1 30); do
  docker exec clab-load-balancing-patterns-client bash -c "echo test | nc -u -w0 -p $((10000 + $i)) 10.99.99.1 7"
done
```

Stop captures and count packets per backend:
```bash
for b in backend1 backend2 backend3; do
  echo -n "$b: "
  docker exec clab-load-balancing-patterns-$b tcpdump -r /tmp/b${b##backend}.pcap 2>/dev/null | wc -l
done
```

Each backend should see roughly 1/3 of the flows.

### Simulate backend failure
```bash
docker exec clab-load-balancing-patterns-backend2 pkill bgpd
```

Wait for BGP hold timer (~3 minutes default). Then:
```bash
docker exec clab-load-balancing-patterns-router Cli -c "show ip route 10.99.99.1"
```

Only 2 paths remain. Re-run client traffic — distributed across 2 backends only.

## What's missing (deliberately)

- **Consistent-hash ECMP** (Maglev) for flow stickiness — newer-hardware feature
- **BFD on BGP sessions** for sub-second backend failure detection — covered in lab 19/26
- **Service health binding** — script that conditionally announces based on `curl localhost` health
- **L7 LB integration** (HAProxy / Envoy in front of pools)
- **TCP connection draining** — protocol-level, not network

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
