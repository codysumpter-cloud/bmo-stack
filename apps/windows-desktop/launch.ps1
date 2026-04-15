param(
  [switch]$SmokeTest,
  [string]$WorkspacePath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$main = Join-Path $root 'src\BMO.Desktop.ps1'
$installState = Join-Path $root 'install-state.json'

if (-not (Test-Path $main)) {
  throw "Missing app entrypoint: $main"
}

if (Test-Path $installState) {
  try {
    $state = Get-Content -LiteralPath $installState -Raw | ConvertFrom-Json
    if (-not [string]::IsNullOrWhiteSpace($state.dataRoot)) {
      $env:BMO_DATA_ROOT = $state.dataRoot
    }
  } catch {
  }
}

& $main -SmokeTest:$SmokeTest -WorkspacePath $WorkspacePath
