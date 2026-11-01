# 中文 FAQ

## 1. 这个项目适合什么场景？

适合多台宝塔 / aaPanel 服务器共用同一个 Google Drive 账号做网站、数据库和目录备份，希望所有备份集中在一个 `BT-Backup` 总目录，并按服务器自动分开的场景。

## 2. 为什么不用一个 `bt_backup` 直接混在一起？

多台服务器直接共用同一层目录，容易出现同名站点、数据库和目录混淆，也不利于后续清理、排错和迁移。本项目默认使用公网 IPv4 作为服务器子目录。

## 3. 服务器 IP 变了怎么办？

下一次备份会自动使用新的公网 IPv4 目录。旧 IP 目录不会自动删除，这样可以保留历史备份归属。

## 4. 为什么建议第一台让插件自己创建 BT-Backup？

谷歌云网盘插件常使用 `drive.file` 授权范围。网页手工新建的 Google Drive 文件夹不一定能被插件访问，所以第一台用 `--bootstrap` 让插件自己创建最稳。

## 5. 宝塔升级后会失效吗？

有可能。宝塔面板升级可能覆盖 `CloudStoraUpload.py`；Google Drive 插件升级、修复或重装可能覆盖 `gdrive_main.py`。

升级后如失效，执行：

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

## 6. repair.sh 会不会把新版宝塔改坏？

脚本会先检查预期代码结构，并在修改前备份原文件。如果结构不匹配，会停止并尝试回滚，而不是盲目替换。

## 7. Folder ID 会不会上传到 GitHub？

不会。公开仓库不包含任何用户的 Folder ID。安装后 Folder ID 只保存在本机：

```text
/root/bt_gdrive_tool/config.env
```

建议权限保持为 `600`。

## 8. 诊断脚本会泄漏 Token 吗？

设计上不会读取或打印 `credentials.json`、access token、refresh token、Client Secret，也不会输出 Folder ID 明文。

## 9. 可以自定义服务器目录名吗？

可以在安装时传入回退名称：

```bash
sudo bash install.sh FOLDER_ID us-vps-01
```

正常情况下仍优先使用公网 IPv4；公网 IP 获取失败时才使用这个名称。

## 10. 如何完全撤销修改？

执行：

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

它会恢复最近一次修复前备份的两个 Python 文件，不会卸载官方 Google Drive 插件。

## 11. 支持哪些版本？

当前主要按宝塔 / aaPanel 谷歌云网盘插件 2.5 设计。其他版本如果代码结构不同，可能需要重新适配。

## 12. 出现不兼容错误怎么办？

先运行：

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

然后把生成的诊断 TXT 提交到 GitHub Issue，避免直接上传整个插件目录或授权文件。
