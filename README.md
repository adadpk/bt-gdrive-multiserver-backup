# 宝塔 / aaPanel Google Drive 多服务器统一备份目录补丁

[English](README.en.md) | 中文

这是一个针对 **宝塔 / aaPanel「谷歌云网盘 2.5」插件**的非官方多服务器备份目录补丁。

适用场景：你有多台服务器，都把网站、数据库或目录备份到同一个 Google Drive 账号，但原插件容易出现多个 `bt_backup`、同名目录混乱，甚至不同服务器之间目录难以区分。

这个项目把备份目录统一成：

```text
BT-Backup/
├── 203.0.113.10/
│   ├── web/
│   ├── db/
│   └── path/
├── web-prod-01/
│   ├── web/
│   ├── db/
│   └── path/
└── ...
```

## v0.2.0：服务器目录命名可选

现在支持 3 种服务器标识模式：

| 模式 | 目录名来源 | 适合场景 |
|---|---|---|
| `ip` | 当前公网 IPv4 | 固定 IP VPS；默认模式 |
| `name` | 自定义固定名称 | IP 会变化、迁移服务器、想长期保持目录不变 |
| `hostname` | Linux 系统 hostname | 已有规范主机名管理 |

### 1. 默认：按公网 IP

```bash
sudo bash install.sh FOLDER_ID --server-id ip
```

目录类似：

```text
BT-Backup/203.0.113.10/
```

如果公网 IP 改变，后续备份会进入新的 IP 目录，旧目录不会删除。

### 2. 固定名称：推荐给 IP 可能变化的服务器

```bash
sudo bash install.sh FOLDER_ID --server-id name --name web-prod-01
```

无论服务器 IP 怎么变化，都会继续进入：

```text
BT-Backup/web-prod-01/
```

### 3. 使用系统 hostname

```bash
sudo bash install.sh FOLDER_ID --server-id hostname
```

### 已安装服务器直接切换

不需要重装：

```bash
# 切回公网 IP
sudo bash /root/bt_gdrive_tool/configure-server-id.sh ip

# 改成固定名称
sudo bash /root/bt_gdrive_tool/configure-server-id.sh name web-prod-01

# 改成系统 hostname
sudo bash /root/bt_gdrive_tool/configure-server-id.sh hostname
```

> 切换模式不会自动移动 Google Drive 里已有的历史备份，只会影响之后的新备份路径。

---

## 解决什么问题

原版多服务器共用同一个 Google Drive 时，常见问题包括：

- Drive 根目录出现多个 `bt_backup`；
- 不同服务器的备份目录混在一起；
- 同名 `sites / database / path` 或其他目录容易混淆；
- 插件升级或宝塔升级后，自定义修改可能被覆盖；
- 后续排查时很难判断到底是插件层还是宝塔核心层在生成路径。

本项目会：

- 多台服务器共用一个 `BT-Backup` 总目录；
- 每台服务器可按公网 IP、固定名称或 hostname 分目录；
- 保留 `web / db / path` 分类；
- 修复 Google Drive 文件夹查找时只按名字匹配、未限定父目录的问题；
- 每次修补前自动备份原文件；
- 宝塔/插件升级后提供一键恢复；
- 提供脱敏诊断脚本，方便升级后快速定位；
- 代码结构不匹配时停止并回滚，避免硬改新版文件。

## 兼容性

当前按以下环境设计并验证：

- 宝塔 / aaPanel 谷歌云网盘插件 **2.5**；
- Linux；
- 默认面板路径 `/www/server/panel/`。

未来宝塔或插件升级后代码结构可能变化。如果脚本提示不兼容，请不要强行替换，建议先运行诊断脚本并提交 Issue。

详细见 [COMPATIBILITY.md](COMPATIBILITY.md)。

## 推荐安装方式

### 第一台服务器：让插件自己创建 BT-Backup

因为 Google Drive 插件常使用 `drive.file` 授权范围，网页手工创建的文件夹不一定能被插件访问，所以第一台推荐使用引导模式：

```bash
git clone https://github.com/adadpk/bt-gdrive-multiserver-backup.git
cd bt-gdrive-multiserver-backup
sudo bash install.sh --bootstrap
```

然后去宝塔：

```text
计划任务 → 找一个较小的网站/数据库备份 → 手动执行
```

正常会在 Google Drive 自动出现：

```text
BT-Backup/<当前服务器标识>/...
```

进入 `BT-Backup`，从浏览器地址栏复制 Folder ID：

```text
https://drive.google.com/drive/folders/FOLDER_ID
```

再执行：

```bash
sudo bash /root/bt_gdrive_tool/configure-root.sh FOLDER_ID
```

第一台也可以在 bootstrap 时指定固定名称：

```bash
sudo bash install.sh --bootstrap --server-id name --name web-prod-01
```

### 其他服务器

先安装并授权同一个 Google Drive 账号，然后根据需要选择一种模式：

```bash
# 默认：按公网 IP
sudo bash install.sh FOLDER_ID

# 固定名称
sudo bash install.sh FOLDER_ID --server-id name --name db-prod-01

# hostname
sudo bash install.sh FOLDER_ID --server-id hostname
```

旧版命令仍兼容：

```bash
sudo bash install.sh FOLDER_ID fallback-name
```

它等价于：**IP 模式 + 公网 IP 获取失败时使用 fallback-name**。

## 升级后失效怎么办

宝塔升级可能覆盖：

```text
/www/server/panel/class/CloudStoraUpload.py
```

Google Drive 插件升级、修复或重装可能覆盖：

```text
/www/server/panel/plugin/gdrive/gdrive_main.py
```

升级后如果目录恢复成 `bt_backup`，直接执行：

```bash
sudo bash /root/bt_gdrive_tool/repair.sh
```

Folder ID 和服务器标识模式都会继续读取之前保存的配置，不需要重新输入。

## 诊断

如果升级后修复失败，执行：

```bash
sudo bash /root/bt_gdrive_tool/diagnose.sh
```

诊断脚本会显示当前服务器标识模式，但不会输出：

- `credentials.json` 内容；
- OAuth access token；
- refresh token；
- Google Client Secret；
- 网站或数据库备份内容；
- Folder ID 明文；
- 公网 IP 明文；
- 自定义服务器名称明文。

提交 Issue 时建议只上传诊断 TXT。

## 回滚

每次修复前都会保存原文件：

```text
/root/bt_gdrive_tool/backups/
```

恢复最近一次修复前的版本：

```bash
sudo bash /root/bt_gdrive_tool/uninstall.sh
```

这只恢复被修改的两个 Python 文件，不会卸载官方 Google Drive 插件。

## 项目会修改哪些文件

只修改服务器上现有的：

```text
/www/server/panel/plugin/gdrive/gdrive_main.py
/www/server/panel/class/CloudStoraUpload.py
```

并在插件目录写入运行时配置：

```text
root_folder_id.conf
server_id_mode.conf
server_name.conf
```

仓库本身不会发布宝塔官方插件源码副本，也不会包含你的 Google Drive 授权信息。

## 安全提醒

不要把下面这些文件上传到 GitHub、论坛或公开网盘：

```text
credentials.json
config.conf
token.json
gdrive_token.json
/root/bt_gdrive_tool/config.env
*.log
```

详细见 [SECURITY.md](SECURITY.md)。

## 更多中文文档

- [中文完整说明](README.zh-CN.md)
- [中文安装指南](docs/INSTALL.zh-CN.md)
- [中文 FAQ](docs/FAQ.zh-CN.md)
- [工作原理](docs/HOW_IT_WORKS.md)
- [升级恢复](docs/UPGRADE_RECOVERY.md)
- [兼容性](COMPATIBILITY.md)
- [安全说明](SECURITY.md)

## License

本仓库自行编写的补丁脚本与文档采用 MIT License。运行时被修改的第三方软件仍遵循其原有版权和许可证。
