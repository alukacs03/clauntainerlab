# Lab 49 — Streaming Telemetry (gNMI / OpenConfig)

> **Format:** Hands-on. Enable gNMI on the switch, subscribe from a collector, observe push-based telemetry. Reference answer in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 9 · Tech lead · Year 5+. SNMP polled every 10 seconds is missing 9 seconds of relevant data per cycle. The microbursts that cause customer pain are invisible. You move to streaming telemetry — the device *pushes* metrics at sub-second cadence. See [`STORY.md`](../../STORY.md).

## Real-world scenario

Your monitoring stack polls SNMP every 10 seconds. A customer complains about "intermittent slow responses." You check the interface graphs — flat. No errors. But the customer's trace shows packet loss at exactly 02:17 for ~3 seconds. SNMP couldn't see it because it averaged the 10-second window.

Streaming telemetry is the answer:
- **Push, not poll**: the device sends data to the collector at the cadence the collector subscribed to (typically 1s or sub-second).
- **Structured**: data is YANG-modeled, not free-text. Tooling can parse it consistently.
- **Efficient**: gRPC over a persistent connection, protobuf encoding. Much less overhead than SNMP polling.

The stack:
- **gNMI** (gRPC Network Management Interface): the protocol
- **OpenConfig**: the vendor-neutral YANG model
- **gnmic** / **gnmi_collector** / **gnmi-gateway**: collector tools
- **Prometheus / InfluxDB**: time-series storage
- **Grafana**: visualization

Lab 50 covers the full stack. This lab just gets gNMI talking.

## Goal

- Enable gNMI on the switch
- From the collector, do a `Get` (one-shot) and a `Subscribe` (streaming)
- Understand the structure (YANG paths, encoding)

## Theory primer

### gNMI in one paragraph

gRPC service with 4 RPCs:
- **Capabilities**: list supported models
- **Get**: one-shot query at a YANG path
- **Set**: configure (write)
- **Subscribe**: stream updates at a path

Operates over TCP (default port 6030 on Arista, 9339 on Cisco/Juniper for OpenConfig). Encoded as protobuf; payload encoded as JSON, JSON_IETF, or PROTO depending on what you ask for.

### YANG paths

Like XPath. Examples:
- `/interfaces/interface[name=Ethernet1]/state/counters/in-octets`
- `/network-instances/network-instance[name=default]/protocols/protocol[identifier=BGP][name=BGP]/bgp/neighbors`

Paths can be OpenConfig (cross-vendor) or vendor-native (Arista's `eos-native`). Same data, different schema.

### Subscribe modes

- **STREAM SAMPLE**: send at fixed interval (e.g., every 1 second)
- **STREAM ON_CHANGE**: send only when the value changes
- **STREAM TARGET_DEFINED**: device picks (usually ON_CHANGE for config, SAMPLE for counters)
- **ONCE**: like Get, but over the Subscribe stream
- **POLL**: client triggers via Poll messages

For counters: SAMPLE 1s. For state changes (BGP peer up/down): ON_CHANGE.

## Your task

1. Configure `management api gnmi` with gRPC transport on port 6030.
2. Allow OpenConfig models in addition to EOS-native.
3. From the `collector` container, install `gnmic` (or use it via Docker) and:
   - List capabilities
   - Get the interface state
   - Subscribe to in-octets at 1-second sample interval

## Verification

### Install gnmic on the collector
```bash
docker exec -it clab-streaming-telemetry-collector bash
apt update && apt install -y curl
bash -c "$(curl -sL https://get-gnmic.openconfig.net)"
```

### Capabilities
```bash
gnmic -a 10.0.0.1:6030 -u admin -p admin --insecure capabilities
```

You should see supported models including OpenConfig and Arista native.

### One-shot Get
```bash
gnmic -a 10.0.0.1:6030 -u admin -p admin --insecure \
  get --path '/interfaces/interface[name=Ethernet1]/state/counters'
```

### Streaming Subscribe
```bash
gnmic -a 10.0.0.1:6030 -u admin -p admin --insecure \
  subscribe --path '/interfaces/interface[name=Ethernet1]/state/counters/in-octets' \
  --stream-mode sample --sample-interval 1s
```

You'll see counter updates every second. Generate some traffic to watch them tick.

## What's missing (deliberately)

- **TLS + client certificate authentication** — mandatory in production; lab uses insecure mode for simplicity
- **Telemetry exporters** (gnmic-to-Prometheus output) — lab 50
- **YANG model browsing** with `pyang` / `yanglint` — orthogonal tooling
- **gNMI Set** for configuration — covered in lab 51 (NETCONF) which is the more common config path

## Cleanup

```bash
sudo containerlab destroy --cleanup
```
