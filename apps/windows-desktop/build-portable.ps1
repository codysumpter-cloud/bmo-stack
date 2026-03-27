Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$distRoot = Join-Path $appRoot 'dist'
$bundleRoot = Join-Path $distRoot 'BMO-Windows-Desktop'
$zipPath = Join-Path $distRoot 'BMO-Windows-Desktop.zip'
$installerRoot = Join-Path $distRoot 'BMO-Windows-Desktop-Installer'
$installerZipPath = Join-Path $distRoot 'BMO-Windows-Desktop-Installer.zip'

if (Test-Path $bundleRoot) {
  Remove-Item -LiteralPath $bundleRoot -Recurse -Force
}

if (Test-Path $zipPath) {
  Remove-Item -LiteralPath $zipPath -Force
}

if (Test-Path $installerRoot) {
  Remove-Item -LiteralPath $installerRoot -Recurse -Force
}

if (Test-Path $installerZipPath) {
  Remove-Item -LiteralPath $installerZipPath -Force
}

New-Item -ItemType Directory -Path $bundleRoot -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $appRoot 'launch.bat') -Destination $bundleRoot
Copy-Item -LiteralPath (Join-Path $appRoot 'launch.ps1') -Destination $bundleRoot
Copy-Item -LiteralPath (Join-Path $appRoot 'install.ps1') -Destination $bundleRoot
Copy-Item -LiteralPath (Join-Path $appRoot 'uninstall.ps1') -Destination $bundleRoot
Copy-Item -LiteralPath (Join-Path $appRoot 'build-exe-installer.ps1') -Destination $bundleRoot
Copy-Item -LiteralPath (Join-Path $appRoot 'README.md') -Destination $bundleRoot
Copy-Item -LiteralPath (Join-Path $appRoot 'config') -Destination $bundleRoot -Recurse
Copy-Item -LiteralPath (Join-Path $appRoot 'installer') -Destination $bundleRoot -Recurse
Copy-Item -LiteralPath (Join-Path $appRoot 'policies') -Destination $bundleRoot -Recurse
Copy-Item -LiteralPath (Join-Path $appRoot 'src') -Destination $bundleRoot -Recurse

New-Item -ItemType Directory -Path $distRoot -Force | Out-Null
Compress-Archive -Path (Join-Path $bundleRoot '*') -DestinationPath $zipPath

New-Item -ItemType Directory -Path $installerRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $bundleRoot '*') -Destination $installerRoot -Recurse

$installCmd = Join-Path $installerRoot 'Install BMO Windows Desktop.bat'
@'
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
'@ | Set-Content -LiteralPath $installCmd -Encoding ASCII

Compress-Archive -Path (Join-Path $installerRoot '*') -DestinationPath $installerZipPath

Write-Host "Portable bundle created at $zipPath"
Write-Host "Installer bundle created at $installerZipPath"
