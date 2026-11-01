# v0.2.0 Release Notes

This release adds selectable server folder naming while keeping the original public-IP behavior as the default.

Highlights:

- `ip` mode: use current public IPv4 (default);
- `name` mode: use a stable custom folder name even when the server IP changes;
- `hostname` mode: use the Linux system hostname;
- switch an installed server without reinstalling via `configure-server-id.sh`;
- persist the selected mode for future scheduled backups and post-upgrade repairs;
- keep v0.1.x install syntax backward compatible;
- diagnostics report the active mode while redacting Folder IDs, IP values, and custom server names;
- shared `BT-Backup` root, parent-aware folder resolution, safe backups, rollback, and one-command upgrade repair remain included.

Examples:

```bash
sudo bash install.sh FOLDER_ID --server-id ip
sudo bash install.sh FOLDER_ID --server-id name --name web-prod-01
sudo bash install.sh FOLDER_ID --server-id hostname
```

Switch later:

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh name web-prod-01
```

Before installing, read `README.md`, `docs/INSTALL.zh-CN.md`, and `SECURITY.md`.
