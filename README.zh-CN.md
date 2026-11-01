# bt-gdrive-multiserver-backup

这是一个针对 **宝塔 / aaPanel「谷歌云网盘 2.5」插件**的非官方多服务器备份目录补丁。

适用场景：多台服务器共用同一个 Google Drive 账号做网站、数据库和目录备份，希望所有备份统一放进一个总目录，同时避免不同服务器的同名目录互相串线。

最终目录结构：

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

默认使用服务器当前公网 IPv4 作为子目录名。公网 IP 获取失败时，可回退到安装时指定的名称，再回退到主机名。

> 本项目是社区非官方补丁，与宝塔、aaPanel、Google、Google Drive 无隶属或官方合作关系。

## 修改内容

运行时只修改服务器上已经存在的两个文件：

```text
/www/server/panel/plugin/gdrive/gdrive_main.py
/www/server/panel/class/CloudStoraUpload.py
```

仓库**不会包含**官方插件源码副本、`credentials.json`、OAuth Token、Client Secret 或个人 Google Drive Folder ID。

主要功能：

- 多台服务器共用同一个 `BT-Backup` 根目录；
- 每台服务器自动按公网 IPv4 分目录；
- 继续区分 `web / db / path`；
- 修复原插件按“文件夹名称”全盘查找导致的同名目录冲突风险；
- 每次修补前自动备份原文件；
- 代码结构不匹配时停止并回滚，避免硬改新版宝塔文件；
- 提供脱敏诊断脚本，方便升级后快速定位。

## 兼容性

目前按以下环境设计并验证：

- 宝塔 / aaPanel 谷歌云网盘插件 **2.5**；
- 默认面板路径 `/www/server/panel/`。

未来宝塔或插件升级后代码结构可能变化。如果脚本提示“不兼容”，不要强行替换，请提交诊断结果。

## 推荐安装流程

### 第一台服务器：让插件自己创建 BT-Backup

谷歌云网盘插件使用 `drive.file` 授权范围时，网页手工创建的文件夹不一定能被插件访问，因此推荐第一台使用引导模式：

```bash
sudo bash install.sh --bootstrap
```

然后在宝塔计划任务里手动执行一个较小的 Google Drive 备份。

正常会出现：

```text
BT-Backup/<当前服务器公网IP>/...
```

进入 Google Drive 的 `BT-Backup`，复制地址栏 `/folders/` 后面的 Folder ID：

```text
https://drive.google.com/drive/folders/FOLDER_ID
```

再在第一台执行：

```bash
sudo bash /root/bt_gdrive_tool/configure-root.sh FOLDER_ID
```

### 其他服务器

先安装并授权谷歌云网盘 2.5，且使用同一个 Google 账号，然后执行：

```bash
sudo bash install.sh FOLDER_ID
```

所有服务器使用相同的 Folder ID，但会自动进入各自的公网 IP 目录。

## 升级后一键恢复

安装后工具固定放在：

```text
/root/bt_gdrive_tool/
```

宝塔升级或谷歌云网盘插件升级导致补丁失效时，只需要：

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

不需要重新输入 Folder ID。

## 诊断

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

诊断文件不会输出 Folder ID 明文，也不会读取/打印：

- `credentials.json` 内容；
- access token / refresh token；
- Google Client Secret；
- 网站或数据库备份内容。

提交 Issue 时建议只上传诊断 TXT。

## 回滚

每次修复前都会把原文件保存在：

```text
/root/bt_gdrive_tool/backups/
```

恢复最近一次修复前的文件：

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

这只恢复两个被修改的 Python 文件，不会卸载官方 Google Drive 插件。

## 安全提醒

不要上传或提交以下文件：

```text
credentials.json
config.conf
token.json
gdrive_token.json
/root/bt_gdrive_tool/config.env
*.log
```

详细见 [SECURITY.md](SECURITY.md)。

## 原理

见 [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md)。

## 升级恢复

见 [docs/UPGRADE_RECOVERY.md](docs/UPGRADE_RECOVERY.md)。

## License

本仓库自行编写的补丁脚本与文档采用 MIT License。运行时被修改的第三方软件仍遵循其原有版权和许可证。
