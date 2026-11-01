#!/usr/bin/env bash
set -Eeuo pipefail
ID="${1:-}"
[ -n "$ID" ] || { echo "Usage: sudo bash configure-root.sh <Google-Drive-folder-ID>"; exit 2; }
STATE_DIR="${BT_GDRIVE_STATE_DIR:-/root/bt_gdrive_tool}"
[ -f "$STATE_DIR/config.env" ] || { echo "Missing $STATE_DIR/config.env"; exit 1; }
python3 - "$STATE_DIR/config.env" "$ID" <<'PY'
from pathlib import Path
import sys,re
p=Path(sys.argv[1]); ID=sys.argv[2]
s=p.read_text()
s=re.sub(r"(?m)^ROOT_FOLDER_ID=.*$", "ROOT_FOLDER_ID='{}'".format(ID.replace("'","")), s)
s=re.sub(r"(?m)^BOOTSTRAP=.*$", "BOOTSTRAP='0'", s)
p.write_text(s)
PY
bash "$STATE_DIR/repair.sh"
echo "Shared root configured. Future servers can install with this same folder ID."
