# Lab 46 — iSCSI Fundamentals (Network Side)

> **Format:** Hands-on (network configuration only). Build the storage VLAN, jumbo MTU, multipath topology. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 8 · Senior+ · Year 5. The Company added a managed-storage product. Customer VMs talk to a SAN over the network. Storage traffic looks like normal IP, but if you treat it like normal IP, performance is unusably bad. You learn that storage networking is its own discipline with its own rules. See [`STORY.md`](../../STORY.md).
>
> **Scope:** This lab covers the *network* side: VLAN isolation, MTU, multipath topology, edge protections. iSCSI initiator/target *daemon* config (LUNs, CHAP, etc.) is host-side and not included — link to references at the end.

## Real-world scenario

The storage team buys a new SAN. They plug it into a shared switch with all the customer VLANs and call it a day. Performance is terrible: 50 MB/s on what should be a 10 Gb link, latency spikes to 200ms, customers complain.

You investigate. The findings:
- Storage shares broadcast domain with general VMs → broadcast storms from one tenant ruin storage for everyone
- MTU is 1500 → every iSCSI block transfer is fragmented into 4 ethernet frames instead of 1, tripling the per-block overhead
- No multipath topology → single switch loss = SAN unreachable = every VM crashes
- LLDP runs on storage ports → adds inter-packet processing latency

You build a real storage network. The pattern: **storage traffic is treated like real-time traffic with a low-jitter requirement, not like data traffic.**

## Goal

- Dedicated storage VLAN (separated broadcast domain)
- Jumbo MTU (9000+) end to end
- Multipath topology (2+ NICs per host, 2+ paths to target)
- Standard edge protections (PortFast, BPDU Guard, storm-control)

## Theory primer

### iSCSI in 30 seconds

iSCSI carries SCSI commands over TCP. The host (initiator) opens a TCP connection to the SAN (target). Reads and writes look like SCSI block I/O — but over the network instead of a SAS/FC bus.

- TCP port 3260 by default
- Target identifier: `iqn.YYYY-MM.<reverse-domain>:<unique>` (IQN — iSCSI Qualified Name)
- Each "LUN" (Logical Unit Number) is a block device on the initiator: `/dev/sdb`, etc.
- The initiator's filesystem (ext4, XFS) sits on top of the LUN as if it were a local disk

### Why network design matters for storage

| Network problem | Storage symptom |
|---|---|
| Packet loss > 0.01% | I/O timeouts, retries, perceived "slow disk" |
| Jitter (variable latency) | Inconsistent throughput, application timeouts |
| MTU mismatch | Connection works for small I/O, hangs for large reads |
| Broadcast storm in storage VLAN | All hosts lose disk simultaneously |
| Single path | Single switch/cable failure = production outage |
| Spanning-tree convergence on storage port | 30-60s of "no disk" during STP recalc |

A working ethernet network with 0.5% packet loss is fine for web traffic. For iSCSI it's catastrophic.

### Jumbo frames (MTU 9000+)

Standard MTU = 1500 bytes. iSCSI block transfers are typically 4 KB-64 KB. With MTU 1500, a 64 KB transfer is ~45 ethernet frames. With MTU 9000, it's ~7 frames. Fewer frames = less per-frame overhead = higher throughput, lower CPU.

Requirements:
- Every device on the path must support and be configured for the same MTU
- One mis-configured device = packets dropped or fragmented → worse than no jumbo
- Test with: `ping -M do -s 8972 target` (8972 = 9000 - 28 ICMP+IP overhead). If it fails, MTU is wrong somewhere.

### Multipath I/O (MPIO)

Two NICs per host, two switches, two paths to target. The Linux multipath daemon (`multipathd`) presents one logical device to the OS that internally fans out across both paths. On failure, the other path takes over without the application noticing.

Topology requirement: paths must be **physically independent** — different NICs, different switches, ideally different power. "Both NICs through the same switch" defeats the purpose.

### Why storage gets its own VLAN (or VRF, or physical network)

Three reasons:
1. **Broadcast isolation**: a misbehaving NIC in the data VLAN can't impact storage.
2. **QoS / lossless ethernet**: storage VLAN can be configured for PFC/ETS (see lab 47).
3. **ACL simplicity**: it's much easier to say "this VLAN is storage, nothing else here" than "filter port 3260 everywhere."

For high-end deployments, storage gets a *physical* separate network (different switches, different cabling). For mid-range, a separate VLAN with priority queueing is enough.

### Spanning-tree configuration on storage ports

Same rules as access ports (lab 05):
- PortFast: skip listening/learning, go straight to forwarding
- BPDU Guard: shut the port if a BPDU arrives (a host shouldn't be sending BPDUs)
- Optionally: disable STP entirely on the VLAN and rely on physical topology (riskier)

Why: if STP runs normally, a topology change can blackhole storage traffic for 30 seconds during convergence. Filesystem timeouts; data corruption potential.

### Disabling LLDP / CDP on storage ports

Marginal but real: every LLDP/CDP packet processed by the host's NIC firmware adds latency. For latency-sensitive storage hosts, some shops disable LLDP on those specific ports.

## Your task

1. Configure all 4 ports in VLAN 50 (already set in starter).
2. Set MTU 9214 on each storage port (9214 = 9000 + 214 bytes for headers; Arista convention).
3. Apply `spanning-tree portfast` and `spanning-tree bpduguard enable` on every storage port.
4. Disable LLDP transmit/receive on storage ports.

## Verification

### Check VLAN + MTU
```bash
docker exec -it clab-iscsi-fundamentals-sw-storage Cli
show interfaces ethernet 1 status
show interfaces ethernet 1 | grep MTU
show spanning-tree interface ethernet 1
```

### Test jumbo end-to-end (initiator → target)
```bash
docker exec clab-iscsi-fundamentals-init-a ping -M do -s 8972 10.50.0.10
```

Should succeed. If you see "Frag needed and DF set" or hangs, MTU is wrong somewhere.

### Test redundant paths
```bash
# Bring down one initiator interface; verify other path still reaches target
docker exec clab-iscsi-fundamentals-init-a ip link set eth1 down
docker exec clab-iscsi-fundamentals-init-a ping -c 3 -I eth2 10.50.0.11
```

## Host-side iSCSI (out of scope, here for context)

If you actually want to do iSCSI on Linux:

- **Target side** (`targetcli`): create a backstore, an IQN, an ACL, an LUN
- **Initiator side** (`iscsiadm`): discover the target, log in, the LUN appears as `/dev/sdX`
- **Multipath**: install `multipath-tools`, configure `/etc/multipath.conf`, the LUN appears as `/dev/mapper/mpathX`

Good reference: [Linux iSCSI documentation](https://docs.kernel.org/admin-guide/iscsi.html).

## What's missing (deliberately)

- **PFC / ETS / DCB** — the lossless-ethernet protocols that make iSCSI work at line rate; covered in lab 47
- **NVMe-over-fabrics (NVMe-oF)** — modern replacement for iSCSI, uses RDMA; needs different network design
- **Fibre Channel** — non-IP storage transport, separate fabric
- **iSER (iSCSI over RDMA)** — high-perf iSCSI variant
- **Host-side LUN provisioning** — kernel target / open-iscsi configuration

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
