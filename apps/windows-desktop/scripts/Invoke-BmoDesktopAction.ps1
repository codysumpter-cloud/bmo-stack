param(
  [Parameter(Mandatory = $true)]
  [string]$ActionId,
  [string]$WorkspacePath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$script:WorkspaceRoot = if ([string]::IsNullOrWhiteSpace($WorkspacePath)) {
  $script:RepoRoot
} else {
  (Resolve-Path -LiteralPath $WorkspacePath).Path
}

function Write-BmoStatus {
  param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('PASS', 'WARN', 'FAIL', 'INFO')]
    [string]$Level,
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  Write-Host ("[{0}] {1}" -f $Level, $Message)
}

function Get-BmoCommandSource {
  param([Parameter(Mandatory = $true)][string]$Name)
  return Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Test-BmoCommandInvocation {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [string[]]$ArgumentList = @('--version')
  )

  try {
    & $FilePath @ArgumentList *> $null
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    return ($exitCode -eq 0)
  } catch {
    return $false
  }
}

function Get-BmoPythonInvocation {
  $py = Get-BmoCommandSource -Name 'py'
  if ($null -ne $py -and (Test-BmoCommandInvocation -FilePath $py.Source -ArgumentList @('-3', '--version'))) {
    return [pscustomobject]@{
      available = $true
      filePath = $py.Source
      arguments = @('-3')
      label = 'py -3'
    }
  }

  $python = Get-BmoCommandSource -Name 'python'
  if ($null -ne $python -and (Test-BmoCommandInvocation -FilePath $python.Source -ArgumentList @('--version'))) {
    return [pscustomobject]@{
      available = $true
      filePath = $python.Source
      arguments = @()
      label = 'python'
    }
  }

  $python3 = Get-BmoCommandSource -Name 'python3'
  if ($null -ne $python3 -and (Test-BmoCommandInvocation -FilePath $python3.Source -ArgumentList @('--version'))) {
    return [pscustomobject]@{
      available = $true
      filePath = $python3.Source
      arguments = @()
      label = 'python3'
    }
  }

  return [pscustomobject]@{
    available = $false
    filePath = ''
    arguments = @()
    label = ''
  }
}

function Invoke-BmoExternalCapture {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [string[]]$ArgumentList = @(),
    [string]$WorkingDirectory = $script:RepoRoot
  )

  Push-Location $WorkingDirectory
  try {
    $stdout = & $FilePath @ArgumentList 2>&1
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
  } finally {
    Pop-Location
  }

  $lines = @()
  foreach ($entry in @($stdout)) {
    $lines += [string]$entry
  }

  return [pscustomobject]@{
    exitCode = $exitCode
    lines = @($lines)
    text = ($lines -join "`r`n")
  }
}

function Invoke-BmoExternal {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [string[]]$ArgumentList = @(),
    [string]$WorkingDirectory = $script:RepoRoot
  )

  $display = $FilePath
  if (@($ArgumentList).Count -gt 0) {
    $display += ' ' + (@($ArgumentList) -join ' ')
  }
  Write-BmoStatus -Level INFO -Message ("COMMAND: {0}" -f $display)

  Push-Location $WorkingDirectory
  try {
    & $FilePath @ArgumentList | Out-Host
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
  } finally {
    Pop-Location
  }

  return $exitCode
}

function Get-BmoTrackedStatePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FileName
  )

  $repoPath = Join-Path $script:RepoRoot $FileName
  if (Test-Path -LiteralPath $repoPath) {
    return $repoPath
  }

  $hostContextDir = if (-not [string]::IsNullOrWhiteSpace($env:BMO_HOST_CONTEXT_DIR)) {
    $env:BMO_HOST_CONTEXT_DIR
  } else {
    Join-Path $HOME 'bmo-context'
  }

  $hostPath = Join-Path $hostContextDir $FileName
  if (Test-Path -LiteralPath $hostPath) {
    return $hostPath
  }

  return ''
}

function Show-BmoStateBlock {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  Write-Host ("{0}: {1}" -f $Label, $Path)
  $patterns = '^(Last updated:|- Description:|- Active repo:|- Branch:|- Last successful step:|- Next intended step:|- Verification complete:|- Safe to resume:)'
  $matches = Select-String -Path $Path -Pattern $patterns
  foreach ($match in $matches) {
    Write-Host $match.Line
  }
  Write-Host ''
}

function Test-BmoHttpEndpoint {
  param([Parameter(Mandatory = $true)][string]$Uri)

  try {
    $handler = New-Object System.Net.Http.HttpClientHandler
    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromSeconds(5)
    $response = $client.GetAsync($Uri).GetAwaiter().GetResult()
    return $response.IsSuccessStatusCode
  } catch {
    return $false
  }
}

function Get-BmoEnvMap {
  param([Parameter(Mandatory = $true)][string]$Path)

  $map = @{}
  if (-not (Test-Path -LiteralPath $Path)) {
    return $map
  }

  foreach ($line in Get-Content -LiteralPath $Path) {
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#') -or (-not $trimmed.Contains('='))) {
      continue
    }

    $parts = $trimmed.Split('=', 2)
    $name = $parts[0].Trim()
    $value = $parts[1].Trim().Trim('"')
    $map[$name] = $value
  }

  return $map
}

function Invoke-BmoWorkerStatusAction {
  $issues = 0
  Write-Host '=== BMO Worker Status ==='
  Write-Host ("Repo root: {0}" -f $script:RepoRoot)

  $openclaw = Get-BmoCommandSource -Name 'openclaw'
  if ($null -eq $openclaw) {
    Write-BmoStatus -Level FAIL -Message 'openclaw is not installed or not in PATH.'
    $issues += 1
  } else {
    $gateway = Invoke-BmoExternalCapture -FilePath $openclaw.Source -ArgumentList @('gateway', 'status')
    if ($gateway.exitCode -eq 0) {
      Write-BmoStatus -Level PASS -Message 'openclaw gateway status is reachable.'
      if ($gateway.text -match 'running') {
        Write-BmoStatus -Level PASS -Message 'openclaw gateway reports running.'
      } else {
        Write-BmoStatus -Level WARN -Message 'openclaw gateway did not clearly report running.'
      }
    } else {
      Write-BmoStatus -Level FAIL -Message 'openclaw gateway status failed.'
      if (-not [string]::IsNullOrWhiteSpace($gateway.text)) {
        Write-Host $gateway.text
      }
      $issues += 1
    }

    $agent = Invoke-BmoExternalCapture -FilePath $openclaw.Source -ArgumentList @('status')
    if ($agent.exitCode -eq 0) {
      Write-BmoStatus -Level PASS -Message 'openclaw agent status is healthy.'
    } else {
      Write-BmoStatus -Level FAIL -Message 'openclaw agent status returned non-zero.'
      if (-not [string]::IsNullOrWhiteSpace($agent.text)) {
        Write-Host $agent.text
      }
      $issues += 1
    }
  }

  $openshell = Get-BmoCommandSource -Name 'openshell'
  if ($null -eq $openshell) {
    Write-BmoStatus -Level FAIL -Message 'openshell is not installed or not in PATH.'
    $issues += 1
  } else {
    $sandboxes = Invoke-BmoExternalCapture -FilePath $openshell.Source -ArgumentList @('sandbox', 'list')
    if ($sandboxes.exitCode -eq 0 -and $sandboxes.text -match 'bmo-tron') {
      Write-BmoStatus -Level PASS -Message 'bmo-tron sandbox is present.'
    } elseif ($sandboxes.exitCode -eq 0) {
      Write-BmoStatus -Level WARN -Message 'openshell is available but bmo-tron is not present.'
    } else {
      Write-BmoStatus -Level FAIL -Message 'openshell sandbox list failed.'
      if (-not [string]::IsNullOrWhiteSpace($sandboxes.text)) {
        Write-Host $sandboxes.text
      }
      $issues += 1
    }
  }

  Write-Host ''
  $taskState = Get-BmoTrackedStatePath -FileName 'TASK_STATE.md'
  if (-not [string]::IsNullOrWhiteSpace($taskState)) {
    Show-BmoStateBlock -Label 'Task state' -Path $taskState
  } else {
    Write-BmoStatus -Level WARN -Message 'TASK_STATE.md not found in repo or host context.'
    Write-Host ''
  }

  $workInProgress = Get-BmoTrackedStatePath -FileName 'WORK_IN_PROGRESS.md'
  if (-not [string]::IsNullOrWhiteSpace($workInProgress)) {
    Show-BmoStateBlock -Label 'Work in progress' -Path $workInProgress
  } else {
    Write-BmoStatus -Level WARN -Message 'WORK_IN_PROGRESS.md not found in repo or host context.'
    Write-Host ''
  }

  Write-Host '=== End Status ==='
  if ($issues -gt 0) {
    return 1
  }
  return 0
}

function Invoke-BmoRuntimeDoctorAction {
  $issues = 0
  $envFile = if (-not [string]::IsNullOrWhiteSpace($env:BMO_RUNTIME_ENV_FILE)) {
    $env:BMO_RUNTIME_ENV_FILE
  } else {
    Join-Path $HOME '.config\bmo-runtime.env'
  }
  $envMap = Get-BmoEnvMap -Path $envFile
  $endpoint = if ($envMap.ContainsKey('BMO_OLLAMA_ENDPOINT')) {
    $envMap['BMO_OLLAMA_ENDPOINT'] + '/api/tags'
  } elseif (-not [string]::IsNullOrWhiteSpace($env:BMO_OLLAMA_ENDPOINT)) {
    $env:BMO_OLLAMA_ENDPOINT + '/api/tags'
  } else {
    'http://127.0.0.1:11434/api/tags'
  }

  Write-Host 'BMO native runtime doctor'
  Write-Host ("repo root: {0}" -f $script:RepoRoot)
  Write-Host ("env file:  {0}" -f $envFile)
  Write-Host ("text model: {0}" -f ($(if ($envMap.ContainsKey('BMO_TEXT_MODEL')) { $envMap['BMO_TEXT_MODEL'] } elseif ($env:BMO_TEXT_MODEL) { $env:BMO_TEXT_MODEL } else { 'gemma3:1b' })))
  Write-Host ("vision model: {0}" -f ($(if ($envMap.ContainsKey('BMO_VISION_MODEL')) { $envMap['BMO_VISION_MODEL'] } elseif ($env:BMO_VISION_MODEL) { $env:BMO_VISION_MODEL } else { 'moondream' })))
  Write-Host ''

  $python = Get-BmoPythonInvocation
  if ($python.available) {
    Write-BmoStatus -Level PASS -Message ("Python launcher found: {0}" -f $python.label)
  } else {
    Write-BmoStatus -Level FAIL -Message 'Python launcher not found.'
    $issues += 1
  }

  foreach ($toolName in @('ollama', 'curl', 'piper', 'node')) {
    $tool = Get-BmoCommandSource -Name $toolName
    if ($null -ne $tool) {
      Write-BmoStatus -Level PASS -Message ("{0} found: {1}" -f $toolName, $tool.Source)
    } else {
      $level = if ($toolName -eq 'node') { 'FAIL' } else { 'WARN' }
      Write-BmoStatus -Level $level -Message ("{0} not found in PATH." -f $toolName)
      if ($level -eq 'FAIL') {
        $issues += 1
      }
    }
  }

  foreach ($fileInfo in @(
    @{ Path = 'scripts\bmo_voice_loop.py'; Label = 'voice loop script'; Required = $false },
    @{ Path = 'scripts\bmo-face.sh'; Label = 'face script'; Required = $false },
    @{ Path = 'scripts\bmo_vision_caption.py'; Label = 'vision helper'; Required = $false },
    @{ Path = 'scripts\apply-bmo-runtime-profile.py'; Label = 'runtime profile helper'; Required = $true }
  )) {
    $fullPath = Join-Path $script:RepoRoot $fileInfo.Path
    if (Test-Path -LiteralPath $fullPath) {
      Write-BmoStatus -Level PASS -Message ("{0} present: {1}" -f $fileInfo.Label, $fullPath)
    } else {
      $level = if ($fileInfo.Required) { 'FAIL' } else { 'WARN' }
      Write-BmoStatus -Level $level -Message ("{0} missing: {1}" -f $fileInfo.Label, $fullPath)
      if ($fileInfo.Required) {
        $issues += 1
      }
    }
  }

  if (Test-Path -LiteralPath $envFile) {
    Write-BmoStatus -Level PASS -Message ("runtime env present: {0}" -f $envFile)
  } else {
    Write-BmoStatus -Level WARN -Message ("runtime env missing: {0}" -f $envFile)
  }

  if (Test-BmoHttpEndpoint -Uri $endpoint) {
    Write-BmoStatus -Level PASS -Message ("Ollama endpoint reachable: {0}" -f $endpoint)
  } else {
    Write-BmoStatus -Level WARN -Message ("Ollama endpoint not reachable yet: {0}" -f $endpoint)
  }

  Write-Host ''
  Write-Host 'Suggested next steps:'
  Write-Host '  1. Populate config/bmo-runtime.env.example into your runtime env file if needed.'
  Write-Host '  2. Apply a runtime profile from the Workstation Operations tab.'
  Write-Host '  3. Re-run runtime doctor after changing runtime prerequisites.'

  if ($issues -gt 0) {
    return 1
  }
  return 0
}

function Invoke-BmoDoctorPlusAction {
  $issues = 0
  Write-Host '=== BMO Doctor Plus ==='

  $node = Get-BmoCommandSource -Name 'node'
  if ($null -eq $node) {
    Write-BmoStatus -Level FAIL -Message 'Node.js is required for operating-system validation.'
    $issues += 1
  } else {
    $validationExit = Invoke-BmoExternal -FilePath $node.Source -ArgumentList @('.\scripts\validate-bmo-operating-system.mjs') -WorkingDirectory $script:RepoRoot
    if ($validationExit -eq 0) {
      Write-BmoStatus -Level PASS -Message 'Operating-system validation succeeded.'
    } else {
      Write-BmoStatus -Level FAIL -Message 'Operating-system validation failed.'
      $issues += 1
    }
  }

  Write-Host ''
  Write-Host '--- Worker Status ---'
  if ((Invoke-BmoWorkerStatusAction) -ne 0) {
    $issues += 1
  }

  Write-Host ''
  Write-Host '--- Runtime Doctor ---'
  if ((Invoke-BmoRuntimeDoctorAction) -ne 0) {
    $issues += 1
  }

  if ($issues -gt 0) {
    return 1
  }
  return 0
}

function Invoke-BmoWorkspaceSyncAction {
  $python = Get-BmoPythonInvocation
  if (-not $python.available) {
    throw 'Workspace sync requires Python, but no supported launcher was found.'
  }

  return Invoke-BmoExternal -FilePath $python.filePath -ArgumentList ($python.arguments + @('.\scripts\bmo-workspace-sync.py')) -WorkingDirectory $script:RepoRoot
}

function Invoke-BmoRuntimeProfileActionImpl {
  param([Parameter(Mandatory = $true)][string]$ProfileName)

  $python = Get-BmoPythonInvocation
  if (-not $python.available) {
    throw 'Runtime profile application requires Python, but no supported launcher was found.'
  }

  return Invoke-BmoExternal -FilePath $python.filePath -ArgumentList ($python.arguments + @('.\scripts\apply-bmo-runtime-profile.py', $ProfileName)) -WorkingDirectory $script:RepoRoot
}

function Invoke-BmoSiteCaretakerAction {
  $node = Get-BmoCommandSource -Name 'node'
  if ($null -eq $node) {
    throw 'Site caretaker requires Node.js in PATH.'
  }

  return Invoke-BmoExternal -FilePath $node.Source -ArgumentList @('.\scripts\bmo-site-caretaker.mjs') -WorkingDirectory $script:RepoRoot
}

function Invoke-BmoWorkerReadyAction {
  $openshell = Get-BmoCommandSource -Name 'openshell'
  if ($null -eq $openshell) {
    throw 'Worker-ready requires openshell in PATH.'
  }

  $configPath = Join-Path $HOME '.openclaw\openclaw.json'
  if (-not (Test-Path -LiteralPath $configPath)) {
    throw "OpenClaw config not found at $configPath"
  }

  $listResult = Invoke-BmoExternalCapture -FilePath $openshell.Source -ArgumentList @('sandbox', 'list')
  if ($listResult.exitCode -ne 0) {
    throw 'Unable to list openshell sandboxes.'
  }

  if ($listResult.text -match 'bmo-tron') {
    Write-BmoStatus -Level INFO -Message 'Sandbox bmo-tron already exists.'
  } else {
    $createExit = Invoke-BmoExternal -FilePath $openshell.Source -ArgumentList @('sandbox', 'create', '--name', 'bmo-tron') -WorkingDirectory $script:RepoRoot
    if ($createExit -ne 0) {
      return $createExit
    }
  }

  return Invoke-BmoExternal -FilePath $openshell.Source -ArgumentList @('sandbox', 'upload', 'bmo-tron', $configPath, '.openclaw/openclaw.json') -WorkingDirectory $script:RepoRoot
}

$normalizedActionId = $ActionId.Trim().ToLowerInvariant()
try {
  $exitCode = switch ($normalizedActionId) {
    'doctor-plus' { Invoke-BmoDoctorPlusAction }
    'worker-status' { Invoke-BmoWorkerStatusAction }
    'runtime-doctor' { Invoke-BmoRuntimeDoctorAction }
    'workspace-sync' { Invoke-BmoWorkspaceSyncAction }
    'runtime-profile-dev' { Invoke-BmoRuntimeProfileActionImpl -ProfileName 'dev' }
    'runtime-profile-snappy' { Invoke-BmoRuntimeProfileActionImpl -ProfileName 'snappy' }
    'runtime-profile-robust' { Invoke-BmoRuntimeProfileActionImpl -ProfileName 'robust' }
    'site-caretaker' { Invoke-BmoSiteCaretakerAction }
    'worker-ready' { Invoke-BmoWorkerReadyAction }
    default { throw "Unknown desktop action id: $ActionId" }
  }

  exit ([int]$exitCode)
} catch {
  Write-BmoStatus -Level FAIL -Message $_.Exception.Message
  exit 1
}
