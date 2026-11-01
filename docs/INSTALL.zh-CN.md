# 中文安装指南

本文档适用于 **宝塔 / aaPanel 谷歌云网盘 2.5**。

## 一、安装前准备

请先确认：

1. 宝塔已安装“谷歌云网盘 2.5”；
2. Google Drive 已授权成功；
3. 多台服务器准备使用同一个 Google Drive 账号；
4. 服务器可以访问 GitHub；
5. 你有 root 权限。

## 二、选择服务器目录命名方式

v0.2.0 支持三种模式：

```text
ip        当前公网 IPv4，默认
name      固定自定义名称
hostname  系统 hostname
```

建议：

- VPS 固定 IP：用 `ip`；
- IP 可能变化、迁移服务器：用 `name`；
- 已有统一主机名规范：用 `hostname`。

## 三、第一台服务器

第一台建议让插件自己创建 `BT-Backup`，避免 `drive.file` 权限导致网页手工创建的目录不可访问。

默认 IP 模式：

```bash
git clone https://github.com/adadpk/bt-gdrive-multiserver-backup.git
cd bt-gdrive-multiserver-backup
sudo bash install.sh --bootstrap
```

固定名称模式：

```bash
sudo bash install.sh --bootstrap --server-id name --name web-prod-01
```

hostname 模式：

```bash
sudo bash install.sh --bootstrap --server-id hostname
```

安装完成后，在宝塔里手动执行一个较小的 Google Drive 备份任务。

正常应出现：

```text
BT-Backup/<服务器标识>/...
```

进入 `BT-Backup`，复制地址中的 Folder ID：

```text
https://drive.google.com/drive/folders/FOLDER_ID
```

然后执行：

```bash
sudo bash /root/bt_gdrive_tool/configure-root.sh FOLDER_ID
```

## 四、其他服务器

每台服务器先安装并授权同一个 Google Drive 账号，然后根据需要选择模式。

默认 IP：

```bash
git clone https://github.com/adadpk/bt-gdrive-multiserver-backup.git
cd bt-gdrive-multiserver-backup
sudo bash install.sh FOLDER_ID
```

固定名称：

```bash
sudo bash install.sh FOLDER_ID --server-id name --name db-prod-01
```

hostname：

```bash
sudo bash install.sh FOLDER_ID --server-id hostname
```

旧版命令仍兼容：

```bash
sudo bash install.sh FOLDER_ID fallback-name
```

这表示 IP 模式，只有公网 IP 获取失败时才使用 `fallback-name`。

## 五、已安装服务器切换模式

无需重装：

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh ip
sudo bash /root/bt_gdrive_tool/configure-server-id.sh name web-prod-01
sudo bash /root/bt_gdrive_tool/configure-server-id.sh hostname
```

切换后只影响新备份，不会自动移动 Google Drive 中的历史目录。

## 六、验证是否成功

执行：

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

再去宝塔手动执行一个小备份。

例如固定名称模式应出现：

```text
BT-Backup/
└── web-prod-01/
    ├── web/
    ├── db/
    └── path/
```

## 七、升级后失效

直接执行：

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

之前保存的 Folder ID 和服务器标识模式会继续生效。

如果脚本提示结构不兼容：

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

把生成的诊断 TXT 提交到 GitHub Issue。

## 八、回滚

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

这会恢复最近一次修复前备份的两个 Python 文件。
