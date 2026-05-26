"""
Integration test example: every leaf must have all expected BGP peers in Established state.

Run after deploy-staging.
"""
import pytest
import requests
import urllib3

urllib3.disable_warnings()

DEVICES = ["10.0.0.1", "10.0.0.2"]
EXPECTED_PEERS = {
    "10.0.0.1": [],   # populate from NetBox / source of truth in production
    "10.0.0.2": [],
}


def eapi(device, cmds):
    r = requests.post(
        f"https://{device}/command-api",
        auth=("admin", "admin"),
        json={
            "jsonrpc": "2.0",
            "method": "runCmds",
            "params": {"version": 1, "cmds": cmds, "format": "json"},
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
    result = eapi(device, ["show logging last 1 hours"])[0]
    msgs = result.get("messages", [])
    critical = [m for m in msgs if "%CRITICAL" in str(m) or "EMERG" in str(m)]
    assert len(critical) == 0, f"{device}: {len(critical)} critical log entries"
