# docs/ —— 文档索引

本目录只放 **仓库自己的说明**（结构约定、运维流程、决策记录）。插件自带文档不复制，避免版本漂移，一律指向上游路径。

## 上游文档（在插件仓库内）

| 文档 | 路径 | 内容 |
| --- | --- | --- |
| 中文 README | `plugins/dsh-purge/README.zh-CN.md` | 安装、目录结构、CLI/聊天命令、模型工具、本地靶场、工作原理 |
| English README | `plugins/dsh-purge/README.md` | 同上的英文版 |
| 日本語 README | `plugins/dsh-purge/README.ja.md` | 日文版 |
| 发布记录 | `plugins/dsh-purge/release-notes.md` | 各版本变更（版本号、修了哪个 issue） |
| 许可证 | `plugins/dsh-purge/LICENSE`、`LICENSE-COMMERCIAL.md`、`NOTICE` | Apache-2.0 + 商用条款；二开署名要求见 README |
| 免责与合规 | `plugins/dsh-purge/README.zh-CN.md` 的「严正法律免责与合规使用声明」 | 使用边界 |
| 预览图 | `plugins/dsh-purge/docs/preview/` | 界面截图、设置页、演练台 |
| 旧版注入文件样例 | `plugins/dsh-purge/docs/v1.1.34-prompt-inject.md` | 提示词注入文件的历史形态 |
| dsh-vars README | `plugins/dsh-vars/README.md` | 变量插件：类型、HTTP/WS 接口、token、安装 |
| dsh-vars 许可证 | `plugins/dsh-vars/LICENSE` | MIT |

## 本仓库文档

| 文档 | 内容 |
| --- | --- |
| `../README.md` | 仓库定位、目录结构、插件层/工具层分工、常用命令 |
| `repos.md` | **GitHub 仓库管理台账**：juntaoqian 三个仓库的现状矩阵、缺口、修复片段、统一规范 |
| `../plugins/README.md` | 插件层规范、已收录插件、新增与升级插件的做法 |
| `../tools/README.md` | 工具层规范、命令表、脚本遵守的规则 |
| `../skills/README.md` | 上游 `skills/redteam` 技能索引（23 条） |

## 写文档的规则

- 文档只写"这个仓库怎么用、怎么维护"，不重复上游 README 的安装教程 —— 指过去即可。
- 涉及路径一律写仓库相对路径（如 `plugins/dsh-purge/bin/dsh-purge.js`），方便换机器。
- 流程变更（如换镜像源、改 submodule 策略）在本目录留一条记录，写清日期与原因。
