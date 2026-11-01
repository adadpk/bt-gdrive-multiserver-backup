#!/usr/bin/env bash
set -u
STATE_DIR="${BT_GDRIVE_STATE_DIR:-/root/bt_gdrive_tool}"
OUT="$STATE_DIR/diagnostic_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p "$STATE_DIR"
{
 echo "bt-gdrive-multiserver diagnostic"; date -Is 2>/dev/null || date
 echo "--- files ---"; ls -l /www/server/panel/plugin/gdrive/gdrive_main.py /www/server/panel/class/CloudStoraUpload.py 2>&1
 echo "--- markers ---"; grep -nE 'BT-GDRIVE-MULTISERVER|BT-Backup|root_folder_id|server_id_mode|api4.ipify.org' /www/server/panel/plugin/gdrive/gdrive_main.py /www/server/panel/class/CloudStoraUpload.py 2>&1 | head -140
 echo "--- config (redacted) ---"
 if [ -f "$STATE_DIR/config.env" ]; then
   sed -E "s/(ROOT_FOLDER_ID=).*/\1'<redacted>'/; s/(SERVER_NAME=).*/\1'<redacted-if-set>'/" "$STATE_DIR/config.env"
 else
   echo missing
 fi
 echo "--- runtime server-id mode ---"; cat /www/server/panel/plugin/gdrive/server_id_mode.conf 2>/dev/null || echo "ip (default/missing)"
 echo "--- public ipv4 detection ---"; IP=$(curl -4fsS --max-time 4 https://api4.ipify.org 2>/dev/null || true); if [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then echo "OK (value redacted)"; else echo "unavailable"; fi
 echo "--- python compile ---"; PY=/www/server/panel/pyenv/bin/python3; [ -x "$PY" ] || PY=$(command -v python3); "$PY" -m py_compile /www/server/panel/plugin/gdrive/gdrive_main.py /www/server/panel/class/CloudStoraUpload.py 2>&1 && echo OK
} | tee "$OUT"
echo "Saved: $OUT"
