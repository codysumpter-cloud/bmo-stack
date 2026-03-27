Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$installRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$statePath = Join-Path $installRoot 'install-state.json'
$desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'BMO Windows Desktop.lnk'
$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\BMO'
$dataRoot = Join-Path $env:LOCALAPPDATA 'BMO'

if (Test-Path $statePath) {
  $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
  $desktopShortcut = $state.desktopShortcut
  $startMenuDir = $state.startMenuDir
  $dataRoot = $state.dataRoot
}

Add-Type -AssemblyName System.Windows.Forms

if ([System.Windows.Forms.SystemInformation]::UserInteractive) {
  $answer = [System.Windows.Forms.MessageBox]::Show(
    "Remove BMO Windows Desktop from this computer?`r`n`r`nApp data under $dataRoot will be kept.",
    'Uninstall BMO Windows Desktop',
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
  )
  if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
    exit 0
  }
}

if (Test-Path $desktopShortcut) {
  Remove-Item -LiteralPath $desktopShortcut -Force
}

if (Test-Path $startMenuDir) {
  Remove-Item -LiteralPath $startMenuDir -Recurse -Force
}

$currentPid = $PID
$cleanupScript = @"
Start-Sleep -Seconds 1
if (Test-Path '$installRoot') {
  Remove-Item -LiteralPath '$installRoot' -Recurse -Force
}
"@

Start-Process powershell -WindowStyle Hidden -ArgumentList '-ExecutionPolicy','Bypass','-Command',$cleanupScript | Out-Null
Write-Host 'BMO Windows Desktop has been removed. App data was left in place.'
