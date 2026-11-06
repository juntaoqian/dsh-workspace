# dsh-workspace

本地工作仓库：**插件归插件，工具归工具**。

- `plugins/` —— DSH 插件（上游仓库，submodule 登记，不二次修改）
- `tools/` —— 可执行入口（把插件自带的 CLI/脚本包一层，统一参数）
- `docs/` —— 本仓库文档 + GitHub 仓库管理台账
- `skills/` —— 上游技能索引（技能实体在插件内，避免版本漂移）

## 目录结构

```
default-workspace/
├─ README.md                 # 本文件：定位、结构、命令
├─ .gitignore
├─ .gitmodules               # submodule 登记（4 个插件）
├─ plugins/
│  ├─ README.md              # 插件层规范 + 已收录清单
│  ├─ dsh-purge/             # submodule → YuJunZhiXue/dsh-purge @ v1.1.92
│  ├─ dsh-vars/              # submodule → juntaoqian/dsh-vars @ 0.2.0
│  ├─ dsh-remote-v2/         # submodule → juntaoqian/dsh-remote-v2 @ 0.1.0
│  └─ dsh-traffic-light/     # submodule → juntaoqian/dsh-traffic-light @ 1.4.0
├─ tools/
│  ├─ README.md              # 工具层规范 + 命令表
│  ├─ purge.ps1              # dsh-purge：status / apply / revert / edit / uninstall
│  ├─ build.ps1              # dsh-purge：构建 client / prompt / profile / dock
│  ├─ report.ps1             # dsh-purge：演练成果报告导出
│  ├─ vars.ps1               # dsh-vars：test / install / uninstall / validate
│  ├─ sync.ps1               # 全部插件上游同步（自动扫描 plugins/*）
│  └─ doctor.ps1             # 全部插件 + 宿主 + 清洗状态体检
├─ docs/
│  ├─ README.md              # 文档索引
│  └─ repos.md               # GitHub 仓库管理台账（现状矩阵 / 缺口 / 修复片段）
└─ skills/
   └─ README.md              # 23 条 redteam 技能索引
```

## 分层规则

| 层 | 放什么 | 不放什么 |
| --- | --- | --- |
| `plugins/` | 能被宿主加载的完整插件包；每个插件一个子目录，保留自己的 `.git` | 自己写的脚本、临时文件、导出的报告 |
| `tools/` | 薄封装：参数整理、路径推导、退出码透传；只调用不改源码 | 业务逻辑的复制品、插件源码副本 |
| `docs/` | 仓库自身说明、运维记录、仓库管理台账 | 上游 README 的拷贝 |
| `skills/` | 技能索引与生效机制说明 | 技能 `.md` 实体（在 `plugins/dsh-purge/skills/`） |

判断标准：**换掉插件版本后还需要改的东西放 `tools/`；跟着插件版本一起变的东西放 `plugins/`。**

## 已收录插件

| 插件 | 归属 | 版本 / 分支 | 本地路径 | 状态 |
| --- | --- | --- | --- | --- |
| `dsh-purge` | 上游 YuJunZhiXue | v1.1.92 / `master` | `plugins/dsh-purge` | 插件已装进宿主、清洗已 apply |
| `dsh-vars` | juntaoqian | 0.2.0 / `main` | `plugins/dsh-vars` | 22 例单测全绿，已有 CI |
| `dsh-remote-v2` | juntaoqian | 0.1.0 / `main` | `plugins/dsh-remote-v2` | 9 个测试文件，已有 CI |
| `dsh-traffic-light` | juntaoqian | 1.4.0 / `main` | `plugins/dsh-traffic-light` | 无 CI / 无测试，tag 停在 v1.0.0 |

三个自有仓库的体检结果与修复清单在 [docs/repos.md](docs/repos.md)。

## 本仓库的远程

```powershell
origin  git@github.com:juntaoqian/dsh-workspace.git   # 走 SSH（github.com 的 HTTPS 在本机被重置）
```

仓库名 `dsh-workspace` 是占位；实际用别的名字时：

```powershell
git remote set-url origin git@github.com:juntaoqian/<实际仓库名>.git
```

## 常用命令

```powershell
# dsh-purge：状态 / 清洗 / 回滚
.\tools\purge.ps1
.\tools\purge.ps1 apply
.\tools\purge.ps1 revert

# dsh-purge：重建前端产物与提示词资源
.\tools\build.ps1 all

# dsh-purge：演练报告
.\tools\report.ps1 -Out D:\交付\靶标名

# dsh-vars：测试 / 安装 / 校验
.\tools\vars.ps1 test
.\tools\vars.ps1 install
.\tools\vars.ps1 validate

# 全部插件：同步 / 单体检查 / 体检
.\tools\sync.ps1
.\tools\sync.ps1 -Apply
.\tools\sync.ps1 -Plugin dsh-vars
.\tools\doctor.ps1
```

## 换机恢复 / 首次拉取

GitHub 直连被重置时用镜像（`insteadOf` 只对本次命令生效）：

```powershell
git -c url."https://ghfast.top/https://github.com/".insteadOf="https://github.com/" clone --recurse-submodules <本仓库远程> dsh-workspace
```

已 clone、只是 submodule 没拉下来：

```powershell
git submodule set-url plugins/dsh-purge          https://ghfast.top/https://github.com/YuJunZhiXue/dsh-purge.git
git submodule set-url plugins/dsh-vars           https://ghfast.top/https://github.com/juntaoqian/dsh-vars.git
git submodule set-url plugins/dsh-remote-v2      https://ghfast.top/https://github.com/juntaoqian/dsh-remote-v2.git
git submodule set-url plugins/dsh-traffic-light  https://ghfast.top/https://github.com/juntaoqian/dsh-traffic-light.git
git submodule update --init --recursive
git submodule sync --recursive   # 拉完改回官方 URL
```

## 维护约定

1. 插件目录只读使用；要改插件行为 → 改上游 / 提 PR，本地改动会让 `sync.ps1 -Apply` 快进失败（刻意的保护）。
2. 自有仓库（`juntaoqian/*`）的规范化改动在各自仓库里做：一个仓库一个 commit、与版本号对齐的 tag。
3. 工具脚本从 `$PSScriptRoot` 推导仓库根，不写死绝对路径。
4. `tools/` 新增脚本要登记到 `tools/README.md` 的命令表。
5. 每次改完插件跑 `.\tools\doctor.ps1`，父仓库 `git add plugins/` 记录新指针。
