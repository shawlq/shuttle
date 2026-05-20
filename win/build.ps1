#Requires -Version 5.1
param(
    [switch]$SkipVenv
)

$ErrorActionPreference = "Stop"
$WinDir = $PSScriptRoot

Set-Location $WinDir

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $global:ShuttlePy = "py -3"
    } else {
        throw "Python not found. Install Python 3 and ensure python or py is on PATH."
    }
} else {
    $global:ShuttlePy = "python"
}

function Invoke-ShuttlePy {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    if ($global:ShuttlePy -eq "python") {
        & python @Args
    } else {
        & py -3 @Args
    }
    if ($LASTEXITCODE -ne 0) { throw "python failed: $Args" }
}

$venv = Join-Path $WinDir ".build-venv"
$pythonExe = $null

if (-not $SkipVenv) {
    if (-not (Test-Path $venv)) {
        Write-Host "Creating venv: $venv"
        Invoke-ShuttlePy -m venv $venv
    }
    $pythonExe = Join-Path $venv "Scripts\python.exe"
} else {
    if ($global:ShuttlePy -eq "python") {
        $pythonExe = (Get-Command python).Source
    } else {
        throw "SkipVenv requires python on PATH"
    }
}

Write-Host "Installing build dependencies..."
& $pythonExe -m pip install -q -U pip
& $pythonExe -m pip install -q -r (Join-Path $WinDir "requirements-build.txt")
if ($LASTEXITCODE -ne 0) { throw "pip install failed" }

Write-Host "Running PyInstaller (onedir)..."
& $pythonExe -m PyInstaller --noconfirm --clean (Join-Path $WinDir "shuttle.spec")
if ($LASTEXITCODE -ne 0) { throw "PyInstaller failed" }

$outDir = Join-Path $WinDir "dist\shuttle"
$internal = Join-Path $outDir "_internal"

$requiredDlls = @("vcruntime140.dll", "vcruntime140_1.dll")
$missing = @()
foreach ($dll in $requiredDlls) {
    if (-not (Test-Path (Join-Path $internal $dll))) {
        $missing += $dll
    }
}
$pyDll = Get-ChildItem -Path $internal -Filter "python3*.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $pyDll) {
    $missing += "python3*.dll"
}

if ($missing.Count -gt 0) {
    throw "Packaging incomplete, missing in _internal: $($missing -join ', ')"
}

Write-Host ""
Write-Host "Done: $outDir" -ForegroundColor Green
Write-Host "Run:  $outDir\shuttle.exe"
Write-Host ""
Write-Host "Distribute: copy the ENTIRE folder dist\shuttle (shuttle.exe + _internal\)."
Write-Host "Do NOT use win\build\ — that is an intermediate build cache only."
Write-Host "Git must be on PATH. Config: .shuttle.env next to exe."
