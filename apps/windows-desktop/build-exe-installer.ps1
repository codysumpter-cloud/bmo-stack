param(
  [string]$AppVersion = '0.1.0',
  [string]$CertificateThumbprint = '',
  [switch]$SkipSigning
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$appRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$distRoot = Join-Path $appRoot 'dist'
$stageRoot = Join-Path $distRoot 'exe-stage'
$appStage = Join-Path $stageRoot 'app'
$launcherStage = Join-Path $stageRoot 'launcher'
$installerScript = Join-Path $appRoot 'installer\BMO-Windows-Desktop.iss'
$launchScript = Join-Path $appRoot 'launch.ps1'
$portableBuilder = Join-Path $appRoot 'build-portable.ps1'

function Require-Command {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [string]$HelpText = ''
  )

  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($null -eq $command) {
    $message = "Missing required tool: $Name"
    if ($HelpText) {
      $message += "`r`n$HelpText"
    }
    throw $message
  }

  return $command.Source
}

function Get-SignToolPath {
  $command = Get-Command signtool.exe -ErrorAction SilentlyContinue
  if ($null -ne $command) {
    return $command.Source
  }
  return $null
}

& powershell -ExecutionPolicy Bypass -File $portableBuilder | Out-Null

if (Test-Path $stageRoot) {
  Remove-Item -LiteralPath $stageRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $appStage -Force | Out-Null
New-Item -ItemType Directory -Path $launcherStage -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $appRoot 'config') -Destination $appStage -Recurse
Copy-Item -LiteralPath (Join-Path $appRoot 'policies') -Destination $appStage -Recurse
Copy-Item -LiteralPath (Join-Path $appRoot 'src') -Destination $appStage -Recurse
Copy-Item -LiteralPath $launchScript -Destination $appStage
Copy-Item -LiteralPath (Join-Path $appRoot 'README.md') -Destination $appStage
Copy-Item -LiteralPath (Join-Path $appRoot 'install.ps1') -Destination $appStage
Copy-Item -LiteralPath (Join-Path $appRoot 'uninstall.ps1') -Destination $appStage

$ps2exeCommand = Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue
if ($null -eq $ps2exeCommand) {
  $ps2exeModulePath = Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules\ps2exe\ps2exe.psm1'
  if (Test-Path $ps2exeModulePath) {
    Import-Module $ps2exeModulePath -Force
  } else {
    throw "Missing required tool: Invoke-PS2EXE`r`nInstall the ps2exe module, then rerun this script."
  }
}

$outputExe = Join-Path $launcherStage 'BMO Windows Desktop.exe'
Invoke-PS2EXE -InputFile $launchScript -OutputFile $outputExe -NoConsole -Title 'BMO Windows Desktop' -Company 'BMO Stack' -Product 'BMO Windows Desktop'

$isccPath = Require-Command -Name 'ISCC.exe' -HelpText 'Install Inno Setup and make ISCC.exe available on PATH.'

$installerTemplate = Get-Content -LiteralPath $installerScript -Raw
$installerTemplate = $installerTemplate.Replace('#define MyAppVersion "0.1.0"', "#define MyAppVersion `"$AppVersion`"")
$resolvedInstallerScript = Join-Path $stageRoot 'BMO-Windows-Desktop.generated.iss'
$installerTemplate | Set-Content -LiteralPath $resolvedInstallerScript -Encoding ASCII

& $isccPath $resolvedInstallerScript

$setupExe = Join-Path $distRoot 'installer-exe\BMO-Windows-Desktop-Setup.exe'
if (-not (Test-Path $setupExe)) {
  throw "Installer build did not produce $setupExe"
}

if (-not $SkipSigning) {
  if ([string]::IsNullOrWhiteSpace($CertificateThumbprint)) {
    throw 'Signing requested but no certificate thumbprint was provided.'
  }

  $signToolPath = Get-SignToolPath
  if ($null -eq $signToolPath) {
    throw 'signtool.exe was not found. Install Windows SDK signing tools or rerun with -SkipSigning.'
  }

  & $signToolPath sign /sha1 $CertificateThumbprint /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $outputExe $setupExe
}

Write-Host "Launcher EXE created at $outputExe"
Write-Host "Installer EXE created at $setupExe"
if ($SkipSigning) {
  Write-Host 'Signing skipped.'
}
