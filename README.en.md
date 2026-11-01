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

## Diagnostics

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

## Rollback

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

## Security

Never commit credentials, OAuth tokens, private folder IDs, or diagnostic logs containing private infrastructure details. See [SECURITY.md](SECURITY.md).

## License

The patch scripts and documentation in this repository are released under the MIT License. Third-party software modified at runtime remains under its own license and copyright.
