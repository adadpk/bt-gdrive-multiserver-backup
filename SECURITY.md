# Security Policy

## Never publish these files

Do not attach, commit, paste, or upload any of the following from a live server:

- `/www/server/panel/plugin/gdrive/credentials.json`
- `/www/server/panel/plugin/gdrive/config.conf`
- `/www/server/panel/plugin/gdrive/token.json`
- `/root/gdrive_token.json`
- `/root/credentials.json`
- `/root/bt_gdrive_tool/config.env`
- raw backup archives or database dumps
- full panel logs that may contain access tokens or private URLs

The built-in `diagnose.sh` intentionally redacts the configured Google Drive Folder ID **and the public IPv4 value**, and does not print token files.

## Reporting a vulnerability

Please open a minimal GitHub issue without secrets. If sensitive material is required to reproduce a security issue, use a private disclosure channel rather than a public issue.
