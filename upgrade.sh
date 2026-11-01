#!/usr/bin/env bash
set -Eeuo pipefail

STATE_DIR="${BT_GDRIVE_STATE_DIR:-/root/bt_gdrive_tool}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$STATE_DIR/config.env"

[ -f "$CONFIG" ] || { echo "Existing installation not found: $CONFIG"; echo "Use install.sh for a fresh installation."; exit 1; }

mkdir -p "$STATE_DIR" "$STATE_DIR/logs" "$STATE_DIR/backups"
chmod 700 "$STATE_DIR" "$STATE_DIR/logs" "$STATE_DIR/backups"

# Migrate v0.1.x configuration while preserving the private Folder ID.
python3 - "$CONFIG" <<'PY'
from pathlib import Path
import re,shlex,sys
p=Path(sys.argv[1]); s=p.read_text()

def get(key):
    m=re.search(rf'(?m)^{re.escape(key)}=(.*)$',s)
    if not m: return ''
    raw=m.group(1).strip()
    if len(raw)>=2 and raw[0]==raw[-1] and raw[0] in "'\"": return raw[1:-1]
    return raw

def setv(text,key,value):
    line=f"{key}={shlex.quote(value)}"
    if re.search(rf'(?m)^{re.escape(key)}=.*$', text):
        return re.sub(rf'(?m)^{re.escape(key)}=.*$', line, text)
    return text.rstrip()+"\n"+line+"\n"

mode=get('SERVER_ID_MODE') or 'ip'
name=get('SERVER_NAME') or get('FALLBACK_SERVER_NAME')
out=s
out=setv(out,'SERVER_ID_MODE',mode)
out=setv(out,'SERVER_NAME',name)
p.write_text(out)
PY

for f in repair.sh diagnose.sh uninstall.sh configure-root.sh configure-server-id.sh upgrade.sh; do
  cp -a "$SCRIPT_DIR/$f" "$STATE_DIR/$f"
done
chmod 600 "$CONFIG" "$STATE_DIR"/*.sh

bash "$STATE_DIR/repair.sh"
echo "Upgrade completed. Existing Folder ID was preserved."
echo "Current server ID mode is stored in $CONFIG."
echo "Switch modes with:"
echo "  sudo bash $STATE_DIR/configure-server-id.sh ip"
echo "  sudo bash $STATE_DIR/configure-server-id.sh name web-prod-01"
echo "  sudo bash $STATE_DIR/configure-server-id.sh hostname"
