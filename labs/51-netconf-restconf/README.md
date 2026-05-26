# Lab 51 — NETCONF / RESTCONF Foundations

> **Format:** Hands-on. Enable NETCONF and eAPI on a switch; query state and push a config change programmatically. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 9 · Tech lead · Year 5+. Click-ops on 100+ devices doesn't scale. The team needs to write configs once and apply everywhere — idempotently, with diffs, with rollback. NETCONF (with YANG models) is the standards-track answer; eAPI is Arista's vendor flavor. Lab 52 builds Ansible on top; this lab is the protocol primer. See [`STORY.md`](../../STORY.md).

## Real-world scenario

Three problems with CLI-based config management:
1. **Not idempotent**: running the same script twice can produce different results. CLI is order-sensitive.
2. **Not transactional**: half-applied configs leave the device in an undefined state.
3. **Hard to diff**: comparing "what's actually there" vs "what we intended" is text-diff. Sensitive to ordering, formatting.

NETCONF solves all three:
- **YANG-modeled**: data is structured, not free text. Diffable structurally.
- **Transactional**: candidate → commit → confirmed-commit pattern. Either the whole change applies or nothing does.
- **Idempotent**: declarative ("the config should look like X") vs imperative ("type these commands").

## Protocols at a glance

| Protocol | Transport | Encoding | Standard | Use |
|---|---|---|---|---|
| **NETCONF** | SSH (port 830) | XML | RFC 6241 | Standards-track config protocol |
| **RESTCONF** | HTTPS | JSON or XML | RFC 8040 | REST-friendly NETCONF |
| **gNMI** | gRPC (port 6030) | protobuf | OpenConfig | Modern, telemetry+config |
| **eAPI** | HTTPS | JSON-RPC | Arista-specific | Send CLI commands, get JSON back |

On Arista, eAPI is the easiest entry point because it accepts CLI commands wrapped in JSON — no YANG learning curve. NETCONF is the standards-track answer. Choose based on:
- Multi-vendor environment → NETCONF (works on Cisco IOS-XR, Juniper, Nokia, Arista)
- Arista-only → eAPI is convenient
- New code today → gNMI (telemetry + config in one protocol)

## Goal

- Enable NETCONF and eAPI on the switch
- Run a `get-config` via NETCONF using `ncclient`
- Push a config change via eAPI using `curl`
- Understand the differences

## Theory primer

### NETCONF operations

- `get-config`: retrieve config from a datastore (running, candidate, startup)
- `edit-config`: apply changes to a datastore
- `copy-config`: copy one datastore to another
- `commit`: copy candidate to running
- `lock`/`unlock`: prevent concurrent edits
- `delete-config`: erase a datastore

The candidate datastore pattern:
```
1. lock candidate
2. edit-config (multiple changes)
3. validate
4. commit
5. unlock candidate
```

If anything fails before commit, the running config is untouched.

### YANG models

YANG describes the shape of the data. Two flavors:
- **OpenConfig**: vendor-neutral, narrower coverage
- **Vendor-native**: full coverage of that vendor's features (Arista has `arista-system`, `arista-bgp`, etc.)

Production-ish pattern: write your tooling against OpenConfig where it exists; fall back to vendor-native for vendor-specific features.

## Your task

1. Configure NETCONF and eAPI on the switch (in solution).
2. From the client, install ncclient (or curl for eAPI).
3. Pull the running config via NETCONF.
4. Push a config change via eAPI: add a loopback interface.

## Verification

### Install client tools
```bash
docker exec -it clab-netconf-restconf-client bash
apt update && apt install -y python3-pip curl
pip3 install ncclient
```

### NETCONF get-config
```python
# /tmp/netconf-get.py
from ncclient import manager

with manager.connect(host="10.0.0.1", port=830, username="admin",
                     password="admin", hostkey_verify=False,
                     device_params={"name": "default"}) as m:
    config = m.get_config(source="running")
    print(config)
```

Run: `python3 /tmp/netconf-get.py`

### eAPI: push a loopback
```bash
curl -k -u admin:admin -H "Content-Type: application/json" \
  https://10.0.0.1/command-api -d '
{
  "jsonrpc": "2.0",
  "method": "runCmds",
  "params": {
    "version": 1,
    "cmds": [
      "configure",
      "interface Loopback99",
      "ip address 10.99.99.99/32"
    ],
    "format": "json"
  },
  "id": "lo-add"
}'
```

Verify:
```bash
curl -k -u admin:admin -H "Content-Type: application/json" \
  https://10.0.0.1/command-api -d '
{"jsonrpc":"2.0","method":"runCmds",
 "params":{"version":1,"cmds":["show ip interface brief"],"format":"json"},
 "id":"check"}'
```

## What's missing (deliberately)

- **YANG model browsing** (`pyang`, `yanglint`)
- **OpenConfig translation libraries** (`pyangbind`)
- **Confirmed commit** with auto-rollback if not re-confirmed
- **NETCONF over TLS** (RFC 7589) instead of SSH
- **Bulk operations** patterns (Ansible's `netconf_config`, Nornir+Scrapli)

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
