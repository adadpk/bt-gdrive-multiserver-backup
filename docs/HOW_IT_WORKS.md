# How it works

## The problem

The stock Google Drive 2.5 path generation uses generic `bt_backup/...` paths. Its folder lookup also searches primarily by folder name. Google Drive allows multiple folders with the same name, so a multi-server setup can become difficult to identify and, depending on the call path, can select a same-named folder from a different parent.

## Patched flow

```text
BT Panel scheduled backup
        |
        v
CloudStoraUpload.py
        |
        v
gdrive_main.py
        |
        v
shared Google Drive root folder ID
        |
        v
<server public IPv4>/web|db|path/
```

Two layers are patched because different backup paths in the panel can generate remote object names at different points.

## Parent-aware folder lookup

Instead of querying only for a folder name, the patched Google Drive helper includes the parent folder ID in the Drive API query. That makes `web`, `db`, and site/database subfolders deterministic even when multiple servers use the same names.

## Public-IP server identifier

The patch queries `https://api4.ipify.org` with a short timeout. If the lookup fails it uses the configured fallback name; if that is empty it uses the host name.

If a VPS public IP changes, future backups naturally go into a new IP directory. The previous IP directory remains as historical data; it is not renamed or deleted automatically.
