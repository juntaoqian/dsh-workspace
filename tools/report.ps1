<#
  tools/report.ps1 —— 导出演练（redteam）成果复现报告包
  委托 plugins/dsh-purge/scripts/export-engagement-report.mjs

  用法：
    .\tools\report.ps1                          导出当前活跃靶标
    .\tools\report.ps1 -Engagement <id>         导出指定靶标
    .\tools\report.ps1 -Out D:\交付\靶标名      指定输出目录
  数据源：$DSH_HOME\redteam（默认 %USERPROFILE%\.dsh\redteam）
#>
[CmdletBinding()]
param(
  [string]$Engagement,
  [string]$Out,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$repoRoot = Split-Path -Parent $PSScriptRoot
$plugin   = Join-Path $repoRoot 'plugins\dsh-purge'
$script   = Join-Path $plugin 'scripts\export-engagement-report.mjs'

if (-not (Test-Path -LiteralPath $script)) {
  Write-Host "[x] 找不到导出脚本：$script" -ForegroundColor Red
  exit 2
}

$nodeArgs = @()
if ($Engagement) { $nodeArgs += @('--engagement', $Engagement) }
if ($Out)        { $nodeArgs += @('--out', $Out) }
if ($Rest)       { $nodeArgs += $Rest }

Push-Location $plugin
try {
  Write-Host "==> node scripts\export-engagement-report.mjs $($nodeArgs -join ' ')" -ForegroundColor DarkGray
  & node 'scripts\export-engagement-report.mjs' @nodeArgs
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
