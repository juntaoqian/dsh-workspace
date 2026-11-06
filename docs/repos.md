# GitHub 仓库管理台账（juntaoqian）

最后更新：2026-11-07 00:05　账号：https://github.com/juntaoqian
数据来源：GitHub API（`/users/juntaoqian/repos`）+ 本地克隆实测 + 本轮修复后的 API 回读

## 一、现状矩阵（修复后）

| 仓库 | 版本 | tag | CI | 测试 | package 元数据 | topics | README |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `dsh-vars` | 0.2.0 | ✅ v0.2.0 | ✅ ci.yml | ✅ 22 例 | ✅ | ✅ 6 个 | ✅ 含维护信息 |
| `dsh-remote-v2` | 0.1.0 | ✅ v0.1.0 | ✅ ci.yml | ✅ 9 个测试文件 | ✅ | ✅ 6 个 | ✅ 含维护信息 |
| `dsh-traffic-light` | 1.4.0 | ✅ v1.4.0（旧 v1.0.0 保留） | ✅ 新增 ci.yml | ⚠️ 无单测（CI 做语法/清单/locale 校验） | ✅ | ✅ 7 个 | ✅ 含维护信息 |
| `dsh-workspace`（本仓库） | — | — | — | — | — | ✅ 5 个 | ✅ |

`dsh-purge` 不是你的仓库（上游 `YuJunZhiXue/dsh-purge`，Apache-2.0），只作为依赖收录在 `plugins/`。

## 二、本轮已执行（全部已推送到远端）

| 仓库 | 提交 | tag | 内容 |
| --- | --- | --- | --- |
| `dsh-vars` | `0adaef0` | `v0.2.0` | package.json 补 `homepage` / `repository` / `bugs`；README 加「维护信息」节 |
| `dsh-remote-v2` | `9035b6f` | `v0.1.0` | 同上 |
| `dsh-traffic-light` | `ea478d2` | `v1.4.0` | 新增 `.github/workflows/ci.yml`（语法检查 + package 清单 + locale JSON）；package.json 补 `engines`；README 加「维护信息」节 |
| `dsh-workspace` | `1684a82` | — | 首次推送：4 个插件 submodule、`tools/` 全套脚本、本台账 |

远端校验：

```powershell
git ls-remote --heads origin        # 三个仓库的 main 均指向新提交
git ls-remote --tags origin         # v0.2.0 / v0.1.0 / v1.4.0 均在
```

topics 已通过 API 补齐（此前 dsh-vars、dsh-remote-v2 为空）：

| 仓库 | topics |
| --- | --- |
| `dsh-vars` | deepseek-harness, dsh, dsh-plugin, variables, http-api, websocket |
| `dsh-remote-v2` | deepseek-harness, dsh, dsh-plugin, remote-access, cloudflare-tunnel, pairing |
| `dsh-traffic-light` | deepseek, deepseek-harness, dsh, dsh-plugin, status, traffic-light, notification |
| `dsh-workspace` | deepseek-harness, dsh, dsh-plugin, workspace, tooling |

## 三、剩余可选项（非阻塞）

| 项 | 说明 |
| --- | --- |
| `dsh-traffic-light` 补单测 | 目前只有 CI 的静态校验；可把 locale 回退、状态聚合逻辑抽出来做 `node --test` |
| GitHub Release | tag 已有，Release 页还是空的；可用 `gh release create` 或网页补一段变更摘要 |
| README 骨架统一 | 三个仓库现状都不差，若要统一可照 `dsh-traffic-light` 的「安装 → 配置表 → 能力 → 常见问题」结构 |
| 分支保护 | 三个仓库都是单人维护，可给 `main` 开 require PR + CI 通过；不开也不影响使用 |

## 四、统一规范检查表

| 检查项 | 标准 | dsh-vars | dsh-remote-v2 | dsh-traffic-light |
| --- | --- | --- | --- | --- |
| `LICENSE` | MIT | ✅ | ✅ | ✅ |
| `icon.svg` | 插件图标 | ✅ | ✅ | ✅ |
| `cordis.patch.yml` | 有 insert 行 | ✅ | ✅ | ✅ |
| `files` 白名单 | 打包只带必要文件 | ✅ | ✅ | ✅ |
| `engines` | node + dsh 版本 | ✅ | ✅ | ✅ |
| `test` 脚本 | `node --test` | ✅ | ✅ | ⚠️ |
| CI | push / PR 都跑 | ✅ | ✅ | ✅ |
| tag | 与版本号一致 | ✅ | ✅ | ✅ |
| package 元数据 | repo / homepage / bugs | ✅ | ✅ | ✅ |
| topics | ≥5 个 | ✅ | ✅ | ✅ |
| README | 含安装与维护信息 | ✅ | ✅ | ✅ |

## 五、日常维护流程

```powershell
# 1. 在对应插件目录改代码
cd plugins\dsh-vars

# 2. 提交 + 打 tag（版本号与 package.json 对齐）
git add -A; git commit -m "feat: ..."
git tag -a v0.3.0 -m "dsh-vars 0.3.0"

# 3. 推送（HTTPS 走凭据管理器，可用；SSH 未配置公钥）
git push origin main --tags

# 4. 回到父仓库，更新指针并推送
cd ..\..
git add plugins; git commit -m "chore: bump dsh-vars to v0.3.0"; git push

# 5. 体检
.\tools\sync.ps1
.\tools\doctor.ps1
```

## 六、注意

- 推送通道：HTTPS（`https://github.com/juntaoqian/*.git`，凭据来自 Git Credential Manager，本机已验证可用）。SSH 仍返回 `Permission denied (publickey)`，公钥 `~/.ssh/id_ed25519.pub` 尚未加入账号；加不加都不影响现有流程。
- `mirror` 远程（ghfast.top）只用于读（fetch/clone），推送一律走 `origin`。
- 本仓库 `.gitmodules` 记录的是官方 URL；换机 clone 慢时临时用 `-c url.<mirror>.insteadOf=...`，不要改 `.gitmodules` 本身。
