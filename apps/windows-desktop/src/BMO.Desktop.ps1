param(
  [switch]$SmokeTest,
  [string]$WorkspacePath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'BMO.Broker.ps1')
. (Join-Path $PSScriptRoot 'BMO.Workstation.ps1')

$settings = Initialize-BmoSettings
Write-BmoLog -Category 'startup' -Message 'Desktop app launched.'

if ($SmokeTest) {
  Invoke-BmoDesktopSmokeTest -WorkspacePath $WorkspacePath
  return
}

$initialWorkspace = $WorkspacePath
if ([string]::IsNullOrWhiteSpace($initialWorkspace)) {
  $initialWorkspace = $settings.defaultWorkspace
}

Start-BmoDesktopApp -InitialWorkspace $initialWorkspace
