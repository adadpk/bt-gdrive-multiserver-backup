# Changelog

## 0.2.0

- Added selectable server ID modes: `ip`, `name`, and `hostname`.
- `ip` remains the default and keeps backward compatibility with v0.1.x.
- Added `configure-server-id.sh` so installed servers can switch modes without reinstalling.
- Added persistent runtime mode configuration via `server_id_mode.conf`.
- Added fixed-name mode for servers whose public IP may change.
- Updated diagnostics to report the active mode while redacting custom names and IP values.

## 0.1.0

- Initial public release.
- Shared `BT-Backup` root folder support.
- Per-server public IPv4 directories.
- Parent-aware Google Drive folder lookup.
- Safe backup/rollback before patching.
- One-command post-upgrade repair.
- Redacted diagnostics.
