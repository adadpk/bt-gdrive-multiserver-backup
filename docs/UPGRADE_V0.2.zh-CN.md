# 从 v0.1.x 升级到 v0.2.0

v0.2.0 新增服务器目录命名模式：`ip`、`name`、`hostname`。

如果服务器已经安装过 v0.1.x，不需要重新输入 Google Drive Folder ID。

## 升级

进入之前克隆的仓库目录：

```bash
cd bt-gdrive-multiserver-backup
git pull
sudo bash upgrade.sh
```

`upgrade.sh` 会：

- 保留 `/root/bt_gdrive_tool/config.env` 中已有的 Folder ID；
- 把旧版 `FALLBACK_SERVER_NAME` 自动迁移到新配置；
- 旧安装默认迁移为 `ip` 模式，保持原行为；
- 更新 `repair.sh`、`diagnose.sh`、`configure-root.sh` 等工具；
- 安装新的 `configure-server-id.sh`；
- 重新应用补丁并执行 Python 语法检查。

## 升级后选择模式

继续按公网 IP：

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh ip
```

改为固定名称（IP 变化后仍使用同一个目录）：

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh name web-prod-01
```

使用系统 hostname：

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh hostname
```

## 注意

切换服务器标识模式不会移动或重命名 Google Drive 中已经存在的历史目录。

例如原来有：

```text
BT-Backup/203.0.113.10/
```

切换固定名称 `web-prod-01` 后，下一次备份会进入：

```text
BT-Backup/web-prod-01/
```

旧的 `203.0.113.10` 目录仍会保留。
