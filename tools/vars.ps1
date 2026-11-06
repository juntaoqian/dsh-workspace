<#
  tools/vars.ps1 —— dsh-vars 插件工具封装
  委托 plugins/dsh-vars/scripts/ 下的上游脚本，cwd 固定在插件根。

  用法：
    .\tools\vars.ps1 test                    跑单测（node --test，22 例）
    .\tools\vars.ps1 install                 装进 profile（默认 desktop）
    .\tools\vars.ps1 install -Profile web
    .\tools\vars.ps1 uninstall               从 profile 卸载
    .\tools\vars.ps1 validate                校验 profile 组合（用 Electron 运行时跑）
    .\tools\vars.ps1 validate -AppAsar <path>

  可选参数：
    -Profile <name>   profile 名，默认 desktop
    -DshHome <dir>    DSH_HOME，默认取 $env:DSH_HOME 或 ~/.dsh
    -AppAsar <path>   显式指定 app.asar/dsh 目录（validate 用）
    -DshExe <path>    Electron 可执行文件，默认自动探测本地安装
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('test', 'install', 'uninstall', 'validate', 'help')]
  [string]$Command = 'help',

  [string]$Profile = 'desktop',
  [string]$DshHome,
  [string]$AppAsar,
  [string]$DshExe,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$repoRoot = Split-Path -Parent $PSScriptRoot
$plugin   = Join-Path $repoRoot 'plugins\dsh-vars'

if (-not (Test-Path -LiteralPath $plugin)) {
  Write-Host "[x] 插件目录不存在：$plugin" -ForegroundColor Red
  Write-Host "    先执行：.\tools\sync.ps1 -Apply   （或手动 clone 到 plugins/dsh-vars）" -ForegroundColor Yellow
  exit 2
}

$common = @('--profile', $Profile)
if ($DshHome) { $common += @('--dsh-home', $DshHome) }
if ($AppAsar) { $common += @('--app-asar', $AppAsar) }

function Get-DshExe {
  if ($DshExe) { return $DshExe }
  if ($env:DSH_EXE) { return $env:DSH_EXE }
  $candidate = Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness\DeepSeek Harness.exe'
  if (Test-Path -LiteralPath $candidate) { return $candidate }
  return $null
}

Push-Location $plugin
try {
  switch ($Command) {
    'test' {
      Write-Host "==> node --test（$plugin）" -ForegroundColor DarkGray
      & node --test @Rest
      exit $LASTEXITCODE
    }
    'install' {
      Write-Host "==> node scripts\install.mjs $($common -join ' ')" -ForegroundColor DarkGray
      & node 'scripts\install.mjs' @common @Rest
      exit $LASTEXITCODE
    }
    'uninstall' {
      Write-Host "==> node scripts\install.mjs $($common -join ' ') --uninstall" -ForegroundColor DarkGray
      & node 'scripts\install.mjs' @common '--uninstall' @Rest
      exit $LASTEXITCODE
    }
    'validate' {
      $exe = Get-DshExe
      if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
        Write-Host "[x] 找不到 DeepSeek Harness.exe；用 -DshExe <path> 指定" -ForegroundColor Red
        exit 2
      }
      Write-Host "==> ELECTRON_RUN_AS_NODE=1 `"$exe`" scripts\validate-profile.mjs $($common -join ' ')" -ForegroundColor DarkGray
      $prev = $env:ELECTRON_RUN_AS_NODE
      $env:ELECTRON_RUN_AS_NODE = '1'
      try {
        & $exe 'scripts\validate-profile.mjs' @common @Rest
        exit $LASTEXITCODE
      } finally {
        $env:ELECTRON_RUN_AS_NODE = $prev
      }
    }
    default {
      Get-Help $PSCommandPath -Detailed | Out-String | Write-Host
      exit 0
    }
  }
} finally {
  Pop-Location
}
