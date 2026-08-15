# 华昇金玛 GEO 连接器安装包镜像

本仓库只提供已完成安全扫描和构建验证的二进制安装包；源码仓库保持私有，不在此公开源码、账号密码、验证码、Cookie、Token、私钥或浏览器登录态。

## 安装

1. macOS 优先下载 `HSJM-GEO-Connector-Install.command`：它会校验 ZIP；如果没有 Chrome for Testing，会自动下载官方对应架构的隔离浏览器，然后自动载入连接器，不改动日常 Chrome。
2. Windows 优先下载 `HSJM-GEO-Connector-Install.ps1`：它会校验 ZIP；如果没有 Chrome for Testing，会自动下载官方隔离浏览器，然后自动载入连接器。
3. 如果设备没有可接受命令行扩展载入的 Chrome for Testing，再下载 ZIP，打开 `chrome://extensions`，开启开发者模式并手动加载包含 `manifest.json` 的最外层目录。

## 运行边界

- Manifest V3，草稿优先，外部发布必须人工确认。
- 不读取或保存密码、验证码、Cookie、Token、私钥。
- 不绕过验证码、实名、WAF 或平台风控。
- 真实发布以平台后台公开回执为准。
- 专用浏览器首次打开后仍需所有者本人登录门户；平台验证码、实名和风控按平台要求人工完成。
