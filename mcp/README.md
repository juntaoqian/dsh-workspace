# mcp/ —— MCP 服务本地安装

本目录放 **MCP server 的安装与验证资产**，不含第三方源码副本（源码与 venv 在 `.gitignore` 里，用 `tools/idalib-mcp.ps1 bootstrap` 复现）。

| 文件 | 说明 |
| --- | --- |
| `README.md` | 本文件：安装记录、验证结果、已知坑 |
| `probe_idalib_mcp.py` | MCP 协议探针：stdio 起 server，跑 `initialize` → `tools/list` → `resources/list` → `idalib_list` |
| `idalib-mcp/` | 源码 clone + `.venv`（git 忽略） |
| `ida-pro-mcp-src/` | 上游依赖，固定 `858b1e5`（git 忽略） |

## 装的是什么

| 项目 | 内容 |
| --- | --- |
| 主体 | [nyaoouo/idalib-mcp](https://github.com/nyaoouo/idalib-mcp)（包名 `idalib-mcp-headless`，0.1.0） |
| 依赖 | [mrexodia/ida-pro-mcp](https://github.com/mrexodia/ida-pro-mcp) 2.0.0，**固定提交 `858b1e5`** |
| 运行时 | Python 3.12.15（uv 自带 CPython），项目内 `.venv` |
| 入口 | `idalib-mcp-headless`（HTTP/stdio supervisor）、`idalib-mcp-worker`（idalib worker） |

## 实际安装步骤

```powershell
# 1. 项目（镜像 clone；官方 codeload zip 在本机 403）
git clone https://ghfast.top/https://github.com/nyaoouo/idalib-mcp.git mcp/idalib-mcp

# 2. 依赖源码（GitHub main 才有 idalib_supervisor / installer_data）
git clone https://ghfast.top/https://github.com/mrexodia/ida-pro-mcp.git mcp/ida-pro-mcp-src
git -C mcp/ida-pro-mcp-src checkout -B pin-858b1e5 858b1e5

# 3. venv + 安装（--no-deps 绕过 pyproject 里的 GitHub zip 依赖）
C:\...\cpython-3.12.15\python.exe -m venv mcp/idalib-mcp/.venv
mcp/idalib-mcp/.venv/Scripts/python.exe -m pip install --no-deps --force-reinstall mcp/ida-pro-mcp-src
mcp/idalib-mcp/.venv/Scripts/python.exe -m pip install -e mcp/idalib-mcp --no-deps
mcp/idalib-mcp/.venv/Scripts/python.exe -m pip install tomli-w idapro
```

一键复现：`.\tools\idalib-mcp.ps1 bootstrap`

## 验证结果

| 层 | 项 | 结果 |
| --- | --- | --- |
| 安装 | venv / 模块导入 | ✅ Python 3.12.15；`idalib_mcp`、`ida_pro_mcp`、`ida_pro_mcp.idalib_supervisor`、`tomli_w` 全部可导入 |
| 安装 | CLI | ✅ `--help` / `--config` / `--list-clients` 正常（检测到 Claude Code 已安装） |
| 协议 | stdio `initialize` | ✅ `serverInfo={"name":"ida-pro-mcp","version":"1.0.0"}`，capabilities = prompts/resources/tools |
| 协议 | streamable-http `POST /mcp` | ✅ 200，返回 protocolVersion `2025-06-18` |
| 协议 | 实例管理 UI | ✅ `http://127.0.0.1:8745/instances` 返回 200（17 KB 页面） |
| 管理工具 | `idalib_list` 调用 | ✅ `{"sessions":[],"count":0,"context_id":"shared:fallback",...}` |
| 分析 | `tools/list` | ❌ 返回 0 个工具：idalib worker 启动即退出（本机没有 IDA 运行时） |

### 分析层阻塞原因（实测）

```
ImportError: Cannot load IDA library file idalib.dll.
Please make sure you are using IDA version 9.0 or newer and the IDADIR
environment variable is set and points to the active IDA installation.
```

`idapro`（PyPI 0.0.12）只是 Python 绑定，真正的 `idalib.dll` 来自 **IDA Pro 9.0+** 安装目录。本机全盘搜索无 `ida*.exe`、无 `idalib` 目录、无 `%APPDATA%\Hex-Rays` 配置（本次安装时新生成了默认 `ida-config.json`），即**没有安装 IDA Pro**。

装上 IDA Pro 9.x 之后：

```powershell
# 1. 用 IDA 自带的 idalib 覆盖 PyPI 的绑定
mcp\idalib-mcp\.venv\Scripts\python.exe -m pip install "D:\IDA_PRO_9.1\idalib\python"

# 2. 带 IDA 目录启动 / 体检
.\tools\idalib-mcp.ps1 check -IdaHome D:\IDA_PRO_9.1
.\tools\idalib-mcp.ps1 start -IdaHome D:\IDA_PRO_9.1

# 3. 复验（tools/list 应从 0 变成 40+，且 idalib_open 能读入二进制）
.\tools\idalib-mcp.ps1 probe
```

## 常用命令

```powershell
.\tools\idalib-mcp.ps1 check                      # 体检
.\tools\idalib-mcp.ps1 probe                      # MCP 协议探针
.\tools\idalib-mcp.ps1 start                      # HTTP 模式，127.0.0.1:8745
.\tools\idalib-mcp.ps1 config                     # 打印客户端配置片段
.\tools\idalib-mcp.ps1 install -Client claude-code
```

MCP 客户端配置（stdio，由客户端拉起 server）：

```json
{
  "mcpServers": {
    "idalib-mcp-headless": {
      "command": "C:\\Users\\22878\\Documents\\deepseek-harness\\default-workspace\\mcp\\idalib-mcp\\.venv\\Scripts\\python.exe",
      "args": ["-m", "idalib_mcp", "--stdio", "--max-workers", "4", "--sync-wait", "15"]
    }
  }
}
```

## 已知坑（踩过并已绕过）

1. **PyPI 的 `ida-pro-mcp` 1.4.0 不完整**：缺 `idalib_supervisor` / `installer_data`，`--list-clients` 直接报 `Missing dependency 'ida-pro-mcp'`。必须用 GitHub 2.0.0 源码。
2. **上游 main 与 idalib-mcp 不兼容**：`ida-pro-mcp` 在 `22aae5f`（2026-05-26）移除了 `isolated_contexts` 参数，而 idalib-mcp 仍传它，启动即 `TypeError: IdalibSupervisor.__init__() got an unexpected keyword argument 'isolated_contexts'`。固定到 `858b1e5`（移除前的最后一个提交）解决。
3. **`pyproject.toml` 依赖 GitHub archive zip**：本机 `codeload.github.com` 经镜像也 403，改为 clone 源码 + `--no-deps` 安装。
4. **无 IDA 时 `tools/list` 不降级**：worker 起不来会抛 `RuntimeError: idalib worker exited early with code 1`，`tools/list` 返回空而不是只暴露管理工具。属上游体验问题，装 IDA 后不影响。
5. **Python 3.14 不用**：本机默认 3.14.8，ida-pro-mcp 要求 `>=3.11` 但生态未验证；选 3.12（uv 提供）更稳。
