# 中文 FAQ

## 1. 这个项目适合什么场景？

适合多台宝塔 / aaPanel 服务器共用同一个 Google Drive 账号做网站、数据库和目录备份，希望所有备份集中在一个 `BT-Backup` 总目录，并按服务器自动分开的场景。

## 2. 为什么不用一个 `bt_backup` 直接混在一起？

多台服务器直接共用同一层目录，容易出现同名站点、数据库和目录混淆，也不利于后续清理、排错和迁移。

## 3. 服务器 IP 变了怎么办？

如果使用默认 `ip` 模式，下一次备份会自动使用新的公网 IPv4 目录。旧 IP 目录不会自动删除。

如果不希望 IP 变化导致新目录，建议切换成固定名称模式：

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh name web-prod-01
```

之后无论 IP 怎么变化，都继续进入：

```text
BT-Backup/web-prod-01/
```

## 4. 支持哪些服务器目录命名模式？

支持 3 种：

```text
ip        当前公网 IPv4，默认
name      自定义固定名称
hostname  Linux 系统 hostname
```

安装时示例：

```bash
sudo bash install.sh FOLDER_ID --server-id ip
sudo bash install.sh FOLDER_ID --server-id name --name web-prod-01
sudo bash install.sh FOLDER_ID --server-id hostname
```

## 5. 已经安装好了，还能切换模式吗？

可以，不需要重装：

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh ip
sudo bash /root/bt_gdrive_tool/configure-server-id.sh name web-prod-01
sudo bash /root/bt_gdrive_tool/configure-server-id.sh hostname
```

切换后只影响之后的新备份，不会自动移动历史目录。

## 6. 为什么建议第一台让插件自己创建 BT-Backup？

谷歌云网盘插件常使用 `drive.file` 授权范围。网页手工新建的 Google Drive 文件夹不一定能被插件访问，所以第一台用 `--bootstrap` 让插件自己创建最稳。

## 7. 宝塔升级后会失效吗？

有可能。宝塔面板升级可能覆盖 `CloudStoraUpload.py`；Google Drive 插件升级、修复或重装可能覆盖 `gdrive_main.py`。

升级后如失效，执行：

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

## 8. repair.sh 会不会把新版宝塔改坏？

脚本会先检查预期代码结构，并在修改前备份原文件。如果结构不匹配，会停止并尝试回滚，而不是盲目替换。

## 9. Folder ID 会不会上传到 GitHub？

不会。公开仓库不包含任何用户的 Folder ID。安装后 Folder ID 只保存在本机：

```text
/root/bt_gdrive_tool/config.env
```

建议权限保持为 `600`。

## 10. 诊断脚本会泄漏 Token、IP 或自定义名称吗？

设计上不会读取或打印 `credentials.json`、access token、refresh token、Client Secret，也不会输出 Folder ID、公网 IP 或自定义服务器名称明文。

## 11. 可以自定义服务器目录名吗？

可以，直接使用固定名称模式：

```bash
sudo bash install.sh FOLDER_ID --server-id name --name us-vps-01
```

或者已安装后切换：

```bash
sudo bash /root/bt_gdrive_tool/configure-server-id.sh name us-vps-01
```

## 12. 旧版的 fallback-name 参数还能用吗？

可以。下面旧命令仍兼容：

```bash
sudo bash install.sh FOLDER_ID us-vps-01
```

它表示：仍使用 `ip` 模式，但公网 IP 获取失败时回退到 `us-vps-01`。

## 13. 如何完全撤销修改？

执行：

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

它会恢复最近一次修复前备份的两个 Python 文件，不会卸载官方 Google Drive 插件。

## 14. 支持哪些版本？

当前主要按宝塔 / aaPanel 谷歌云网盘插件 2.5 设计。其他版本如果代码结构不同，可能需要重新适配。

## 15. 出现不兼容错误怎么办？

先运行：

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

然后把生成的诊断 TXT 提交到 GitHub Issue，避免直接上传整个插件目录或授权文件。
