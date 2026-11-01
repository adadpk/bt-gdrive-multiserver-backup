# bt-gdrive-multiserver-backup

Unofficial multi-server path patch for the **BT Panel / aaPanel Google Drive backup plugin 2.5**.

It helps multiple servers share one Google Drive backup root while keeping each server isolated in its own subfolder.

```text
BT-Backup/
├── 203.0.113.10/
│   ├── web/
│   ├── db/
│   └── path/
├── web-prod-01/
│   ├── web/
│   ├── db/
│   └── path/
└── ...
```

> This is an **unofficial community patch**. It is not affiliated with, endorsed by, or distributed by BT.cn, aaPanel, Google, or Google Drive.

## v0.2.0: selectable server ID modes

Three modes are supported:

| Mode | Folder name source | Best for |
|---|---|---|
| `ip` | current public IPv4 | fixed-IP VPS; default |
| `name` | custom fixed name | changing IPs, migrations, stable naming |
| `hostname` | system hostname | managed hostname environments |

Examples:

```bash
sudo bash install.sh FOLDER_ID --server-id ip
sudo bash install.sh FOLDER_ID --server-id name --name web-prod-01
sudo bash install.sh FOLDER_ID --server-id hostname
```

Switch an already installed server without reinstalling:

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh ip
sudo bash /root/bt_gdrive_tool/configure-server-id.sh name web-prod-01
sudo bash /root/bt_gdrive_tool/configure-server-id.sh hostname
```

Changing the mode only affects future backups. Existing Google Drive folders are not moved automatically.

## What this project changes

The patch modifies two files already present on the server:

```text
/www/server/panel/plugin/gdrive/gdrive_main.py
/www/server/panel/class/CloudStoraUpload.py
```

It does **not** ship the vendor's plugin source code, credentials, OAuth tokens, or Google Drive secrets.

Main changes:

- use one shared Google Drive root folder;
- create a separate subfolder per server;
- selectable server identifiers (`ip`, `name`, `hostname`);
- make Google Drive folder lookup parent-aware to avoid same-name folder collisions;
- preserve `web`, `db`, and `path` subdirectories;
- back up modified files before every repair;
- stop and roll back when the expected code structure is not found;
- include privacy-redacted diagnostics.

## Compatibility

Verified design target:

- BT Panel / aaPanel Google Drive plugin **2.5**
- Linux panel installations using the default paths under `/www/server/panel/`

A future panel/plugin update may change the Python structure. In that case the repair script is designed to stop instead of blindly replacing unrelated code.

## First server

Clone/download this repository, then run bootstrap mode:

```bash
git clone https://github.com/adadpk/bt-gdrive-multiserver-backup.git
cd bt-gdrive-multiserver-backup
sudo bash install.sh --bootstrap
```

You can also bootstrap directly with a fixed server name:

```bash
sudo bash install.sh --bootstrap --server-id name --name web-prod-01
```

Run one small backup from BT Panel. Open the newly created `BT-Backup` folder in Google Drive and copy its folder ID from the URL, then configure it:

```bash
sudo bash /root/bt_gdrive_tool/configure-root.sh FOLDER_ID_HERE
```

## Additional servers

Authorize the Google Drive 2.5 plugin with the **same Google account**, then run one of:

```bash
sudo bash install.sh FOLDER_ID_HERE
sudo bash install.sh FOLDER_ID_HERE --server-id name --name db-prod-01
sudo bash install.sh FOLDER_ID_HERE --server-id hostname
```

The legacy form remains supported:

```bash
sudo bash install.sh FOLDER_ID_HERE fallback-name
```

That means IP mode with a fallback name if public-IP detection fails.

## One-command repair after an upgrade

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

The saved Folder ID and server-ID mode are reused automatically.

## Diagnostics

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

Diagnostics report the active mode but redact the Folder ID, public IP value, and custom server name.

## Rollback

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

## Security

Never commit credentials, OAuth tokens, private folder IDs, or runtime configuration. See [SECURITY.md](SECURITY.md).

## License

The patch scripts and documentation in this repository are released under the MIT License. Third-party software modified at runtime remains under its own license and copyright.
