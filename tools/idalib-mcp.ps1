<#
  tools/idalib-mcp.ps1 —— idalib-mcp（无头 IDA MCP supervisor）安装与验证入口

  项目：https://github.com/nyaoouo/idalib-mcp
  本地：mcp/idalib-mcp（源码 + .venv，不纳入版本控制）
  依赖：ida-pro-mcp 固定到 858b1e5（含 isolated_contexts 的最后一个版本），
        否则 supervisor 启动即 TypeError；idalib 分析需要 IDA Pro 9.0+ 的 idalib.dll。

  用法：
    .\tools\idalib-mcp.ps1 check                 体检：venv / 模块 / idalib.dll / CLI
    .\tools\idalib-mcp.ps1 probe                 MCP 协议探针（initialize / tools/list / idalib_list）
    .\tools\idalib-mcp.ps1 start                 HTTP 模式启动（默认 127.0.0.1:8745）
    .\tools\idalib-mcp.ps1 start -IdaHome D:\IDA_PRO_9.1
    .\tools\idalib-mcp.ps1 config                打印 MCP 客户端配置片段
    .\tools\idalib-mcp.ps1 install -Client claude-code -Scope global
    .\tools\idalib-mcp.ps1 bootstrap             从零复现安装（venv + 依赖 + 固定版本）
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('check', 'probe', 'start', 'config', 'install', 'bootstrap')]
  [string]$Command = 'check',

  [string]$IdaHome,
  [string]$Client = 'claude-code',
  [ValidateSet('global', 'project')]
  [string]$Scope = 'global',
  [int]$Port = 8745,
  [int]$MaxWorkers = 2
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$env:PYTHONIOENCODING = 'utf-8'

$repoRoot = Split-Path -Parent $PSScriptRoot
$proj     = Join-Path $repoRoot 'mcp\idalib-mcp'
$venvPy   = Join-Path $proj '.venv\Scripts\python.exe'
$cliExe   = Join-Path $proj '.venv\Scripts\idalib-mcp-headless.exe'
$probe    = Join-Path $repoRoot 'mcp\probe_idalib_mcp.py'
$pin      = '858b1e5'
$py312    = 'C:\Users\22878\AppData\Roaming\uv\python\cpython-3.12.15-windows-x86_64-none\python.exe'

function Show-Doctor {
  Write-Host "== idalib-mcp 体检 ==" -ForegroundColor Cyan
  Write-Host ("  项目目录 : {0}  ({1})" -f $proj, $(if (Test-Path $proj) { 'ok' } else { '缺失' }))
  Write-Host ("  venv     : {0}  ({1})" -f $venvPy, $(if (Test-Path $venvPy) { 'ok' } else { '缺失 → 跑 bootstrap' }))
  if (-not (Test-Path $venvPy)) { return 2 }

  Write-Host ("  Python   : " + (& $venvPy --version 2>&1))

  $mods = & $venvPy -c "import idalib_mcp, ida_pro_mcp, ida_pro_mcp.idalib_supervisor, tomli_w; print('all modules ok')" 2>&1
  Write-Host ("  模块检查 : " + ($mods -join " "))

  $sig = & $venvPy -c "import inspect, ida_pro_mcp.idalib_supervisor as s; print(inspect.signature(s.IdalibSupervisor.__init__))" 2>&1
  Write-Host ("  supervisor 签名 : " + ($sig -join ' '))

  Write-Host "  IDA 运行时 :" -NoNewline
  if ($IdaHome) { $env:IDADIR = $IdaHome }
  $idaProbe = & $venvPy -c "import idapro; print('idapro ok')" 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host " ok（IDADIR=$env:IDADIR）" -ForegroundColor Green
  } else {
    Write-Host " 缺 idalib.dll" -ForegroundColor Yellow
    Write-Host ("    " + (($idaProbe | Select-Object -Last 1)))
    Write-Host "    → 需要 IDA Pro 9.0+，然后：pip install <IDA>\idalib\python 并设置 IDADIR" -ForegroundColor Yellow
  }

  Write-Host "  CLI      :" -NoNewline
  if (Test-Path $cliExe) {
    $v = & $cliExe --list-clients 2>&1 | Select-Object -First 3
    Write-Host " ok" -ForegroundColor Green
  } else {
    Write-Host " 缺失" -ForegroundColor Red
  }
  return 0
}

function Invoke-Bootstrap {
  Write-Host "== bootstrap：复现安装 ==" -ForegroundColor Cyan
  $py = if (Test-Path $py312) { $py312 } else { (Get-Command python -ErrorAction SilentlyContinue).Source }
  if (-not $py) { Write-Host "  [x] 找不到 Python 3.12+，先装 Python" -ForegroundColor Red; return 2 }
  Write-Host ("  Python: {0}" -f $py)

  if (-not (Test-Path $proj)) {
    New-Item -ItemType Directory -Force (Split-Path $proj) | Out-Null
    git clone "https://ghfast.top/https://github.com/nyaoouo/idalib-mcp.git" $proj
    git -C $proj remote set-url origin "https://github.com/nyaoouo/idalib-mcp.git"
    git -C $proj remote add mirror "https://ghfast.top/https://github.com/nyaoouo/idalib-mcp.git" 2>$null
  }

  if (-not (Test-Path $venvPy)) { & $py -m venv (Join-Path $proj '.venv') }

  $src = Join-Path $repoRoot 'mcp\ida-pro-mcp-src'
  if (-not (Test-Path $src)) {
    git clone "https://ghfast.top/https://github.com/mrexodia/ida-pro-mcp.git" $src
  }
  git -C $src checkout -q -B "pin-$pin" $pin

  & $venvPy -m pip install -q --upgrade pip
  & $venvPy -m pip install -q --no-deps --force-reinstall --no-cache-dir $src
  & $venvPy -m pip install -q -e $proj --no-deps
  & $venvPy -m pip install -q tomli-w idapro
  Write-Host "  [ok] 安装完成；接着跑：.\tools\idalib-mcp.ps1 check" -ForegroundColor Green
  return 0
}

switch ($Command) {
  'bootstrap' { exit (Invoke-Bootstrap) }
  'check'     { exit (Show-Doctor) }
  'probe' {
    if (-not (Test-Path $probe)) { Write-Host "[x] 缺少探针脚本 $probe" -ForegroundColor Red; exit 2 }
    & $venvPy -X utf8 $probe
    exit $LASTEXITCODE
  }
  'start' {
    $args0 = @('-X', 'utf8', '-m', 'idalib_mcp', '--host', '127.0.0.1', '--port', "$Port", '--max-workers', "$MaxWorkers")
    if ($IdaHome) { $args0 += @('--ida-home', $IdaHome) }
    Write-Host ("==> " + $venvPy + " " + ($args0 -join ' ')) -ForegroundColor DarkGray
    Push-Location $proj
    try { & $venvPy @args0 } finally { Pop-Location }
    exit $LASTEXITCODE
  }
  'config' {
    $a = @('--config')
    if ($IdaHome) { $a += @('--ida-home', $IdaHome) }
    & $cliExe @a
    exit $LASTEXITCODE
  }
  'install' {
    $a = @('--install', $Client, '--scope', $Scope, '--transport', 'stdio')
    if ($IdaHome) { $a += @('--ida-home', $IdaHome) }
    Write-Host ("==> idalib-mcp-headless " + ($a -join ' ')) -ForegroundColor DarkGray
    & $cliExe @a
    exit $LASTEXITCODE
  }
}
