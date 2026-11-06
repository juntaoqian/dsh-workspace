# GitHub 仓库管理台账（juntaoqian）

盘点时间：2026-11-06　来源：GitHub API（`/users/juntaoqian/repos`）+ 本地克隆实测
账号：https://github.com/juntaoqian（GitHub ID 102168830，公开仓库 3 个）

## 一、现状矩阵

| 仓库 | 版本 | 默认分支 | 最近推送 | 体积 | CI | 测试 | tag / release | package 元数据 | topics | README |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `dsh-remote-v2` | 0.1.0 | main | 2026-10-24 | 293 KB | ✅ `ci.yml` | ✅ 9 个测试文件 | ❌ 无 tag | ⚠️ 缺 repository/homepage/bugs | ❌ 空 | 8.0 KB |
| `dsh-vars` | 0.2.0 | main | 2026-10-26 | 42 KB | ✅ `ci.yml` | ✅ 22 例 | ❌ 无 tag | ⚠️ 缺 repository/homepage/bugs | ❌ 空 | 7.5 KB |
| `dsh-traffic-light` | 1.4.0 | main | 2026-11-06 | 62 KB | ❌ 无 | ❌ 无 | ⚠️ 仅 v1.0.0（落后 4 个小版本） | ✅ 完整 | ✅ 7 个 | 21 KB |

补充：`dsh-purge` 不是你的仓库（上游 `YuJunZhiXue/dsh-purge`，Apache-2.0），只作为依赖收录在 `plugins/`。

## 二、已完成的归集（本地）

| 动作 | 状态 |
| --- | --- |
| 三个仓库全部克隆到 `plugins/` | ✅ `dsh-vars`、`dsh-remote-v2`、`dsh-traffic-light` |
| 每个仓库配 `origin`（官方）+ `mirror`（ghfast 镜像，直连被重置时用） | ✅ |
| submodule 登记（父仓库只记指针，可随上游升级） | ✅ 4 个 |
| `tools/sync.ps1` 改为自动扫描 `plugins/*` | ✅ `-Plugin all` 默认 |
| `tools/doctor.ps1` 逐插件体检（版本/HEAD/脏否/落后/宿主安装/profile 登记） | ✅ |

## 三、缺口与修复清单

### P0：三个仓库都缺 release tag

当前只有 `dsh-traffic-light` 有 `v1.0.0`，但代码已到 `1.4.0`。tag 缺失的后果：装插件的人拿不到可追溯版本，rollback 只能靠 commit。

```powershell
# 在每个插件目录内，版本号与 package.json 对齐打 tag
git -C plugins/dsh-vars           tag -a v0.2.0 -m "dsh-vars 0.2.0"
git -C plugins/dsh-remote-v2      tag -a v0.1.0 -m "dsh-remote-v2 0.1.0"
git -C plugins/dsh-traffic-light  tag -a v1.4.0 -m "dsh-traffic-light 1.4.0"
# 推送（需要 SSH 认证就绪）
git -C plugins/dsh-vars push origin main --tags
```

配套：在 GitHub Releases 页把 tag 写成 release，附 `package.json` 的 `files` 清单。

### P1：`dsh-vars`、`dsh-remote-v2` 的 package.json 缺仓库元数据

npm 页面和 IDE 里没有源码入口、issues 入口。两个仓库的 `package.json` 都缺，补法一样（插在 `"license"` 行后）：

```json
  "homepage": "https://github.com/juntaoqian/<REPO>#readme",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/juntaoqian/<REPO>.git"
  },
  "bugs": {
    "url": "https://github.com/juntaoqian/<REPO>/issues"
  },
```

`dsh-traffic-light` 已有这三项，可作为模板。

### P1：`dsh-traffic-light` 没有 CI

它是三个仓库里唯一没有 `.github/workflows/` 的，但它也是唯一有 `locale/` 多语言文件的。建议加一个轻量 CI（不需要测试框架也能跑）：

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: 语法检查
        run: |
          for f in index.js proxy.js client.js; do node --check "$f"; done
      - name: package 校验
        run: node -e "const p=require('./package.json'); if(!p.exports) throw new Error('missing exports'); console.log('ok', p.name, p.version)"
      - name: locale JSON 合法性
        run: for f in locale/*.json; do node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" || exit 1; done
```

### P2：topics 不统一

| 仓库 | 现状 | 建议 |
| --- | --- | --- |
| `dsh-vars` | 空 | `deepseek-harness, dsh, dsh-plugin, variables, http-api, websocket` |
| `dsh-remote-v2` | 空 | `deepseek-harness, dsh, dsh-plugin, remote-access, cloudflare-tunnel, pairing` |
| `dsh-traffic-light` | 7 个，规范 | 保持 |

补 topics 只能在网页或 API 操作（需要 token），本地脚本改不了。

### P2：README 结构差异

- `dsh-traffic-light` 21 KB 最完整（含安装、配置、音效说明、看板）
- `dsh-remote-v2` 8 KB，有 `docs/` 目录可拆长文
- `dsh-vars` 7.5 KB，缺「常见问题」和「API 示例」两节

建议统一骨架：一句话定位 → 安装 → 快速开始 → 配置项表 → API/能力 → 常见问题 → License。`dsh-traffic-light` 的结构可以直接抄。

## 四、统一规范（三个仓库共用的检查表）

| 检查项 | 标准 | dsh-vars | dsh-remote-v2 | dsh-traffic-light |
| --- | --- | --- | --- | --- |
| `LICENSE` | MIT | ✅ | ✅ | ✅ |
| `icon.svg` | 插件图标 | ✅ | ✅ | ✅ |
| `cordis.patch.yml` | 有 insert 行 | ✅ | ✅ | ✅ |
| `files` 白名单 | 打包只带必要文件 | ✅ | ✅ | ✅ |
| `engines` | node + dsh 版本 | ✅ | ✅ | ❌ 缺 |
| `test` 脚本 | `node --test` | ✅ | ✅ | ❌ 无 |
| CI | push/PR 都跑 | ✅ | ✅ | ❌ 无 |
| tag | 与版本号一致 | ❌ | ❌ | ⚠️ v1.0.0 |
| package 元数据 | repo/homepage/bugs | ❌ | ❌ | ✅ |
| topics | ≥5 个 | ❌ | ❌ | ✅ |
| README | 骨架统一 | ⚠️ | ⚠️ | ✅ |

指标最好的当模板：`dsh-traffic-light`（元数据/topics/README）+ `dsh-vars`（测试/CI）。

## 五、执行顺序

1. **先让推送通道可用**：把 `~/.ssh/id_ed25519.pub` 加进 GitHub 账号（SSH 已配 443，`ssh -T git@github.com` 应返回 `Hi juntaoqian!`）
2. 在 GitHub 上建 `dsh-workspace` 仓库（或改名），本地父仓库 `origin` 已指向它
3. 按 P0 → P1 → P2 改三个插件仓库，每个仓库一个 commit，一个 tag
4. 每次改完 `.\tools\sync.ps1` 体检，父仓库 `git add plugins/` 记录新指针

改仓库内容属于对你的仓库动手，没凭据我不推。上面的命令和片段可以直接用，也能我这边批量执行（认证就绪后）。
