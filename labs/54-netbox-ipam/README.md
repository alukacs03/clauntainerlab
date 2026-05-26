# Lab 54 — Source of Truth & IPAM (NetBox)

> **Format:** Reference + setup pointers. NetBox is a multi-container app — you'll run it separately via docker-compose, not inside containerlab. This lab covers the model and integration patterns. Reference in [`solutions/`](solutions/).
>
> **Story chapter:** Phase 9 · Tech lead · Year 5+. After lab 52 the team can apply playbooks to 100 devices. But the *inventory* lives in a YAML file someone edits by hand. New rack? Update YAML. New VLAN? Update YAML. Drift starts. You introduce NetBox: one database that knows what every device, interface, IP, VLAN, and circuit *should* be. Every other tool reads from it. See [`STORY.md`](../../STORY.md).

## Setup — running NetBox

NetBox itself isn't in this containerlab topology because it runs as a multi-container app. Easiest start:

```bash
git clone https://github.com/netbox-community/netbox-docker.git
cd netbox-docker
docker compose up -d
# Default: http://localhost:8000  (admin / admin)
```

Once it's up, populate with at least one site, one device role ("leaf"), one device (matching `leaf1` in our containerlab topology), and an API token.

## Real-world scenario

Before NetBox:
- "What VLAN was Tenant X assigned to?" → ask Bob, hope he remembers, check the wiki, check the switch config.
- "What's the next free /24 in the customer block?" → spreadsheet.
- "Which switch is this customer on?" → search through 47 switch configs.
- Result: drift between intent and reality. Mistakes. Outages caused by IP collisions.

After NetBox:
- One database knows: sites, racks, devices, interfaces, IPs, prefixes, VLANs, VRFs, circuits, cables.
- Every config-management tool reads from it: Ansible inventory comes from NetBox; Jinja templates pull device data from NetBox; new-rack provisioning generates configs from NetBox.
- Audit: "is the running config what NetBox says it should be?" You can answer that programmatically.

## Goal

- Stand up NetBox separately
- Model your lab topology in NetBox: site, devices, interfaces, IPs
- Drive Ansible inventory from NetBox
- (Optional) Render configs from NetBox via Jinja2

## Theory primer

### What NetBox models

| Object | What it represents |
|---|---|
| **Site** | Physical location (DC, office, colo cage) |
| **Rack** | A rack at a site |
| **Device** | A switch / router / server (anything with a serial number) |
| **Device Role** | leaf / spine / edge / firewall / etc. |
| **Interface** | A port on a device |
| **IP Address** | A specific IP assigned to an interface |
| **Prefix** | A subnet (allocated or available) |
| **VLAN** | A VLAN ID in a site/group |
| **VRF** | A VRF (with RD/RT optionally) |
| **Cable** | A physical connection between two interfaces |
| **Circuit** | A provider circuit (transit, peering, cross-connect) |

### The "source of truth" pattern

NetBox holds **intent**. Live devices hold **state**. The two should match — and you have tooling to verify (`diff(intent, state)`).

When they diverge:
- Drift detected → alert
- Either: fix the device to match intent (re-apply), or fix intent to match device (someone made an authorized hand-edit, update NetBox)
- Don't ignore drift — it always grows

### API usage

NetBox has a REST API and a GraphQL API. Tooling:
- **pynetbox**: Python client
- **netbox.netbox.nb_inventory**: Ansible inventory plugin
- **NetBox API in CI**: read state during pipelines

Authentication: API tokens (per-user). Don't share tokens; one per service that needs access.

### What NetBox doesn't do

- **Not a NMS**: doesn't poll, doesn't alert. (Use Prometheus for that — lab 50.)
- **Not a config push**: doesn't ssh to devices. (Use Ansible for that — lab 52.)
- **Not auto-discovery**: it's a *declared* state. You can integrate discovery (LLDP polling → NetBox), but NetBox isn't doing the discovery itself.

NetBox is the "what should be." Other tools handle "what is" and "make it so."

### Custom fields

NetBox lets you add custom fields to any object. Common additions:
- `asn` on devices (per-leaf BGP ASN for spine-leaf eBGP)
- `tenant_id` on prefixes (for billing)
- `monitor_priority` on devices (for alerting tiers)

Don't go overboard. Start with NetBox's built-in fields; add custom only when you have a real use case.

## Your task

1. Bring up NetBox via docker-compose.
2. Create a site (e.g., "dc-1"), one device role ("leaf"), and one device (`leaf1` with IP `10.0.0.1/24`).
3. Create an API token.
4. From the `automation` container, install `pynetbox`:
   ```bash
   docker exec -it clab-netbox-ipam-automation bash
   pip3 install pynetbox
   ```
5. Verify the API:
   ```python
   import pynetbox
   nb = pynetbox.api("http://YOUR-VM-IP:8000", token="YOUR-TOKEN")
   for d in nb.dcim.devices.all():
       print(d.name, d.primary_ip4)
   ```
6. (Optional) Use `netbox-inventory.yml` to drive Ansible from NetBox.

## What's missing (deliberately)

- **Initial bulk import** from existing switch configs into NetBox (community tools: `netbox-importer`, `ntc-templates`)
- **Drift detection** automation — comparing rendered intent vs live state
- **Cable management** — tracking cross-connects, fiber MMR records
- **Circuits & providers** — for managing transit and peering links
- **Webhook-driven automation** (NetBox change → trigger CI)
- **CMDB integration** with ITSM tools (ServiceNow etc.)

## Cleanup

```bash
sudo containerlab destroy --cleanup
docker compose -f netbox-docker/docker-compose.yml down  # if you set up NetBox
```
