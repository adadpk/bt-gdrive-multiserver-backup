#!/usr/bin/env bash
set -Eeuo pipefail

TOOL_DIR="${BT_GDRIVE_STATE_DIR:-/root/bt_gdrive_tool}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_FOLDER_ID=""
BOOTSTRAP=0
SERVER_ID_MODE="ip"
SERVER_NAME=""

usage() {
  cat <<'EOF'
Usage:
  sudo bash install.sh --bootstrap [--server-id ip|name|hostname] [--name NAME]
  sudo bash install.sh FOLDER_ID [--server-id ip|name|hostname] [--name NAME]

Server ID modes:
  ip        Use current public IPv4 (default). --name can be used as fallback.
  name      Use a fixed custom name. Requires --name.
  hostname  Use the system hostname.

Backward compatibility:
  sudo bash install.sh FOLDER_ID fallback-name
still works and means: ip mode + fallback name.
EOF
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "${1:-}" = "--bootstrap" ]; then
  BOOTSTRAP=1
  shift
elif [ -n "${1:-}" ] && [[ "${1:-}" != --* ]]; then
  ROOT_FOLDER_ID="$1"
  shift
else
  usage
  exit 2
fi

# Legacy positional fallback name from v0.1.x.
if [ -n "${1:-}" ] && [[ "${1:-}" != --* ]]; then
  SERVER_NAME="$1"
  shift
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --server-id)
      [ "$#" -ge 2 ] || { echo "Missing value for --server-id"; exit 2; }
      SERVER_ID_MODE="$2"
      shift 2
      ;;
    --name)
      [ "$#" -ge 2 ] || { echo "Missing value for --name"; exit 2; }
      SERVER_NAME="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

case "$SERVER_ID_MODE" in
  ip|name|hostname) ;;
  *) echo "Invalid --server-id: $SERVER_ID_MODE (use ip, name, or hostname)"; exit 2 ;;
esac

if [ "$SERVER_ID_MODE" = "name" ] && [ -z "$SERVER_NAME" ]; then
  echo "--server-id name requires --name NAME"
  exit 2
fi

if [ "$BOOTSTRAP" != "1" ] && [ -z "$ROOT_FOLDER_ID" ]; then
  echo "Google Drive Folder ID is required unless --bootstrap is used."
  exit 2
fi

mkdir -p "$TOOL_DIR" "$TOOL_DIR/logs" "$TOOL_DIR/backups"
chmod 700 "$TOOL_DIR" "$TOOL_DIR/logs" "$TOOL_DIR/backups"
for f in repair.sh diagnose.sh uninstall.sh configure-root.sh configure-server-id.sh; do
  cp -a "$SCRIPT_DIR/$f" "$TOOL_DIR/$f"
done

{
  printf 'ROOT_FOLDER_ID=%q\n' "$ROOT_FOLDER_ID"
  printf 'BOOTSTRAP=%q\n' "$BOOTSTRAP"
  printf 'SERVER_ID_MODE=%q\n' "$SERVER_ID_MODE"
  printf 'SERVER_NAME=%q\n' "$SERVER_NAME"
} > "$TOOL_DIR/config.env"

chmod 600 "$TOOL_DIR/config.env" "$TOOL_DIR"/*.sh
bash "$TOOL_DIR/repair.sh"

echo "Installed to $TOOL_DIR"
echo "Server ID mode: $SERVER_ID_MODE"
if [ "$SERVER_ID_MODE" = "name" ]; then
  echo "Fixed server name configured."
elif [ "$SERVER_ID_MODE" = "ip" ] && [ -n "$SERVER_NAME" ]; then
  echo "Public-IP mode with a configured fallback name."
fi

if [ "$BOOTSTRAP" = "1" ]; then
  echo "Bootstrap mode: run ONE small backup, find the new BT-Backup folder ID in Drive, then run:"
  echo "  sudo bash $TOOL_DIR/configure-root.sh <folder-id>"
else
  echo "Future repair: sudo bash $TOOL_DIR/repair.sh"
fi

echo "Change server ID mode later with:"
echo "  sudo bash $TOOL_DIR/configure-server-id.sh ip"
echo "  sudo bash $TOOL_DIR/configure-server-id.sh name web-prod-01"
echo "  sudo bash $TOOL_DIR/configure-server-id.sh hostname"
