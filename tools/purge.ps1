<#
  tools/purge.ps1 —— 插件 CLI 薄封装
  实际执行：plugins/dsh-purge/bin/dsh-purge.js（本仓库不复制插件代码，只做入口）

  用法：
    .\tools\purge.ps1 status      查看清洗/补丁状态（默认）
    .\tools\purge.ps1 apply       应用全部清洗（提示词 + 代码 + shim + override）
    .\tools\purge.ps1 revert      回滚到原版
    .\tools\purge.ps1 edit        打开注入文件 prompt-inject.md
    .\tools\purge.ps1 uninstall   卸载插件（已应用则先回滚）
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('status', 'apply', 'revert', 'edit', 'uninstall', 'help')]
  [string]$Command = 'status'
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$repoRoot = Split-Path -Parent $PSScriptRoot
$cli      = Join-Path $repoRoot 'plugins\dsh-purge\bin\dsh-purge.js'

if (-not (Test-Path -LiteralPath $cli)) {
  Write-Host "[x] 找不到插件 CLI：$cli" -ForegroundColor Red
  Write-Host "    先执行：.\tools\sync.ps1        # 拉取 / 更新插件" -ForegroundColor Yellow
  exit 2
}

$flag = switch ($Command) {
  'status'    { '--status' }
  'apply'     { '--apply' }
  'revert'    { '--revert' }
  'edit'      { '--edit' }
  'uninstall' { '--uninstall' }
  default     { '--help' }
}

Write-Host "==> node $cli $flag" -ForegroundColor DarkGray
& node $cli $flag
exit $LASTEXITCODE
