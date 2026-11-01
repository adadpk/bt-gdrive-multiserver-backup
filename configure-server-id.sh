#!/usr/bin/env bash
set -Eeuo pipefail

STATE_DIR="${BT_GDRIVE_STATE_DIR:-/root/bt_gdrive_tool}"
CONFIG="$STATE_DIR/config.env"
MODE="${1:-}"
NAME="${2:-}"

usage() {
  cat <<'EOF'
Usage:
  sudo bash configure-server-id.sh ip [fallback-name]
  sudo bash configure-server-id.sh name FIXED_NAME
  sudo bash configure-server-id.sh hostname
EOF
}

[ -f "$CONFIG" ] || { echo "Missing $CONFIG. Run install.sh first."; exit 1; }

case "$MODE" in
  ip)
    ;;
  name)
    [ -n "$NAME" ] || { echo "name mode requires a fixed name"; usage; exit 2; }
    ;;
  hostname)
    NAME=""
    ;;
  *)
    usage
    exit 2
    ;;
esac

python3 - "$CONFIG" "$MODE" "$NAME" <<'PY'
from pathlib import Path
import sys,re,shlex
p=Path(sys.argv[1]); mode=sys.argv[2]; name=sys.argv[3]
s=p.read_text()

def setv(text,key,value):
    line=f"{key}={shlex.quote(value)}"
    if re.search(rf"(?m)^{re.escape(key)}=.*$", text):
        return re.sub(rf"(?m)^{re.escape(key)}=.*$", line, text)
    return text.rstrip()+"\n"+line+"\n"

s=setv(s,'SERVER_ID_MODE',mode)
s=setv(s,'SERVER_NAME',name)
p.write_text(s)
PY

chmod 600 "$CONFIG"
bash "$STATE_DIR/repair.sh"

echo "Server ID mode changed to: $MODE"
if [ "$MODE" = "name" ]; then
  echo "Fixed server name: $NAME"
elif [ "$MODE" = "ip" ] && [ -n "$NAME" ]; then
  echo "Fallback name configured."
fi
