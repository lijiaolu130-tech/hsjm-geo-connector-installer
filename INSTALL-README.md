# 华昇金玛 GEO 连接器安装助手

本目录包含两种本地安装助手（fix3）：

- `HSJM-GEO-Connector-Install.command`：macOS，双击运行。
- `HSJM-GEO-Connector-Install.ps1`：Windows PowerShell，右键使用 PowerShell 运行。

助手下载公开 ZIP、校验 SHA-256、解压到版本化目录，并优先启动一个独立的 GEO 专用 Chrome for Testing 配置，通过 `--load-extension` 自动载入连接器。若本机没有 Chrome for Testing，助手会从 Chrome for Testing 官方公开清单自动下载对应架构；现有 Chrome 的窗口、登录态和扩展配置不会被修改。网络不稳定时，助手会先走 GitHub API 二进制入口，再回退 Release 直链；如果 Downloads 里已有同 SHA-256 的包，则直接复用。

这条专用浏览器路线不依赖普通 Chrome 的文件选择器，也不会把扩展强行写入你的日常 Chrome。机器上已有 Chrome for Testing 时会自动载入；没有时会自动下载到 GEO 专用目录；首次打开专用窗口后，只需在门户中完成所有者登录；平台验证码、实名和风控按平台要求人工完成。

如果自动下载官方浏览器失败，或你明确要使用现有 Chrome，仍可选择 ZIP 手动加载：打开“开发者模式”→“加载未打包的扩展程序”→选择能直接看到 `manifest.json` 的最外层文件夹。

不能在手机、微信内置浏览器或普通网页中安装 Chrome 扩展；不要直接选择 ZIP、`assets` 或 `src` 文件夹。

安装包 SHA-256：

`776e8cfa71276895a1e73496cbe91bffd3fa9f81afb11ea08aee686720ac0dd6`

安装完成后回到 GEO 门户刷新并运行本机预检。安装通过不等于已绑定门户所有者会话，也不等于已登录平台或已公开发布。
