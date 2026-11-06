<#
  tools/build.ps1 —— 插件构建 / 资源生成
  全部委托给 plugins/dsh-purge/scripts/ 下的上游脚本，cwd 固定在插件根。

  用法：
    .\tools\build.ps1 client     重建 client.js（把 lib/redteam/client.js 打进 DRILL 片段）
    .\tools\build.ps1 prompt     把 lib/default-prompt-inject.md 嵌入 lib/asset-table.js
    .\tools\build.ps1 profile    补 profile bundles / cordis.patch.yml insert（postinstall 同款）
    .\tools\build.ps1 dock       打 dock UI 补丁
    .\tools\build.ps1 all        依次 prompt -> client -> profile
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('client', 'prompt', 'profile', 'dock', 'all')]
  [string]$Target = 'client',

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$repoRoot = Split-Path -Parent $PSScriptRoot
$plugin   = Join-Path $repoRoot 'plugins\dsh-purge'

if (-not (Test-Path -LiteralPath $plugin)) {
  Write-Host "[x] 插件目录不存在：$plugin" -ForegroundColor Red
  exit 2
}

$map = @{
  client  = 'scripts\build-client.mjs'
  prompt  = 'scripts\embed-default-prompt.mjs'
  profile = 'scripts\ensure-profile-bundle.mjs'
  dock    = 'scripts\patch-client-dock.mjs'
}

$order = if ($Target -eq 'all') { @('prompt', 'client', 'profile') } else { @($Target) }

Push-Location $plugin
try {
  foreach ($t in $order) {
    $scriptPath = $map[$t]
    if (-not (Test-Path -LiteralPath $scriptPath)) {
      Write-Host "[x] 缺少脚本：$scriptPath" -ForegroundColor Red
      exit 3
    }
    Write-Host "==> node $scriptPath $($Rest -join ' ')" -ForegroundColor DarkGray
    & node $scriptPath @Rest
    if ($LASTEXITCODE -ne 0) {
      Write-Host "[x] $t 失败（exit $LASTEXITCODE）" -ForegroundColor Red
      exit $LASTEXITCODE
    }
  }
} finally {
  Pop-Location
}

Write-Host "[ok] 构建完成：$($order -join ', ')" -ForegroundColor Green
