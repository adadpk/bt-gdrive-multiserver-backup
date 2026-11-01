# 中文安装指南

本文档适用于 **宝塔 / aaPanel 谷歌云网盘 2.5**。

## 一、安装前准备

请先确认：

1. 宝塔已安装“谷歌云网盘 2.5”；
2. Google Drive 已授权成功；
3. 多台服务器准备使用同一个 Google Drive 账号；
4. 服务器可以访问 GitHub；
5. 你有 root 权限。

## 二、第一台服务器

第一台建议让插件自己创建 `BT-Backup`，避免 `drive.file` 权限导致网页手工创建的目录不可访问。

```bash
git clone https://github.com/adadpk/bt-gdrive-multiserver-backup.git
cd bt-gdrive-multiserver-backup
sudo bash install.sh --bootstrap
```

安装完成后，在宝塔里手动执行一个较小的 Google Drive 备份任务。

正常应出现：

```text
BT-Backup/<公网IP>/...
```

进入 `BT-Backup`，复制地址中的 Folder ID：

```text
https://drive.google.com/drive/folders/FOLDER_ID
```

然后执行：

```bash
sudo bash /root/bt_gdrive_tool/configure-root.sh FOLDER_ID
```

## 三、其他服务器

每台服务器先安装并授权同一个 Google Drive 账号，然后：

```bash
git clone https://github.com/adadpk/bt-gdrive-multiserver-backup.git
cd bt-gdrive-multiserver-backup
sudo bash install.sh FOLDER_ID
```

安装脚本会自动：

- 备份原文件；
- 写入共享 Folder ID；
- 修补 Google Drive 路径逻辑；
- 自动获取当前公网 IPv4；
- 做 Python 语法检查；
- 保存恢复脚本和诊断脚本。

## 四、验证是否成功

执行：

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

再去宝塔手动执行一个小备份。

Google Drive 应出现：

```text
BT-Backup/
├── 第一台服务器IP/
└── 当前服务器IP/
```

## 五、升级后失效

直接执行：

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

如果脚本提示结构不兼容：

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

把生成的诊断 TXT 提交到 GitHub Issue。

## 六、回滚

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

这会恢复最近一次修复前备份的两个 Python 文件。
