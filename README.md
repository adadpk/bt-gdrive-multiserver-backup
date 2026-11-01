# bt-gdrive-multiserver-backup

Unofficial multi-server path patch for the **BT Panel / aaPanel Google Drive backup plugin 2.5**.

It fixes a practical problem when several servers back up into the same Google Drive account: the stock plugin can create or reuse generic `bt_backup` folders and may resolve same-named folders without constraining the parent folder. This project changes the layout to:

```text
BT-Backup/
├── 203.0.113.10/
│   ├── web/
│   ├── db/
│   └── path/
├── 203.0.113.11/
│   ├── web/
│   ├── db/
│   └── path/
└── ...
```

The server subfolder defaults to the current public IPv4 address. If public-IP detection fails, an optional fallback name and then the hostname are used.

> This is an **unofficial community patch**. It is not affiliated with, endorsed by, or distributed by BT.cn, aaPanel, Google, or Google Drive.

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
- use public IPv4 as the default server identifier;
- make Google Drive folder lookup parent-aware to avoid same-name folder collisions;
- preserve `web`, `db`, and `path` subdirectories;
- back up modified files before every repair;
- stop and roll back when the expected code structure is not found;
- include a redacted diagnostic script for upgrade troubleshooting.

## Compatibility

Verified design target:

- BT Panel / aaPanel Google Drive plugin **2.5**
- Linux panel installations using the default paths under `/www/server/panel/`

A future panel/plugin update may change the Python structure. In that case the repair script is designed to stop instead of blindly replacing unrelated code.

## Recommended setup

### A. First server: let the plugin create `BT-Backup`

This is the safest route when the Google Drive plugin uses the `drive.file` OAuth scope, because a folder manually created in the Drive web UI may not always be visible to the app.

Clone/download this repository, then run:

```bash
sudo bash install.sh --bootstrap
```

Run **one small backup** from BT Panel. A new folder should appear:

```text
BT-Backup/<this-server-public-ip>/...
```

Open `BT-Backup` in Google Drive and copy the folder ID from the URL:

```text
https://drive.google.com/drive/folders/FOLDER_ID_HERE
```

Then configure that shared root on the first server:

```bash
sudo bash /root/bt_gdrive_tool/configure-root.sh FOLDER_ID_HERE
```

### B. Additional servers

Authorize the Google Drive 2.5 plugin with the **same Google account**, then run:

```bash
sudo bash install.sh FOLDER_ID_HERE
```

Every server uses the same root folder ID, while its backup files go under its own public-IP subfolder.

## One-command repair after an upgrade

After installation, the tool lives here:

```text
/root/bt_gdrive_tool/
```

If a BT Panel update or Google Drive plugin update overwrites the patch, run:

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

The configured folder ID is stored locally in:

```text
/root/bt_gdrive_tool/config.env
```

with mode `600` permissions.

## Optional fallback server name

If a server cannot reach the public-IP lookup endpoint, provide a fallback name during installation:

```bash
sudo bash install.sh FOLDER_ID_HERE us-vps-01
```

The normal order is:

1. current public IPv4;
2. fallback name;
3. hostname.

## Diagnostics

Run:

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

It creates a diagnostic TXT under `/root/bt_gdrive_tool/` and prints it to the terminal.

The diagnostic output intentionally redacts the Google Drive folder ID and does not read or print:

- `credentials.json` contents;
- OAuth access tokens;
- refresh tokens;
- Google client secrets;
- website/database backup contents.

When opening an issue, attach the diagnostic TXT rather than uploading your entire plugin directory.

## Rollback

Each repair creates a timestamped snapshot under:

```text
/root/bt_gdrive_tool/backups/
```

To restore the newest snapshot:

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

Note: this restores the latest pre-repair copies of the two modified Python files. It does not uninstall the official Google Drive plugin.

## Security notes

Never commit or upload these files:

```text
credentials.json
config.conf
token.json
gdrive_token.json
*.log
/root/bt_gdrive_tool/config.env
```

See [SECURITY.md](SECURITY.md).

## How it works

See [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md).

## Upgrade recovery

See [docs/UPGRADE_RECOVERY.md](docs/UPGRADE_RECOVERY.md).

## License

The patch scripts and documentation in this repository are released under the MIT License. Third-party software modified at runtime remains under its own license and copyright.
