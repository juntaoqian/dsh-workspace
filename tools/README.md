# tools/ —— 工具层

本目录只放 **可执行入口**：包装插件自带的 CLI 与脚本，统一参数、统一入口，方便直接跑。
工具不复制插件源码，一律 `委托` 到 `plugins/dsh-purge/` 内的上游实现 —— 插件升级后工具自动跟着升级。

> 约定：`tools/` 里只写"怎么调"，不写"怎么做"。业务实现放插件里；如果这里需要新逻辑，说明它应该进插件或单独成包。

## 命令一览

| 脚本 | 作用 | 底层实现 |
| --- | --- | --- |
| `purge.ps1` | 清洗状态 / 应用 / 回滚 / 编辑注入 / 卸载 | `plugins/dsh-purge/bin/dsh-purge.js` |
| `vars.ps1` | dsh-vars：单测 / 装进 profile / 卸载 / 校验 profile 组合 | `plugins/dsh-vars/scripts/*.mjs` + `node --test` |
| `build.ps1` | 重建 `client.js`、嵌入默认提示词、补 profile 登记、打 dock 补丁 | `plugins/dsh-purge/scripts/*.mjs` |
| `report.ps1` | 导出演练成果复现报告包（md + 截图，相对路径） | `scripts/export-engagement-report.mjs` |
| `sync.ps1` | 与上游同步插件（默认走 mirror，`-Apply` 快进） | `git fetch/merge --ff-only` |
| `doctor.ps1` | 只读体检：工具链、插件版本、宿主安装、清洗状态 | 本地文件 + git |

## 用法

```powershell
# 清洗
.\tools\purge.ps1                 # = status
.\tools\purge.ps1 apply
.\tools\purge.ps1 revert

# 构建
.\tools\build.ps1 all             # prompt -> client -> profile
.\tools\build.ps1 client

# 演练报告
.\tools\report.ps1 -Out D:\交付\靶标名

# dsh-vars
.\tools\vars.ps1 test              # 22 例单测
.\tools\vars.ps1 install           # 装进 desktop profile
.\tools\vars.ps1 validate          # 用 Electron 运行时校验 profile
.\tools\report.ps1 -Engagement <id>

# 同步与体检
.\tools\sync.ps1
.\tools\sync.ps1 -Apply
.\tools\doctor.ps1
```

## 脚本遵守的规则

1. **不猜路径**：一律从 `$PSScriptRoot` 推导仓库根，再用 `plugins/dsh-purge/...` 定位上游文件。
2. **不改上游**：工具只调用，不 patch 插件源码；需要改行为，改插件仓库并走 submodule 更新。
3. **失败即停**：`$ErrorActionPreference = 'Stop'`，透传上游 `exit code`，不当"成功"处理。
4. **可回滚**：`sync.ps1` 只用 `--ff-only`，插件目录有本地改动时直接报错而不是覆盖。

## 新增工具

- 需要包装插件里的某个 `bin/` 或 `scripts/` 入口 → 照现有脚本写薄封装，登记到上表。
- 需要全新逻辑 → 先判断是否该进插件（插件能力）还是独立小工具（放 `tools/<name>.ps1` + 独立脚本目录）。
- 纯一次性命令 → 不落盘，写在 `docs/` 的运维笔记里。
