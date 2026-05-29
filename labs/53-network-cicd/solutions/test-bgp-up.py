"""
Integration test example: every leaf must have all expected BGP peers in Established state.

Run after deploy-staging.
"""
import pytest
import requests
import urllib3

urllib3.disable_warnings()

# staging-sw faces the runner on 10.0.0.0/30 (eth1); prod-sw on 10.0.1.0/30 (eth2).
DEVICES = ["10.0.0.1", "10.0.1.1"]
EXPECTED_PEERS = {
    # NOTE: the lab switches run NO BGP, so these lists are empty and
    # test_bgp_peers_established passes *vacuously* — the loop has nothing to
    # assert. That is deliberate: this file demonstrates the eAPI test *pattern*.
    # In production you populate these from NetBox / your source of truth, and
    # the test then fails loudly if any expected peer is missing or not Established.
    "10.0.0.1": [],   # populate from NetBox / source of truth in production
    "10.0.1.1": [],
}


def eapi(device, cmds, fmt="json"):
    r = requests.post(
        f"https://{device}/command-api",
        auth=("admin", "admin"),
        json={
            "jsonrpc": "2.0",
            "method": "runCmds",
            "params": {"version": 1, "cmds": cmds, "format": fmt},
            "id": "test",
        },
        verify=False,
        timeout=5,
    )
    return r.json()["result"]


@pytest.mark.parametrize("device", DEVICES)
def test_bgp_peers_established(device):
    result = eapi(device, ["show ip bgp summary"])[0]
    peers = result.get("vrfs", {}).get("default", {}).get("peers", {})
    expected = set(EXPECTED_PEERS[device])
    for peer_ip in expected:
        assert peer_ip in peers, f"{device}: peer {peer_ip} missing"
        state = peers[peer_ip].get("peerState")
        assert state == "Established", f"{device}: peer {peer_ip} state={state}"


@pytest.mark.parametrize("device", DEVICES)
def test_no_critical_errors(device):
    # `show logging` is an *unconverted* command in EOS eAPI: with format=json it
    # usually returns no structured `messages` array (and can raise a
    # commandUnconverted error), so JSON parsing is fragile and would pass
    # vacuously. Request format=text and grep the raw output instead — robust
    # across EOS versions. The text payload lives under the "output" key.
    result = eapi(device, ["show logging last 1 hours"], fmt="text")[0]
    output = result.get("output", "")
    critical = [
        line for line in output.splitlines()
        if "%CRITICAL" in line or "EMERG" in line
    ]
    assert len(critical) == 0, f"{device}: {len(critical)} critical log entries"
