<#
  tools/doctor.ps1 —— 仓库与运行环境体检（只读，不改任何文件）

  检查项：
    1. 工具链：node / npm / git 是否可用
    2. 插件来源：plugins/dsh-purge 是否存在、版本、HEAD、上游落后情况
    3. 宿主安装：$DSH_HOME\plugins\dsh-purge 的版本与 profile 登记
    4. 清洗状态：override 文件、installed-rev、shim 目录

  用法：.\tools\doctor.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }

function Section([string]$title) {
  Write-Host ""
  Write-Host "== $title ==" -ForegroundColor Cyan
}

function Try-Cmd([string]$name) {
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if ($c) { return $c.Source } else { return $null }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$plugin   = Join-Path $repoRoot 'plugins\dsh-purge'
$dshHome  = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $env:USERPROFILE '.dsh' }

Section '1. 工具链'
foreach ($t in @('node', 'npm', 'git')) {
  $p = Try-Cmd $t
  if ($p) {
    $v = (& $t --version 2>$null | Select-Object -First 1)
    Write-Host ("  [ok] {0,-5} {1}  ({2})" -f $t, $v, $p) -ForegroundColor Green
  } else {
    Write-Host ("  [x]  {0,-5} 未安装或不在 PATH" -f $t) -ForegroundColor Red
  }
}

Section '2. 插件来源 (plugins/*)'
$pluginRoot = Join-Path $repoRoot 'plugins'
$pluginDirs = @(Get-ChildItem -LiteralPath $pluginRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'node_modules' })
if ($pluginDirs.Count -eq 0) {
  Write-Host "  [x] plugins/ 下没有插件" -ForegroundColor Red
}
foreach ($pd in $pluginDirs) {
  $plugin  = $pd.FullName
  $pkgPath = Join-Path $plugin 'package.json'
  if (-not (Test-Path -LiteralPath $pkgPath)) {
    Write-Host ("  [!]  {0}：没有 package.json（不是插件目录？）" -f $pd.Name) -ForegroundColor Yellow
    continue
  }
  $pkg = Get-Content -LiteralPath $pkgPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Write-Host ("  {0}  {1}" -f $pd.Name, $pkg.version) -ForegroundColor Green
  $head  = (git -C $plugin rev-parse --short HEAD 2>$null)
  $br    = (git -C $plugin rev-parse --abbrev-ref HEAD 2>$null)
  $dirty = (git -C $plugin status --porcelain 2>$null)
  Write-Host ("       HEAD {0}  分支 {1}  工作区{2}" -f $head, $br, $(if ($dirty) { '有改动' } else { '干净' }))
  $mirrorRef = "mirror/$br"
  $mirror = (git -C $plugin rev-parse $mirrorRef 2>$null)
  if ($mirror) {
    $behind = (git -C $plugin rev-list --count "HEAD..$mirrorRef" 2>$null)
    if ([int]$behind -gt 0) {
      Write-Host ("       [!] 落后 {0} {1} 个提交 -> .\tools\sync.ps1 -Apply -Plugin {2}" -f $mirrorRef, $behind, $pd.Name) -ForegroundColor Yellow
    } else {
      Write-Host "       [ok] 与 mirror 一致" -ForegroundColor Green
    }
  } else {
    Write-Host "       [!] 未 fetch mirror，无法比对（.\tools\sync.ps1 可更新缓存）" -ForegroundColor Yellow
  }
}

Section '3. 宿主安装'
$patchYml = Join-Path $dshHome 'profiles\desktop\cordis.patch.yml'
foreach ($pd in $pluginDirs) {
  $installed = Join-Path (Join-Path $dshHome 'plugins') $pd.Name
  if (Test-Path -LiteralPath $installed) {
    $ipkg = Join-Path $installed 'package.json'
    $ver  = if (Test-Path -LiteralPath $ipkg) { (Get-Content -LiteralPath $ipkg -Raw -Encoding UTF8 | ConvertFrom-Json).version } else { '?' }
    Write-Host ("  [ok] 已装进宿主 {0,-12} {1}" -f $pd.Name, $ver) -ForegroundColor Green
  } else {
    Write-Host ("  [!]  未装进宿主：{0}" -f $installed) -ForegroundColor Yellow
  }
}

$profilePkg = Join-Path $dshHome 'profiles\desktop\package.json'
$bundleText = if (Test-Path -LiteralPath $profilePkg) { Get-Content -LiteralPath $profilePkg -Raw -Encoding UTF8 } else { '' }
$patchText  = if (Test-Path -LiteralPath $patchYml) { Get-Content -LiteralPath $patchYml -Raw -Encoding UTF8 } else { '' }
foreach ($pd in $pluginDirs) {
  $hit = ($bundleText -match [regex]::Escape($pd.Name)) -or ($patchText -match [regex]::Escape($pd.Name))
  if ($hit) { Write-Host ("  [ok] profile 已登记 {0}（bundles/cordis.patch.yml）" -f $pd.Name) -ForegroundColor Green }
  else { Write-Host ("  [!] profile 未登记 {0}（两处都没有）" -f $pd.Name) -ForegroundColor Yellow }
}

Section '4. 清洗状态'
$stateDir = Join-Path $dshHome 'dsh-purge'
$revFile  = Join-Path $stateDir 'installed-rev'
$ovState  = Join-Path $stateDir 'override-state.json'
if (Test-Path -LiteralPath $revFile) {
  Write-Host ("  installed-rev: {0}" -f (Get-Content -LiteralPath $revFile -Raw -Encoding UTF8).Trim())
} else {
  Write-Host "  installed-rev: 无" -ForegroundColor Yellow
}
if (Test-Path -LiteralPath $ovState) {
  $ov = Get-Content -LiteralPath $ovState -Raw -Encoding UTF8 | ConvertFrom-Json
  $status = if ($ov.PSObject.Properties['status']) { $ov.status } else { ($ov | ConvertTo-Json -Compress) }
  Write-Host ("  override 状态: {0}" -f $status)
} else {
  Write-Host "  override 状态: 无（未 apply）" -ForegroundColor Yellow
}
if (Test-Path -LiteralPath (Join-Path $dshHome 'prompt-inject.md')) {
  Write-Host ("  注入文件: {0}" -f (Join-Path $dshHome 'prompt-inject.md'))
}

Write-Host ""
Write-Host "[完成] doctor 结束（只读检查）" -ForegroundColor Green
