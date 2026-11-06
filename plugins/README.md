# plugins/ —— 插件层

本目录只放 **DSH 插件**（能被宿主加载、带 `cordis.patch.yml` / `lib/index.js` 的包）。
每个插件一个子目录，保留上游 `.git`，作为该插件的独立仓库登记为 submodule，不做二次修改。

> 约定：插件层不放自己写的脚本、笔记、导出物。工具放 `../tools/`，文档索引放 `../docs/`，技能索引放 `../skills/`。

## 已收录

| 插件 | 说明 | 来源 | 本地路径 |
| --- | --- | --- | --- |
| `dsh-purge` | DSH 破壁/清洗插件：提示词注入、宿主补丁、shim、演练台（redteam）、技能包 | [YuJunZhiXue/dsh-purge](https://github.com/YuJunZhiXue/dsh-purge)（`master`） | `plugins/dsh-purge` |
| `dsh-vars` | DSH 变量插件：新建带类型的变量，本机 HTTP GET/POST 读写，可选 Bearer token、WebSocket 变化订阅、设置页「变量」分区 | [juntaoqian/dsh-vars](https://github.com/juntaoqian/dsh-vars)（`main`） | `plugins/dsh-vars` |
| `dsh-remote-v2` | 远程访问：隔离 sidecar + 认证网关 + 一次性配对，Quick/Named Cloudflare Tunnel | [juntaoqian/dsh-remote-v2](https://github.com/juntaoqian/dsh-remote-v2)（`main`） | `plugins/dsh-remote-v2` |
| `dsh-traffic-light` | Web UI 左下角红绿灯：汇总会话运行/等待状态、6 种蜂鸣音效、设置页可配 | [juntaoqian/dsh-traffic-light](https://github.com/juntaoqian/dsh-traffic-light)（`main`） | `plugins/dsh-traffic-light` |

## dsh-purge 关键信息

- 版本：见 `dsh-purge/package.json` 的 `version`；历史版本见 `dsh-purge/release-notes.md`
- 插件入口：`lib/index.js`（主插件）、`lib/redteam/index.js`（演练台）、`client.js`（Web 前端产物）
- 宿主补丁清单：`cordis.patch.yml`
- CLI：`bin/dsh-purge.js`（`--status` / `--apply` / `--revert` / `--edit` / `--uninstall`）
- 远程：
  - `origin` → `https://github.com/YuJunZhiXue/dsh-purge.git`
  - `mirror` → `https://ghfast.top/https://github.com/YuJunZhiXue/dsh-purge.git`（直连被重置时用这个 fetch）

## dsh-vars 关键信息

- 版本：见 `dsh-vars/package.json` 的 `version`（当前 0.2.0）
- 插件入口：`lib/index.js`；前端 `lib/client.js`
- 模块：`lib/api.js`（本机 HTTP API，挂在 `/dsh-vars/api`）、`lib/store.js`（变量存取）、`lib/ws.js`（变化订阅）
- 宿主行：`cordis.patch.yml` 只 insert 一行 `dsh-vars`，默认配置即可用
- 数据文件：`~/.dsh/plugins/dsh-vars/variables.json`（本机生成，不进仓库）
- 工具脚本：`scripts/install.mjs`（开发态装/卸 profile）、`scripts/validate-profile.mjs`（校验 profile 组合，需 Electron 运行时）
- 测试：`test/*.test.js`，`node --test` 22 例，本仓库已实测全绿
- 远程：
  - `origin` → `https://github.com/juntaoqian/dsh-vars.git`
  - `mirror` → `https://ghfast.top/https://github.com/juntaoqian/dsh-vars.git`

## dsh-remote-v2 / dsh-traffic-light 关键信息

`dsh-remote-v2`（0.1.0）
- 入口 `lib/index.js`；`core/`（sidecar 运行时）、`scripts/smoke.mjs` 冒烟
- 测试 9 个文件（config/control/devices/gateway/host/pairing/sidecar-runtime/tailscale/tunnel），`node --test`
- CI：`.github/workflows/ci.yml`；`NOTICE` 文件在，注意第三方声明

`dsh-traffic-light`（1.4.0）
- 入口 `index.js`；前端 `client.js`；本地代理 `proxy.js`；多语言 `locale/*.json`
- **无 CI、无测试**；tag 停在 `v1.0.0`，版本已到 1.4.0（见 `docs/repos.md` 待办）
- 有 `v1.0.0` tag 可作为其余两个仓库打 tag 的参考格式

## 新增插件

```powershell
# 1) 克隆到 plugins/<name>
git clone <upstream-url> plugins/<name>
# 2) 登记为 submodule（父仓库只记录 commit 指针）
git submodule add -f <upstream-url> plugins/<name>
# 3) 在本表补一行
```

升级已有插件（本仓库已封装）：

```powershell
.\tools\sync.ps1            # 体检：只 fetch + 列出落后提交
.\tools\sync.ps1 -Apply     # 快进合并，然后 git add plugins/dsh-purge
```
