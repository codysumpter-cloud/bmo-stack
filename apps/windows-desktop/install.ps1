param(
  [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'Programs\BMO-Windows-Desktop'),
  [string]$DataRoot = (Join-Path $env:LOCALAPPDATA 'BMO'),
  [switch]$NoShortcuts
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sourceRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$startMenuDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\BMO'
$startMenuShortcut = Join-Path $startMenuDir 'BMO Windows Desktop.lnk'
$uninstallShortcut = Join-Path $startMenuDir 'Uninstall BMO Windows Desktop.lnk'
$desktopFolder = [Environment]::GetFolderPath('Desktop')
$desktopShortcut = ''

if (-not [string]::IsNullOrWhiteSpace($desktopFolder)) {
  $desktopShortcut = Join-Path $desktopFolder 'BMO Windows Desktop.lnk'
}

function New-Shortcut {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ShortcutPath,
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,
    [string]$Arguments = '',
    [string]$WorkingDirectory = '',
    [string]$Description = ''
  )

  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($ShortcutPath)
  $shortcut.TargetPath = $TargetPath
  if ($Arguments) { $shortcut.Arguments = $Arguments }
  if ($WorkingDirectory) { $shortcut.WorkingDirectory = $WorkingDirectory }
  if ($Description) { $shortcut.Description = $Description }
  $shortcut.Save()
}

if (Test-Path $InstallRoot) {
  Remove-Item -LiteralPath $InstallRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceRoot 'config') -Destination $InstallRoot -Recurse
Copy-Item -LiteralPath (Join-Path $sourceRoot 'policies') -Destination $InstallRoot -Recurse
Copy-Item -LiteralPath (Join-Path $sourceRoot 'src') -Destination $InstallRoot -Recurse
Copy-Item -LiteralPath (Join-Path $sourceRoot 'README.md') -Destination $InstallRoot
Copy-Item -LiteralPath (Join-Path $sourceRoot 'launch.ps1') -Destination $InstallRoot
Copy-Item -LiteralPath (Join-Path $sourceRoot 'launch.bat') -Destination $InstallRoot

New-Item -ItemType Directory -Path $DataRoot -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $DataRoot 'config') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $DataRoot 'logs') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $DataRoot 'tasks') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $DataRoot 'memory') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $DataRoot 'workspaces') -Force | Out-Null

$settingsPath = Join-Path $DataRoot 'config\appsettings.json'
if (-not (Test-Path $settingsPath)) {
  Copy-Item -LiteralPath (Join-Path $sourceRoot 'config\appsettings.example.json') -Destination $settingsPath
}

Copy-Item -LiteralPath (Join-Path $sourceRoot 'uninstall.ps1') -Destination $InstallRoot

$state = [pscustomobject]@{
  installRoot = $InstallRoot
  dataRoot = $DataRoot
  desktopShortcut = $desktopShortcut
  startMenuDir = $startMenuDir
}
$state | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $InstallRoot 'install-state.json') -Encoding UTF8

if (-not $NoShortcuts) {
  New-Item -ItemType Directory -Path $startMenuDir -Force | Out-Null

  if (-not [string]::IsNullOrWhiteSpace($desktopShortcut)) {
    New-Shortcut -ShortcutPath $desktopShortcut `
      -TargetPath 'powershell.exe' `
      -Arguments "-ExecutionPolicy Bypass -File `"$InstallRoot\launch.ps1`"" `
      -WorkingDirectory $InstallRoot `
      -Description 'Launch BMO Windows Desktop'
  }

  New-Shortcut -ShortcutPath $startMenuShortcut `
    -TargetPath 'powershell.exe' `
    -Arguments "-ExecutionPolicy Bypass -File `"$InstallRoot\launch.ps1`"" `
    -WorkingDirectory $InstallRoot `
    -Description 'Launch BMO Windows Desktop'

  New-Shortcut -ShortcutPath $uninstallShortcut `
    -TargetPath 'powershell.exe' `
    -Arguments "-ExecutionPolicy Bypass -File `"$InstallRoot\uninstall.ps1`"" `
    -WorkingDirectory $InstallRoot `
    -Description 'Uninstall BMO Windows Desktop'
}

Write-Host "Installed to $InstallRoot"
Write-Host "Data directory: $DataRoot"
if (-not $NoShortcuts) {
  if (-not [string]::IsNullOrWhiteSpace($desktopShortcut)) {
    Write-Host "Desktop shortcut: $desktopShortcut"
  }
}
