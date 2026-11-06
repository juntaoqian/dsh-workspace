# skills/ —— 技能索引

本目录**不放技能实体**。技能文件在上游插件里：

```
plugins/dsh-purge/skills/redteam/*.md
```

复制一份就会和插件版本脱钩（插件升级技能内容会变），所以这里只做索引与导航。

## 技能是怎么生效的

- 插件启动时把 `skills/redteam/` 注册进宿主技能目录（实现见 `plugins/dsh-purge/lib/skills.js`）；
- 每个 `.md` 是 YAML front matter + Markdown 正文：`name` / `description` / `whenToUse` / `role` / `enabled`；
- 技能由 agent 按 `whenToUse` 自动挑选，也可以在对话里点名加载。

## 索引（共 23 条，按 role 分组）

### recon — 信息收集（9）

| 技能 | 用途 |
| --- | --- |
| `passive-recon` | 被动信息收集：不接触目标主机，仅用公开数据源 |
| `active-scan` | 主动端口与服务扫描（nmap/masscan），严格遵守授权范围 |
| `asset-correlation` | 资产关联：域名 ↔ IP ↔ C 段 ↔ 证书 ↔ 服务的图谱化 |
| `recon-pipeline` | ProjectDiscovery 流水线：subfinder→dnsx→naabu→httpx→katana |
| `fofa-recon` | FOFA API 批量测绘（域名/IP/端口/标题/指纹），内置限速与退避 |
| `web-fingerprint` | Web 指纹：框架、中间件、CMS、组件版本 |
| `browser-automation` | 无依赖驱动 Chrome 抓 JS 渲染页、截图、执行 JS、抓接口 |
| `kimi-webbridge` | 用 Kimi 浏览器扩展驱动真实 Chrome：导航/点击/填表/截图 |
| `redteam-setup` | 首次引导：FOFA_KEY 与 VPS 登录、通道验证、降级口径 |

### vuln-scan — 漏洞扫描（3）

| 技能 | 用途 |
| --- | --- |
| `nuclei-scan` | 13000+ 模板的 CVE/暴露面/配置缺陷/默认口令检测 |
| `dir-bruteforce` | 目录与文件爆破：后台、备份、配置泄露、源码与 .git 暴露 |
| `cn-proxy-pool` | 国内免费 HTTP/SOCKS5 代理池：抓取、验活、按需轮换 |

### exploit — 利用（4）

| 技能 | 用途 |
| --- | --- |
| `credential-attack` | 在线弱口令爆破（hydra）+ 离线哈希破解（hashcat/john） |
| `unauth-exploit` | 未授权访问利用链：Redis/MySQL/MSSQL/ES/Docker/MongoDB |
| `shell-handler` | 反弹 Shell 与载荷投递：VPS 起 MSF/nc/socat 监听 |
| `vps-reverse-shell` | 自建 VPS 做反弹 Shell 落地与中转、非交互会话驱动 |
| `webshell-toolkit` | 冰蝎 / 哥斯拉 / 蚁剑的启动与 WebShell 管理 |

### internal — 内网（6）

| 技能 | 用途 |
| --- | --- |
| `fscan-intranet` | fscan v2.2.1：存活、端口、28 类弱口令、MS17-010、Redis 利用 |
| `gogo-intranet` | gogo v2.15.0：智能模式、指纹、关键信息提取、nuclei POC |
| `lateral-movement` | Impacket（PtH/PsExec/WMI/DCOM/Kerberos）+ enum4linux |
| `suo5-tunnel` | 用 suo5 通过 WebShell/HTTP 建 SOCKS5 隧道 |
| `chisel-tunnel` | chisel：HTTP/WebSocket 多路复用隧道，穿透出网限制 |
| `frp-tunnel` | frp 内网穿透：VPS 跑 frps、目标跑 frpc，稳定 socks5 |

## 查看 / 修改

```powershell
# 列全部技能文件
Get-ChildItem plugins\dsh-purge\skills\redteam -Filter *.md

# 看某条技能
Get-Content plugins\dsh-purge\skills\redteam\nuclei-scan.md -Encoding UTF8
```

改技能内容 = 改插件仓库（`plugins/dsh-purge/skills/redteam/`）。改完要么提 PR 给上游，要么接受 `sync.ps1` 快进时冲突 —— 长期本地定制建议单独维护，不要直接改 submodule 工作区。
