<#
  tools/sync.ps1 —— 与上游同步插件（默认走各插件的 mirror 远程；GitHub 直连被重置时用）

  每个插件目录里有两个远程：
    origin  = 官方仓库（https://github.com/<owner>/<repo>.git）
    mirror  = https://ghfast.top/https://github.com/<owner>/<repo>.git

  用法：
    .\tools\sync.ps1                     检查全部插件（fetch + 列出落后提交）
    .\tools\sync.ps1 -Apply              快进合并到上游最新（ff-only）
    .\tools\sync.ps1 -Plugin dsh-vars    只处理一个插件（默认 all = plugins/ 下全部）
    .\tools\sync.ps1 -Remote origin      强制走官方（需要能直连 GitHub）

  注意：插件登记为 submodule，插件更新后父仓库指针会变化，
        需要 git add plugins/<name> 再提交（脚本会提示，不自动提交）。
#>
[CmdletBinding()]
param(
  [switch]$Apply,
  [string]$Remote = 'mirror',
  [string]$Plugin = 'all'
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

$repoRoot = Split-Path -Parent $PSScriptRoot

function Sync-One {
  param(
    [string]$Name,
    [string]$RemoteName,
    [bool]$DoApply
  )

  $plugin = Join-Path $repoRoot "plugins\$Name"
  Write-Host ""
  Write-Host "== $Name ==" -ForegroundColor Cyan

  if (-not (Test-Path -LiteralPath (Join-Path $plugin '.git'))) {
    Write-Host "  [x] 未克隆：$plugin" -ForegroundColor Red
    return 2
  }

  git -C $plugin remote get-url $RemoteName *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "  [x] 远程 '$RemoteName' 未配置；已有远程：" -ForegroundColor Red
    git -C $plugin remote -v | ForEach-Object { "      $_" }
    return 2
  }

  Write-Host "  ==> git fetch $RemoteName" -ForegroundColor DarkGray
  git -C $plugin fetch --prune --tags $RemoteName 2>&1 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
  if ($LASTEXITCODE -ne 0) {
    Write-Host "  [x] fetch 失败，检查网络或换远程：-Remote origin" -ForegroundColor Red
    return 3
  }

  $branch  = (git -C $plugin rev-parse --abbrev-ref HEAD).Trim()
  $tracked = "$RemoteName/$branch"
  $local   = (git -C $plugin rev-parse HEAD).Trim()
  $up      = git -C $plugin rev-parse $tracked 2>$null
  if (-not $up) {
    Write-Host "  [!] 远程没有分支 $tracked" -ForegroundColor Yellow
    return 0
  }
  $up = $up.Trim()

  if ($local -eq $up) {
    Write-Host "  [ok] 已是最新：$branch @ $($local.Substring(0, 7))" -ForegroundColor Green
    return 0
  }

  $ahead = [int](git -C $plugin rev-list --count "$tracked..HEAD")
  if ($ahead -gt 0) {
    Write-Host "  [!] 本地领先 $ahead 个提交（插件目录被改过？）" -ForegroundColor Yellow
  }

  Write-Host "  待合入的上游提交：" -ForegroundColor Cyan
  git -C $plugin log --oneline --no-decorate "$local..$tracked" | Select-Object -First 20 | ForEach-Object { Write-Host "    $_" }

  if (-not $DoApply) {
    Write-Host "  [i] 只检查，未改动。拉取：-Apply" -ForegroundColor Yellow
    return 0
  }

  Write-Host "  ==> git merge --ff-only $tracked" -ForegroundColor DarkGray
  git -C $plugin merge --ff-only $tracked
  if ($LASTEXITCODE -ne 0) {
    Write-Host "  [x] 无法快进：存在本地改动或分叉，先手动处理后重试" -ForegroundColor Red
    return 4
  }

  Write-Host "  [ok] 已更新 → $((git -C $plugin rev-parse HEAD).Trim().Substring(0, 7))" -ForegroundColor Green
  return 0
}

$pluginRoot = Join-Path $repoRoot 'plugins'
if ($Plugin -eq 'all') {
  $names = @(Get-ChildItem -LiteralPath $pluginRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') } |
    Select-Object -ExpandProperty Name |
    Sort-Object)
} else {
  $names = @($Plugin)
}

if ($names.Count -eq 0) {
  Write-Host "[x] plugins/ 下没有任何已克隆的插件" -ForegroundColor Red
  exit 2
}

$rc = 0
foreach ($name in $names) {
  $r = Sync-One -Name $name -RemoteName $Remote -DoApply:$Apply.IsPresent
  if ($r -ne 0) { $rc = $r }
}

Write-Host ""
if ($rc -eq 0) {
  Write-Host "[done] 处理了 $($names.Count) 个插件" -ForegroundColor Green
  if ($Apply) {
    Write-Host "       父仓库记录更新：git add plugins/" -ForegroundColor Yellow
  }
} else {
  Write-Host "[done] 有失败项（rc=$rc），看上面输出" -ForegroundColor Yellow
}
exit $rc
