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

# Initialise the repo on 'main' so the optional push at the end matches.
# (Without -b main, stock git creates 'master' and the push below no-ops.)
[ -d .git ] || git init -q -b main

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

# Commit any changes. Stage first, THEN check the staged diff: `git diff
# --quiet` only looks at tracked files, so on the very first run the freshly
# written *.cfg are untracked and would be missed — `git diff --cached
# --quiet` sees newly-staged files too, so the first backup is committed.
git add -A
if ! git diff --cached --quiet; then
    git commit -qm "automated backup $(date -u +%FT%TZ)"
    echo "committed config changes"
else
    echo "no config changes"
fi

# Optional: push to remote (pushes whatever branch we're on)
git push origin HEAD 2>/dev/null || echo "no remote configured"
