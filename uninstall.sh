#!/usr/bin/env bash
set -Eeuo pipefail
STATE_DIR="${BT_GDRIVE_STATE_DIR:-/root/bt_gdrive_tool}"
latest="$(find "$STATE_DIR/backups" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -1)"
[ -n "$latest" ] || { echo "No backup snapshot found; refusing to restore automatically."; exit 1; }
cp -a "$latest/gdrive_main.py" /www/server/panel/plugin/gdrive/gdrive_main.py
cp -a "$latest/CloudStoraUpload.py" /www/server/panel/class/CloudStoraUpload.py
rm -f /www/server/panel/plugin/gdrive/root_folder_id.conf /www/server/panel/plugin/gdrive/server_name.conf
echo "Restored snapshot: $latest"
