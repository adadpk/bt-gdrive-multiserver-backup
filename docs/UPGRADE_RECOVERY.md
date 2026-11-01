# Upgrade recovery

Two upstream files are modified at runtime:

```text
/www/server/panel/plugin/gdrive/gdrive_main.py
/www/server/panel/class/CloudStoraUpload.py
```

A Google Drive plugin update/repair/reinstall may overwrite `gdrive_main.py`.
A BT Panel / aaPanel core update may overwrite `CloudStoraUpload.py`.

After an update, run:

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

If the markers are missing, repair with:

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

If repair reports an unsupported structure, stop there. Do not use a global search-and-replace on `bt_backup`, because `CloudStoraUpload.py` can serve other storage providers too.

Open an issue and attach the redacted diagnostic output plus the panel/plugin version. Do not attach OAuth credentials or token files.
