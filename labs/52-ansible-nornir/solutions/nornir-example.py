#!/usr/bin/env python3
"""
Nornir equivalent of the baseline Ansible playbook.

Why someone picks Nornir over Ansible:
- Pure Python (no YAML DSL); easier to test, type-check, integrate
- Faster execution (true parallelism, no fork overhead)
- Better for engineers comfortable in Python; worse for ops folk used to YAML

Install: pip install nornir nornir-napalm nornir-utils

The SimpleInventory below reads the three YAML files shipped alongside this
script (hosts.yaml / groups.yaml / defaults.yaml), so the example runs as-is
once napalm can reach the switches' eAPI. Each host carries its own mgmt_server
(the automation host's address on that host's link) as host data, mirroring the
Ansible inventory.
"""

from nornir import InitNornir
from nornir.core.task import Task, Result
from nornir_napalm.plugins.tasks import napalm_configure
from nornir_utils.plugins.functions import print_result

BASELINE_TEMPLATE = """
banner login
Authorized access only. All activity logged.
EOF
logging host {mgmt_server}
ntp server {mgmt_server}
line vty
   exec-timeout 10
"""


def apply_baseline(task: Task) -> Result:
    config = BASELINE_TEMPLATE.format(mgmt_server=task.host["mgmt_server"])
    result = task.run(task=napalm_configure, configuration=config)
    return Result(host=task.host, result=f"baseline applied: {result.changed}")


if __name__ == "__main__":
    nr = InitNornir(
        runner={"plugin": "threaded", "options": {"num_workers": 10}},
        inventory={
            "plugin": "SimpleInventory",
            "options": {
                "host_file": "hosts.yaml",
                "group_file": "groups.yaml",
                "defaults_file": "defaults.yaml",
            },
        },
    )
    result = nr.run(task=apply_baseline)
    print_result(result)
