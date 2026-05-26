#!/bin/bash
# Daily config backup script. Run from cron / systemd timer on the backup server.
# Pull running-config from each device via eAPI, commit to git, push to remote.

set -euo pipefail

BACKUP_DIR=/backups/configs
DEVICES_FILE=/etc/network-backups/devices.txt
USER=admin
# Production: use Vault / sops, not a literal env var
: "${EAPI_PASSWORD:?must set EAPI_PASSWORD}"

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

[ -d .git ] || git init -q

while IFS= read -r device; do
    [ -z "$device" ] && continue
    [[ "$device" == \#* ]] && continue

    echo "backing up $device..."
    curl -sk -u "$USER:$EAPI_PASSWORD" "https://$device/command-api" \
      -H "Content-Type: application/json" \
      -d '{"jsonrpc":"2.0","method":"runCmds","params":{"version":1,"cmds":["show running-config"],"format":"text"},"id":"backup"}' \
      | jq -r '.result[0].output' \
      > "$device.cfg"
done < "$DEVICES_FILE"

# Commit any changes
if ! git diff --quiet; then
    git add -A
    git commit -qm "automated backup $(date -u +%FT%TZ)"
    echo "committed config changes"
else
    echo "no config changes"
fi

# Optional: push to remote
git push origin main 2>/dev/null || echo "no remote configured"
