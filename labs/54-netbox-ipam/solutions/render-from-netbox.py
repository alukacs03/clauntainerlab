#!/usr/bin/env python3
"""
Render device configs from NetBox + Jinja2 templates.

Pattern: NetBox is the source of truth for *intent*. This script renders
configs from that intent. Ansible (lab 52) applies them.

Install: pip install pynetbox jinja2
"""
import os
from pathlib import Path
import pynetbox
from jinja2 import Environment, FileSystemLoader

nb = pynetbox.api(
    "http://netbox.lan:8000",
    token=os.environ["NETBOX_TOKEN"],
)

env = Environment(loader=FileSystemLoader("templates/"))
template = env.get_template("leaf.j2")

for device in nb.dcim.devices.filter(role="leaf", status="active"):
    ctx = {
        "hostname": device.name,
        "primary_ip": str(device.primary_ip4).split("/")[0],
        "asn": device.custom_fields.get("asn"),
        "interfaces": [
            {
                "name": iface.name,
                "description": iface.description,
                "ip": str(iface.ip_addresses[0]) if iface.ip_addresses else None,
            }
            for iface in nb.dcim.interfaces.filter(device_id=device.id)
        ],
        # Pull all prefixes assigned to this device's site for routing context
        "site_prefixes": [
            str(p.prefix) for p in nb.ipam.prefixes.filter(site=device.site.slug)
        ],
    }
    out = Path(f"rendered/{device.name}.cfg")
    out.parent.mkdir(exist_ok=True)
    out.write_text(template.render(**ctx))
    print(f"rendered {out}")
