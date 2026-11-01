#!/usr/bin/env bash
set -Eeuo pipefail
ARG1="${1:-}"
TOOL_DIR="${BT_GDRIVE_STATE_DIR:-/root/bt_gdrive_tool}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$ARG1" = "--bootstrap" ]; then
  ROOT_FOLDER_ID=""; BOOTSTRAP=1; FALLBACK="${2:-}"
else
  ROOT_FOLDER_ID="${ARG1:-${ROOT_FOLDER_ID:-}}"; BOOTSTRAP=0; FALLBACK="${2:-}"
  [ -n "$ROOT_FOLDER_ID" ] || { echo "Usage: sudo bash install.sh <Google-Drive-folder-ID> [fallback-server-name]"; echo "   or: sudo bash install.sh --bootstrap [fallback-server-name]"; exit 2; }
fi
mkdir -p "$TOOL_DIR" "$TOOL_DIR/logs" "$TOOL_DIR/backups"
chmod 700 "$TOOL_DIR" "$TOOL_DIR/logs" "$TOOL_DIR/backups"
for f in repair.sh diagnose.sh uninstall.sh configure-root.sh; do cp -a "$SCRIPT_DIR/$f" "$TOOL_DIR/$f"; done
cat > "$TOOL_DIR/config.env" <<CFG
ROOT_FOLDER_ID='$ROOT_FOLDER_ID'
BOOTSTRAP='$BOOTSTRAP'
FALLBACK_SERVER_NAME='$FALLBACK'
CFG
chmod 600 "$TOOL_DIR/config.env" "$TOOL_DIR"/*.sh
bash "$TOOL_DIR/repair.sh"
echo "Installed to $TOOL_DIR"
if [ "$BOOTSTRAP" = "1" ]; then
  echo "Bootstrap mode: run ONE small backup, find the new BT-Backup folder ID in Drive, then run:"
  echo "  sudo bash $TOOL_DIR/configure-root.sh <folder-id>"
else
  echo "Future repair: sudo bash $TOOL_DIR/repair.sh"
fi
