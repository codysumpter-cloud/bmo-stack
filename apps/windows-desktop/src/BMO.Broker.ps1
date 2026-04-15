Set-StrictMode -Version Latest

if (-not (Get-Variable -Name BmoProcessTasks -Scope Script -ErrorAction SilentlyContinue)) {
  $script:BmoProcessTasks = @{}
}

function Get-BmoAppRoot {
  return Split-Path -Parent $PSScriptRoot
}

function Get-BmoPropertyValue {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Object,
    [Parameter(Mandatory = $true)]
    [string]$Name,
    $Default = $null
  )

  if ($null -eq $Object) {
    return $Default
  }

  if ($Object -is [System.Collections.IDictionary]) {
    if ($Object.Contains($Name)) {
      return $Object[$Name]
    }
    return $Default
  }

  $property = $Object.PSObject.Properties[$Name]
  if ($null -eq $property) {
    return $Default
  }

  return $property.Value
}

function Test-BmoWritableDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  try {
    if (-not (Test-Path $Path)) {
      New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
    }

    $probe = Join-Path $Path ('.write-test-' + [guid]::NewGuid().ToString() + '.tmp')
    Set-Content -LiteralPath $probe -Value 'ok' -Encoding ASCII -ErrorAction Stop
    Remove-Item -LiteralPath $probe -Force -ErrorAction Stop
    return $true
  } catch {
    return $false
  }
}

function Get-BmoDataRoot {
  $preferred = Join-Path $env:LOCALAPPDATA 'BMO'
  $portable = Join-Path (Get-BmoAppRoot) 'data'
  $configured = $null
  $override = $env:BMO_DATA_ROOT
  $statePath = Join-Path (Get-BmoAppRoot) 'install-state.json'

  if (-not [string]::IsNullOrWhiteSpace($override)) {
    $configured = $override
  } elseif (Test-Path $statePath) {
    try {
      $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
      $stateDataRoot = Get-BmoPropertyValue -Object $state -Name 'dataRoot' -Default ''
      if (-not [string]::IsNullOrWhiteSpace($stateDataRoot)) {
        $configured = $stateDataRoot
      }
    } catch {
      $configured = $null
    }
  }

  $candidates = @()
  if (-not [string]::IsNullOrWhiteSpace($configured)) {
    $candidates += $configured
  }
  $candidates += $preferred
  $candidates += $portable

  foreach ($candidate in $candidates) {
    if (Test-BmoWritableDirectory -Path $candidate) {
      return $candidate
    }
  }

  throw 'Unable to create a writable BMO data directory.'
}

function Initialize-BmoDataDirs {
  $root = Get-BmoDataRoot
  $paths = @(
    $root,
    (Join-Path $root 'cache'),
    (Join-Path $root 'config'),
    (Join-Path $root 'logs'),
    (Join-Path $root 'logs\task-runs'),
    (Join-Path $root 'memory'),
    (Join-Path $root 'tasks'),
    (Join-Path $root 'workspaces')
  )

  foreach ($path in $paths) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
  }
}

function Get-BmoSettingsPath {
  return Join-Path (Get-BmoDataRoot) 'config\appsettings.json'
}

function Get-BmoSettingsTemplatePath {
  return Join-Path (Get-BmoAppRoot) 'config\appsettings.example.json'
}

function Merge-BmoSettingsDefaults {
  param([object]$Settings)

  $provider = [ordered]@{
    mode = 'offline'
    endpoint = ''
    apiKey = ''
    model = ''
  }

  $inputProvider = Get-BmoPropertyValue -Object $Settings -Name 'provider' -Default $null
  if ($null -ne $inputProvider) {
    $provider.mode = [string](Get-BmoPropertyValue -Object $inputProvider -Name 'mode' -Default $provider.mode)
    $provider.endpoint = [string](Get-BmoPropertyValue -Object $inputProvider -Name 'endpoint' -Default $provider.endpoint)
    $provider.apiKey = [string](Get-BmoPropertyValue -Object $inputProvider -Name 'apiKey' -Default $provider.apiKey)
    $provider.model = [string](Get-BmoPropertyValue -Object $inputProvider -Name 'model' -Default $provider.model)
  }

  $recent = Get-BmoPropertyValue -Object $Settings -Name 'recentWorkspaces' -Default @()
  if ($recent -isnot [System.Array]) {
    $recent = @($recent)
  }

  return [pscustomobject][ordered]@{
    appName = [string](Get-BmoPropertyValue -Object $Settings -Name 'appName' -Default 'BMO Windows Desktop')
    defaultWorkspace = [string](Get-BmoPropertyValue -Object $Settings -Name 'defaultWorkspace' -Default '')
    recentWorkspaces = @($recent | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    maxOutputCharacters = [int](Get-BmoPropertyValue -Object $Settings -Name 'maxOutputCharacters' -Default 12000)
    maxRecentWorkspaces = [int](Get-BmoPropertyValue -Object $Settings -Name 'maxRecentWorkspaces' -Default 8)
    preferredRuntimeProfile = [string](Get-BmoPropertyValue -Object $Settings -Name 'preferredRuntimeProfile' -Default 'dev')
    safeExecutionMode = [string](Get-BmoPropertyValue -Object $Settings -Name 'safeExecutionMode' -Default 'prompt')
    provider = [pscustomobject]$provider
  }
}

function Initialize-BmoSettings {
  Initialize-BmoDataDirs
  $settingsPath = Get-BmoSettingsPath
  $templatePath = Get-BmoSettingsTemplatePath

  if (-not (Test-Path $settingsPath)) {
    Copy-Item -LiteralPath $templatePath -Destination $settingsPath
  }

  $settings = Get-BmoSettings
  Save-BmoSettings -Settings $settings
  return $settings
}

function Get-BmoSettings {
  $settingsPath = Get-BmoSettingsPath
  if (-not (Test-Path $settingsPath)) {
    return Initialize-BmoSettings
  }

  $parsed = $null
  try {
    $parsed = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
  } catch {
    $parsed = $null
  }

  return (Merge-BmoSettingsDefaults -Settings $parsed)
}

function Save-BmoSettings {
  param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Settings
  )

  $settingsPath = Get-BmoSettingsPath
  $normalized = Merge-BmoSettingsDefaults -Settings $Settings
  $normalized | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
}

function Add-BmoRecentWorkspace {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $settings = Get-BmoSettings
  $recent = @($settings.recentWorkspaces | Where-Object { $_ -and $_ -ne $resolvedWorkspace })
  $recent = @($resolvedWorkspace) + $recent
  $settings.recentWorkspaces = @($recent | Select-Object -First $settings.maxRecentWorkspaces)
  if ([string]::IsNullOrWhiteSpace($settings.defaultWorkspace)) {
    $settings.defaultWorkspace = $resolvedWorkspace
  }
  Save-BmoSettings -Settings $settings
}

function Get-BmoPolicy {
  $policyPath = Join-Path (Get-BmoAppRoot) 'policies\capability-policy.example.json'
  return Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
}

function Get-BmoDesktopManifest {
  $manifestPath = Join-Path (Get-BmoAppRoot) 'config\workstation-manifest.json'
  if (-not (Test-Path $manifestPath)) {
    return [pscustomobject]@{
      version = 1
      documentShortcuts = @()
      validationActions = @()
      runtimeProfiles = @()
      skillActions = @()
    }
  }

  return Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
}

function Write-BmoLog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [string]$Category = 'app'
  )

  Initialize-BmoDataDirs
  $logPath = Join-Path (Get-BmoDataRoot) ('logs\' + (Get-Date -Format 'yyyy-MM-dd') + '.log')
  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Add-Content -LiteralPath $logPath -Value "[$timestamp][$Category] $Message"
}

function Get-BmoTaskDirectory {
  return Join-Path (Get-BmoDataRoot) 'tasks'
}

function Get-BmoTaskRuntimeDirectory {
  return Join-Path (Get-BmoDataRoot) 'logs\task-runs'
}

function Get-BmoTaskPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId
  )

  return Join-Path (Get-BmoTaskDirectory) ($TaskId + '.json')
}

function New-BmoTaskRecord {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Title,
    [Parameter(Mandatory = $true)]
    [string]$TaskType,
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [string]$InitiatedBy = 'operator',
    [string]$Command = '',
    [string]$PolicyDecision = 'allow',
    [string]$Capability = 'workspace.exec.safe',
    [string]$Notes = ''
  )

  return [pscustomobject][ordered]@{
    id = [guid]::NewGuid().ToString()
    title = $Title
    taskType = $TaskType
    initiatedBy = $InitiatedBy
    workspace = $WorkspacePath
    command = $Command
    status = 'queued'
    policyDecision = $PolicyDecision
    capability = $Capability
    notes = $Notes
    startedAt = $null
    completedAt = $null
    exitCode = $null
    stdoutPath = ''
    stderrPath = ''
    outputPreview = ''
    prompt = ''
    reply = ''
    sourceTaskId = ''
    pid = $null
  }
}

function Save-BmoTaskRecord {
  param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Task
  )

  Initialize-BmoDataDirs
  $path = Get-BmoTaskPath -TaskId $Task.id
  $Task | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $path -Encoding UTF8
}

function Get-BmoTaskRecord {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId
  )

  $path = Get-BmoTaskPath -TaskId $TaskId
  if (-not (Test-Path $path)) {
    return $null
  }

  return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

function Update-BmoTaskRecord {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    [Parameter(Mandatory = $true)]
    [hashtable]$Changes
  )

  $task = Get-BmoTaskRecord -TaskId $TaskId
  if ($null -eq $task) {
    throw "Unknown task id: $TaskId"
  }

  foreach ($key in $Changes.Keys) {
    $existing = $task.PSObject.Properties[$key]
    if ($null -eq $existing) {
      $task | Add-Member -NotePropertyName $key -NotePropertyValue $Changes[$key] -Force
    } else {
      $task.$key = $Changes[$key]
    }
  }

  Save-BmoTaskRecord -Task $task
  return $task
}

function Get-BmoTaskHistory {
  param(
    [int]$Limit = 200,
    [string]$WorkspacePath = ''
  )

  Initialize-BmoDataDirs
  $items = Get-ChildItem -LiteralPath (Get-BmoTaskDirectory) -Filter '*.json' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending

  $resolvedFilter = ''
  if (-not [string]::IsNullOrWhiteSpace($WorkspacePath) -and (Test-BmoWorkspace -WorkspacePath $WorkspacePath)) {
    $resolvedFilter = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  }

  $tasks = @()
  foreach ($item in $items) {
    if ($tasks.Count -ge $Limit) {
      break
    }

    try {
      $task = Get-Content -LiteralPath $item.FullName -Raw | ConvertFrom-Json
      if (-not [string]::IsNullOrWhiteSpace($resolvedFilter) -and $task.workspace -ne $resolvedFilter) {
        continue
      }
      $tasks += $task
    } catch {
    }
  }

  return $tasks
}

function Get-BmoLatestTaskRecord {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$TaskType,
    [Parameter(Mandatory = $true)]
    [string]$Title
  )

  return @(
    Get-BmoTaskHistory -WorkspacePath $WorkspacePath -Limit 200 |
      Where-Object { $_.taskType -eq $TaskType -and $_.title -eq $Title } |
      Select-Object -First 1
  )
}

function Get-BmoMaxOutputCharacters {
  $settings = Get-BmoSettings
  return [Math]::Max(1000, [int]$settings.maxOutputCharacters)
}

function Get-BmoTruncatedText {
  param(
    [string]$Text,
    [int]$MaxLength = 0
  )

  if ($null -eq $Text) {
    return ''
  }

  if ($MaxLength -le 0) {
    $MaxLength = Get-BmoMaxOutputCharacters
  }

  if ($Text.Length -le $MaxLength) {
    return $Text
  }

  return $Text.Substring(0, $MaxLength) + "`r`n`r`n[Truncated]"
}

function Get-BmoRelativePathFromRoot {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RootPath,
    [Parameter(Mandatory = $true)]
    [string]$TargetPath
  )

  $resolvedRoot = (Resolve-Path -LiteralPath $RootPath -ErrorAction Stop).Path
  $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath -ErrorAction Stop).Path

  $rootUri = New-Object System.Uri($resolvedRoot.TrimEnd('\') + '\')
  $targetUri = New-Object System.Uri($resolvedTarget)
  $relative = $rootUri.MakeRelativeUri($targetUri).ToString()
  return [System.Uri]::UnescapeDataString($relative).Replace('/', '\')
}

function Test-BmoWorkspace {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  return [System.IO.Directory]::Exists($WorkspacePath)
}

function Resolve-BmoWorkspacePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  if ([string]::IsNullOrWhiteSpace($WorkspacePath)) {
    throw 'Choose a workspace folder first.'
  }

  $resolved = Resolve-Path -LiteralPath $WorkspacePath -ErrorAction Stop
  return $resolved.Path
}

function Test-BmoPathWithinWorkspace {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$CandidatePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $workspacePrefix = $resolvedWorkspace.TrimEnd('\') + '\'
  $resolvedCandidate = (Resolve-Path -LiteralPath $CandidatePath -ErrorAction Stop).Path

  if ($resolvedCandidate.Equals($resolvedWorkspace, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $true
  }

  return $resolvedCandidate.StartsWith($workspacePrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-BmoWorkspaceItemPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $candidate = Join-Path $resolvedWorkspace $RelativePath
  $resolvedCandidate = Resolve-Path -LiteralPath $candidate -ErrorAction Stop
  $resolvedCandidatePath = $resolvedCandidate.Path

  if (-not (Test-BmoPathWithinWorkspace -WorkspacePath $resolvedWorkspace -CandidatePath $resolvedCandidatePath)) {
    throw 'Path is outside the workspace root.'
  }

  return $resolvedCandidatePath
}

function Get-BmoRelativePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$TargetPath
  )

  return Get-BmoRelativePathFromRoot -RootPath (Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath) -TargetPath $TargetPath
}

function Test-BmoTextFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
  try {
    $sampleLength = [Math]::Min($stream.Length, 4096)
    $buffer = New-Object byte[] $sampleLength
    [void]$stream.Read($buffer, 0, $sampleLength)
    foreach ($byte in $buffer) {
      if ($byte -eq 0) {
        return $false
      }
    }
    return $true
  } finally {
    $stream.Dispose()
  }
}

function Read-BmoWorkspaceFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath,
    [switch]$NoTruncate
  )

  $resolvedFilePath = Resolve-BmoWorkspaceItemPath -WorkspacePath $WorkspacePath -RelativePath $RelativePath
  $item = Get-Item -LiteralPath $resolvedFilePath -ErrorAction Stop
  if ($item.PSIsContainer) {
    throw 'Cannot read a directory. Choose a file instead.'
  }

  if (-not (Test-BmoTextFile -Path $resolvedFilePath)) {
    return "[Binary or unsupported file preview disabled] $RelativePath"
  }

  $content = Get-Content -LiteralPath $resolvedFilePath -Raw
  if ($NoTruncate) {
    return $content
  }

  return Get-BmoTruncatedText -Text $content
}

function Write-BmoWorkspaceFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath,
    [Parameter(Mandatory = $true)]
    [string]$Content
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $targetPath = Join-Path $resolvedWorkspace $RelativePath
  $parentPath = Split-Path -Parent $targetPath

  if (-not [string]::IsNullOrWhiteSpace($parentPath)) {
    if (-not (Test-Path $parentPath)) {
      New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }

    $resolvedParent = (Resolve-Path -LiteralPath $parentPath -ErrorAction Stop).Path
    if (-not (Test-BmoPathWithinWorkspace -WorkspacePath $resolvedWorkspace -CandidatePath $resolvedParent)) {
      throw 'Write blocked: parent path is outside the workspace root.'
    }
  }

  Set-Content -LiteralPath $targetPath -Value $Content -Encoding UTF8
  $resolvedTargetPath = (Resolve-Path -LiteralPath $targetPath -ErrorAction Stop).Path
  if (-not (Test-BmoPathWithinWorkspace -WorkspacePath $resolvedWorkspace -CandidatePath $resolvedTargetPath)) {
    throw 'Write blocked: target path escaped the workspace root.'
  }

  Write-BmoLog -Category 'workspace-write' -Message ("workspace={0} file={1}" -f $resolvedWorkspace, $RelativePath)
  return $resolvedTargetPath
}

function New-BmoWorkspaceDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $targetPath = Join-Path $resolvedWorkspace $RelativePath
  if (Test-Path -LiteralPath $targetPath) {
    throw "Path already exists: $RelativePath"
  }

  $parentPath = Split-Path -Parent $targetPath
  if (-not [string]::IsNullOrWhiteSpace($parentPath)) {
    if (-not (Test-Path -LiteralPath $parentPath)) {
      New-Item -ItemType Directory -Path $parentPath -Force | Out-Null
    }

    $resolvedParent = (Resolve-Path -LiteralPath $parentPath -ErrorAction Stop).Path
    if (-not (Test-BmoPathWithinWorkspace -WorkspacePath $resolvedWorkspace -CandidatePath $resolvedParent)) {
      throw 'Create blocked: parent path is outside the workspace root.'
    }
  }

  New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
  $resolvedTarget = (Resolve-Path -LiteralPath $targetPath -ErrorAction Stop).Path
  if (-not (Test-BmoPathWithinWorkspace -WorkspacePath $resolvedWorkspace -CandidatePath $resolvedTarget)) {
    throw 'Create blocked: target path escaped the workspace root.'
  }

  Write-BmoLog -Category 'workspace-mkdir' -Message ("workspace={0} path={1}" -f $resolvedWorkspace, $RelativePath)
  return $resolvedTarget
}

function New-BmoWorkspaceFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath,
    [string]$Content = ''
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $targetPath = Join-Path $resolvedWorkspace $RelativePath
  if (Test-Path -LiteralPath $targetPath) {
    throw "Path already exists: $RelativePath"
  }

  [void](Write-BmoWorkspaceFile -WorkspacePath $resolvedWorkspace -RelativePath $RelativePath -Content $Content)
  return (Resolve-Path -LiteralPath $targetPath -ErrorAction Stop).Path
}

function Get-BmoSafeCommands {
  $policy = Get-BmoPolicy
  return [pscustomobject]@{
    exact = @($policy.safeCommandExact)
    prefixes = @($policy.safeCommandPrefixes)
    blockedTokens = @($policy.blockedCommandTokens)
  }
}

function Get-BmoExactSafeCommands {
  return @((Get-BmoSafeCommands).exact)
}

function Get-BmoSafeCommandPrefixes {
  return @((Get-BmoSafeCommands).prefixes)
}

function Get-BmoBlockedTokens {
  return @((Get-BmoSafeCommands).blockedTokens)
}

function Get-BmoToolStatus {
  $names = @('git', 'node', 'python', 'python3', 'py', 'bash', 'make', 'pwsh', 'powershell', 'rg', 'openclaw', 'openshell', 'ollama')
  $result = @()

  foreach ($name in $names) {
    $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
    $result += [pscustomobject]@{
      name = $name
      available = ($null -ne $command)
      path = if ($null -ne $command) { $command.Source } else { '' }
    }
  }

  return $result
}

function ConvertTo-BmoPowerShellLiteral {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  return "'" + $Text.Replace("'", "''") + "'"
}

function Get-BmoPrimaryCommandToken {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandText
  )

  $match = [regex]::Match($CommandText.Trim(), '^(?:"([^"]+)"|''([^'']+)''|(\S+))')
  if (-not $match.Success) {
    return ''
  }

  foreach ($index in @(1, 2, 3)) {
    $value = $match.Groups[$index].Value
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      return $value
    }
  }

  return ''
}

function Get-BmoDesktopActionCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ActionId
  )

  $scriptPath = '.\apps\windows-desktop\scripts\Invoke-BmoDesktopAction.ps1'
  return "powershell -NoProfile -ExecutionPolicy Bypass -File $(ConvertTo-BmoPowerShellLiteral -Text $scriptPath) -ActionId $(ConvertTo-BmoPowerShellLiteral -Text $ActionId)"
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

function Get-BmoPythonCommand {
  $py = Get-Command py -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -ne $py -and (Test-BmoCommandInvocation -FilePath $py.Source -ArgumentList @('-3', '--version'))) {
    return [pscustomobject]@{
      available = $true
      filePath = $py.Source
      commandName = 'py'
      arguments = @('-3')
    }
  }

  $python = Get-Command python -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -ne $python -and (Test-BmoCommandInvocation -FilePath $python.Source -ArgumentList @('--version'))) {
    return [pscustomobject]@{
      available = $true
      filePath = $python.Source
      commandName = 'python'
      arguments = @()
    }
  }

  $python3 = Get-Command python3 -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -ne $python3 -and (Test-BmoCommandInvocation -FilePath $python3.Source -ArgumentList @('--version'))) {
    return [pscustomobject]@{
      available = $true
      filePath = $python3.Source
      commandName = 'python3'
      arguments = @()
    }
  }

  return [pscustomobject]@{
    available = $false
    filePath = ''
    commandName = ''
    arguments = @()
  }
}

function Get-BmoManagedActionId {
  param(
    [string]$CommandText = '',
    [string]$HintId = ''
  )

  $knownActionIds = @(
    'doctor-plus',
    'worker-status',
    'runtime-doctor',
    'workspace-sync',
    'runtime-profile-dev',
    'runtime-profile-snappy',
    'runtime-profile-robust',
    'site-caretaker',
    'worker-ready'
  )
  $hintAliases = @{
    'bootstrap-recovery' = 'doctor-plus'
    'context-sync' = 'workspace-sync'
    'openclaw-agent-split' = 'worker-status'
  }

  if (-not [string]::IsNullOrWhiteSpace($HintId)) {
    if ($HintId -in $knownActionIds) {
      return $HintId
    }
    if ($hintAliases.ContainsKey($HintId)) {
      return [string]$hintAliases[$HintId]
    }
  }

  $normalized = $CommandText.Trim().ToLowerInvariant()
  switch ($normalized) {
    'make doctor-plus' { return 'doctor-plus' }
    'make worker-status' { return 'worker-status' }
    'scripts/bmo-worker-status' { return 'worker-status' }
    'bash ./scripts/bmo-worker-status' { return 'worker-status' }
    'bash scripts/bmo-worker-status' { return 'worker-status' }
    'make runtime-doctor' { return 'runtime-doctor' }
    'bash ./scripts/bmo-runtime-doctor.sh' { return 'runtime-doctor' }
    'bash scripts/bmo-runtime-doctor.sh' { return 'runtime-doctor' }
    'make workspace-sync' { return 'workspace-sync' }
    'python ./scripts/bmo-workspace-sync.py' { return 'workspace-sync' }
    'python3 ./scripts/bmo-workspace-sync.py' { return 'workspace-sync' }
    'make runtime-profile-dev' { return 'runtime-profile-dev' }
    'make runtime-profile-snappy' { return 'runtime-profile-snappy' }
    'make runtime-profile-robust' { return 'runtime-profile-robust' }
    'make site-caretaker' { return 'site-caretaker' }
    'node ./scripts/bmo-site-caretaker.mjs' { return 'site-caretaker' }
    'make worker-ready' { return 'worker-ready' }
    default { return '' }
  }
}

function Get-BmoDesktopActionReadiness {
  param(
    [Parameter(Mandatory = $true)]
    [string]$ActionId
  )

  $scriptPath = Join-Path (Get-BmoAppRoot) 'scripts\Invoke-BmoDesktopAction.ps1'
  if (-not (Test-Path -LiteralPath $scriptPath)) {
    return [pscustomobject]@{
      ready = $false
      status = 'blocked'
      reason = "Desktop action script is missing: $scriptPath"
    }
  }

  $powershellCommand = Get-Command powershell -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -eq $powershellCommand) {
    return [pscustomobject]@{
      ready = $false
      status = 'blocked'
      reason = 'Windows PowerShell is not available in PATH.'
    }
  }

  switch ($ActionId) {
    'workspace-sync' {
      $python = Get-BmoPythonCommand
      if (-not $python.available) {
        return [pscustomobject]@{
          ready = $false
          status = 'blocked'
          reason = 'Workspace sync needs Python, but no supported Python launcher was found.'
        }
      }
    }
    'runtime-profile-dev' { }
    'runtime-profile-snappy' { }
    'runtime-profile-robust' { }
    'site-caretaker' {
      $node = Get-Command node -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($null -eq $node) {
        return [pscustomobject]@{
          ready = $false
          status = 'blocked'
          reason = 'Site caretaker needs Node.js in PATH.'
        }
      }
    }
    'worker-ready' {
      $openshell = Get-Command openshell -ErrorAction SilentlyContinue | Select-Object -First 1
      $configPath = Join-Path $HOME '.openclaw\openclaw.json'
      if ($null -eq $openshell) {
        return [pscustomobject]@{
          ready = $false
          status = 'blocked'
          reason = 'Worker-ready needs openshell in PATH.'
        }
      }
      if (-not (Test-Path -LiteralPath $configPath)) {
        return [pscustomobject]@{
          ready = $false
          status = 'blocked'
          reason = "Worker-ready needs an OpenClaw config at $configPath"
        }
      }
    }
  }

  if ($ActionId -like 'runtime-profile-*') {
    $python = Get-BmoPythonCommand
    if (-not $python.available) {
      return [pscustomobject]@{
        ready = $false
        status = 'blocked'
        reason = 'Runtime profile actions need Python, but no supported Python launcher was found.'
      }
    }
  }

  $diagnosticActions = @('doctor-plus', 'worker-status', 'runtime-doctor')
  if ($ActionId -in $diagnosticActions) {
    return [pscustomobject]@{
      ready = $true
      status = 'diagnostic'
      reason = 'Diagnostic action can run even when tools are missing; it will report blockers in task output.'
    }
  }

  return [pscustomobject]@{
    ready = $true
    status = 'ready'
    reason = 'Action is ready to run on this workstation.'
  }
}

function Get-BmoCommandReadiness {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandText,
    [string]$WorkspacePath = ''
  )

  $token = Get-BmoPrimaryCommandToken -CommandText $CommandText
  if ([string]::IsNullOrWhiteSpace($token)) {
    return [pscustomobject]@{
      ready = $false
      status = 'blocked'
      token = ''
      reason = 'No executable token was found in the command.'
    }
  }

  $lower = $token.ToLowerInvariant()
  $command = $null
  switch ($lower) {
    { $_ -in @('powershell', 'powershell.exe', 'pwsh', 'pwsh.exe', 'node', 'node.exe', 'python', 'python.exe', 'python3', 'python3.exe', 'py', 'py.exe', 'git', 'git.exe', 'bash', 'bash.exe', 'make', 'make.exe', 'rg', 'rg.exe') } {
      $command = Get-Command $token -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($null -eq $command) {
        return [pscustomobject]@{
          ready = $false
          status = 'blocked'
          token = $token
          reason = "Executable not found in PATH: $token"
        }
      }

      return [pscustomobject]@{
        ready = $true
        status = 'ready'
        token = $token
        reason = "Executable found: $($command.Source)"
      }
    }
  }

  if ($token.Contains('\') -or $token.Contains('/')) {
    $candidate = $token
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
      $basePath = if (-not [string]::IsNullOrWhiteSpace($WorkspacePath)) {
        Get-BmoWorkspaceBasePath -WorkspacePath $WorkspacePath
      } else {
        (Resolve-Path '.').Path
      }
      $candidate = Join-Path $basePath $candidate
    }

    if (Test-Path -LiteralPath $candidate) {
      return [pscustomobject]@{
        ready = $true
        status = 'ready'
        token = $token
        reason = "Path found: $candidate"
      }
    }

    return [pscustomobject]@{
      ready = $false
      status = 'blocked'
      token = $token
      reason = "Path not found: $candidate"
    }
  }

  $command = Get-Command $token -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($null -eq $command) {
    return [pscustomobject]@{
      ready = $false
      status = 'blocked'
      token = $token
      reason = "Command not found: $token"
    }
  }

  return [pscustomobject]@{
    ready = $true
    status = 'ready'
    token = $token
    reason = "Command found: $($command.Source)"
  }
}

function Resolve-BmoManagedCommand {
  param(
    [string]$CommandText = '',
    [string]$ActionId = '',
    [string]$WorkspacePath = ''
  )

  $rawCommand = $CommandText.Trim()
  $managedActionId = Get-BmoManagedActionId -CommandText $rawCommand -HintId $ActionId
  $effectiveCommand = $rawCommand
  $executionNote = ''

  if (-not [string]::IsNullOrWhiteSpace($managedActionId)) {
    $effectiveCommand = Get-BmoDesktopActionCommand -ActionId $managedActionId
    $executionNote = 'Windows desktop dispatcher will run the repo action with native tooling and explicit logs.'
    $readiness = Get-BmoDesktopActionReadiness -ActionId $managedActionId
  } elseif (-not [string]::IsNullOrWhiteSpace($rawCommand)) {
    $readiness = Get-BmoCommandReadiness -CommandText $rawCommand -WorkspacePath $WorkspacePath
  } else {
    $readiness = [pscustomobject]@{
      ready = $false
      status = 'none'
      token = ''
      reason = 'No command is registered for this action.'
    }
  }

  return [pscustomobject]@{
    rawCommand = $rawCommand
    effectiveCommand = $effectiveCommand
    managedActionId = $managedActionId
    isManaged = (-not [string]::IsNullOrWhiteSpace($managedActionId))
    executionNote = $executionNote
    readiness = $readiness
  }
}

function Get-BmoCommandClassification {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandText
  )

  $normalized = $CommandText.Trim()
  if ([string]::IsNullOrWhiteSpace($normalized)) {
    throw 'Enter a command first.'
  }

  $lower = $normalized.ToLowerInvariant()
  $settings = Get-BmoSettings
  $unknownMode = $settings.safeExecutionMode.ToLowerInvariant()

  foreach ($token in Get-BmoBlockedTokens) {
    if ($lower.Contains($token.ToLowerInvariant())) {
      return [pscustomobject]@{
        command = $normalized
        decision = 'deny'
        capability = 'policy.blocked'
        riskLevel = 'high'
        safe = $false
        requiresApproval = $false
        reason = "Blocked token matched: $token"
      }
    }
  }

  foreach ($candidate in Get-BmoExactSafeCommands) {
    if ($lower -eq $candidate.ToLowerInvariant()) {
      return [pscustomobject]@{
        command = $normalized
        decision = 'allow'
        capability = 'workspace.exec.safe'
        riskLevel = 'low'
        safe = $true
        requiresApproval = $false
        reason = 'Command matched the safe exact allowlist.'
      }
    }
  }

  foreach ($prefix in Get-BmoSafeCommandPrefixes) {
    if ($lower.StartsWith($prefix.ToLowerInvariant())) {
      return [pscustomobject]@{
        command = $normalized
        decision = 'allow'
        capability = 'workspace.exec.safe'
        riskLevel = 'low'
        safe = $true
        requiresApproval = $false
        reason = 'Command matched the safe prefix allowlist.'
      }
    }
  }

  $networkPrefixes = @('git fetch', 'git pull', 'git clone', 'npm ', 'pnpm ', 'yarn ', 'pip ', 'pip3 ')
  foreach ($prefix in $networkPrefixes) {
    if ($lower.StartsWith($prefix)) {
      return [pscustomobject]@{
        command = $normalized
        decision = 'prompt'
        capability = 'workspace.exec.network'
        riskLevel = 'high'
        safe = $false
        requiresApproval = $true
        reason = 'Network-capable command requires explicit approval.'
      }
    }
  }

  $gitMutators = @(
    'git add', 'git commit', 'git checkout', 'git switch', 'git merge',
    'git rebase', 'git stash', 'git cherry-pick', 'git reset', 'git revert',
    'git rm', 'git push', 'git tag ', 'git branch -d', 'git branch -m'
  )
  foreach ($prefix in $gitMutators) {
    if ($lower.StartsWith($prefix)) {
      return [pscustomobject]@{
        command = $normalized
        decision = 'prompt'
        capability = 'git.mutate'
        riskLevel = 'medium'
        safe = $false
        requiresApproval = $true
        reason = 'Git mutation requires explicit approval.'
      }
    }
  }

  $reviewPrefixes = @('make ', 'bash ', 'node ', 'python ', 'python3 ', 'pwsh ', 'powershell ', '.\scripts\', './scripts/')
  foreach ($prefix in $reviewPrefixes) {
    if ($lower.StartsWith($prefix)) {
      return [pscustomobject]@{
        command = $normalized
        decision = 'prompt'
        capability = 'workspace.exec.review'
        riskLevel = 'medium'
        safe = $false
        requiresApproval = $true
        reason = 'Scripted or composite command requires operator review.'
      }
    }
  }

  if ($unknownMode -eq 'deny' -or $unknownMode -eq 'deny-unknown') {
    return [pscustomobject]@{
      command = $normalized
      decision = 'deny'
      capability = 'workspace.exec.unknown'
      riskLevel = 'medium'
      safe = $false
      requiresApproval = $false
      reason = 'Unknown commands are denied by the current safe execution mode.'
    }
  }

  return [pscustomobject]@{
    command = $normalized
    decision = 'prompt'
    capability = 'workspace.exec.review'
    riskLevel = 'medium'
    safe = $false
    requiresApproval = $true
    reason = 'Unknown command requires explicit approval.'
  }
}

function Test-BmoSafeCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandText
  )

  return (Get-BmoCommandClassification -CommandText $CommandText).safe
}

function Get-BmoPolicySummary {
  $safe = Get-BmoSafeCommands
  $policy = Get-BmoPolicy
  $settings = Get-BmoSettings

  return [pscustomobject]@{
    defaultMode = $policy.defaultMode
    safeExecutionMode = $settings.safeExecutionMode
    exactSafeCommands = @($safe.exact)
    safePrefixes = @($safe.prefixes)
    blockedTokens = @($safe.blockedTokens)
  }
}

function Get-BmoRepoRoot {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath

  try {
    $repoRoot = (& git -C $resolvedWorkspace rev-parse --show-toplevel 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
      return $null
    }
    return $repoRoot
  } catch {
    return $null
  }
}

function Get-BmoWorkspaceBasePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $repoRoot = Get-BmoRepoRoot -WorkspacePath $WorkspacePath
  if (-not [string]::IsNullOrWhiteSpace($repoRoot)) {
    return $repoRoot
  }

  return Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
}

function Get-BmoRepoChanges {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $repoRoot = Get-BmoRepoRoot -WorkspacePath $resolvedWorkspace
  if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    return @()
  }

  $lines = & git -C $resolvedWorkspace status --porcelain=v1 -uall 2>$null
  $changes = @()

  foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('##')) {
      continue
    }

    $indexStatus = $line.Substring(0, 1)
    $worktreeStatus = $line.Substring(1, 1)
    $pathText = $line.Substring(3).Trim()
    $originalPath = ''

    if ($pathText.Contains(' -> ')) {
      $parts = $pathText -split ' -> '
      if ($parts.Count -ge 2) {
        $originalPath = $parts[0]
        $pathText = $parts[-1]
      }
    }

    $isUntracked = ($indexStatus -eq '?' -and $worktreeStatus -eq '?')
    $summaryParts = @()
    if ($indexStatus -ne ' ' -and $indexStatus -ne '?') { $summaryParts += "staged:$indexStatus" }
    if ($worktreeStatus -ne ' ' -and $worktreeStatus -ne '?') { $summaryParts += "worktree:$worktreeStatus" }
    if ($isUntracked) { $summaryParts += 'untracked' }
    if (-not [string]::IsNullOrWhiteSpace($originalPath)) { $summaryParts += "from:$originalPath" }

    $changes += [pscustomobject]@{
      path = $pathText
      originalPath = $originalPath
      stagedStatus = if ($indexStatus -ne ' ' -and $indexStatus -ne '?') { $indexStatus } else { '' }
      worktreeStatus = if ($worktreeStatus -ne ' ' -and $worktreeStatus -ne '?') { $worktreeStatus } else { '' }
      isUntracked = $isUntracked
      summary = ($summaryParts -join ', ')
    }
  }

  return @($changes)
}

function Get-BmoWorktrees {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $repoRoot = Get-BmoRepoRoot -WorkspacePath $WorkspacePath
  if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    return @()
  }

  $lines = & git -C $repoRoot worktree list --porcelain 2>$null
  if ($LASTEXITCODE -ne 0) {
    return @()
  }

  $worktrees = @()
  $current = @{}

  foreach ($line in @($lines + '')) {
    if ([string]::IsNullOrWhiteSpace($line)) {
      if ($current.ContainsKey('path')) {
        $pathValue = [string]$current['path']
        $normalizedPath = $pathValue.Replace('/', '\')
        $currentWorkspace = (Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath).Replace('/', '\')
        $worktrees += [pscustomobject]@{
          path = $pathValue
          branch = if ($current.ContainsKey('branch')) { [string]$current['branch'] } else { '' }
          head = if ($current.ContainsKey('head')) { [string]$current['head'] } else { '' }
          isCurrent = $normalizedPath.Equals($currentWorkspace, [System.StringComparison]::OrdinalIgnoreCase)
          locked = if ($current.ContainsKey('locked')) { [bool]$current['locked'] } else { $false }
        }
      }
      $current = @{}
      continue
    }

    if ($line.StartsWith('worktree ')) {
      $current['path'] = $line.Substring(9)
    } elseif ($line.StartsWith('HEAD ')) {
      $current['head'] = $line.Substring(5)
    } elseif ($line.StartsWith('branch ')) {
      $branchValue = $line.Substring(7)
      $branchValue = $branchValue.Replace('refs/heads/', '')
      $current['branch'] = $branchValue
    } elseif ($line -eq 'detached') {
      $current['branch'] = '(detached)'
    } elseif ($line.StartsWith('locked')) {
      $current['locked'] = $true
    }
  }

  return @($worktrees)
}

function Get-BmoRepoInfo {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $repoRoot = Get-BmoRepoRoot -WorkspacePath $resolvedWorkspace

  $result = [ordered]@{
    workspace = $resolvedWorkspace
    isGitRepo = $false
    repoRoot = ''
    branch = ''
    remoteBranch = ''
    ahead = 0
    behind = 0
    dirty = $false
    stagedCount = 0
    unstagedCount = 0
    untrackedCount = 0
    statusHeader = ''
    statusText = ''
    changedFiles = @()
    worktrees = @()
  }

  if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    return [pscustomobject]$result
  }

  $statusText = (& git -C $resolvedWorkspace status --short --branch 2>$null | Out-String).Trim()
  $statusHeader = ''
  if (-not [string]::IsNullOrWhiteSpace($statusText)) {
    $statusLines = $statusText -split "`r?`n"
    if ($statusLines.Count -gt 0) {
      $statusHeader = $statusLines[0].Replace('## ', '').Trim()
    }
  }

  $branch = $statusHeader
  $remoteBranch = ''
  $ahead = 0
  $behind = 0
  if ($statusHeader -match '^(?<branch>.+?)(\.\.\.(?<remote>[^\[]+))?( \[(?<tracking>[^\]]+)\])?$') {
    $branch = $Matches['branch'].Trim()
    $remoteBranch = $Matches['remote']
    $tracking = $Matches['tracking']
    if ($tracking -match 'ahead (?<ahead>\d+)') {
      $ahead = [int]$Matches['ahead']
    }
    if ($tracking -match 'behind (?<behind>\d+)') {
      $behind = [int]$Matches['behind']
    }
  }

  $changes = @(Get-BmoRepoChanges -WorkspacePath $resolvedWorkspace)
  $stagedCount = (@($changes | Where-Object { -not [string]::IsNullOrWhiteSpace($_.stagedStatus) })).Count
  $unstagedCount = (@($changes | Where-Object { -not [string]::IsNullOrWhiteSpace($_.worktreeStatus) })).Count
  $untrackedCount = (@($changes | Where-Object { $_.isUntracked })).Count

  $result.isGitRepo = $true
  $result.repoRoot = $repoRoot
  $result.branch = $branch
  $result.remoteBranch = $remoteBranch
  $result.ahead = $ahead
  $result.behind = $behind
  $result.changedFiles = @($changes)
  $result.stagedCount = $stagedCount
  $result.unstagedCount = $unstagedCount
  $result.untrackedCount = $untrackedCount
  $result.dirty = (@($changes).Count -gt 0)
  $result.statusHeader = $statusHeader
  $result.statusText = $statusText
  $result.worktrees = @(Get-BmoWorktrees -WorkspacePath $resolvedWorkspace)

  return [pscustomobject]$result
}

function Get-BmoRepoSummary {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $items = Get-ChildItem -LiteralPath $resolvedWorkspace -Force | Select-Object -First 20
  $names = $items | ForEach-Object { $_.Name }
  $repoInfo = Get-BmoRepoInfo -WorkspacePath $resolvedWorkspace

  return [pscustomobject]@{
    workspace = $resolvedWorkspace
    topLevelItems = $names
    gitStatus = $repoInfo.statusText
    branch = $repoInfo.branch
    dirty = $repoInfo.dirty
    changedCount = $repoInfo.changedFiles.Count
  }
}

function Get-BmoRepoDiff {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath,
    [ValidateSet('worktree', 'staged')]
    [string]$Mode = 'worktree'
  )

  $repoRoot = Get-BmoRepoRoot -WorkspacePath $WorkspacePath
  if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    return 'Git diff unavailable: workspace is not a git repo.'
  }

  $args = @('-C', $repoRoot, 'diff')
  if ($Mode -eq 'staged') {
    $args += '--cached'
  }
  $args += '--no-ext-diff'
  $args += '--'
  $args += $RelativePath

  $diff = (& git @args 2>&1 | Out-String).Trim()
  if ([string]::IsNullOrWhiteSpace($diff)) {
    if ($Mode -eq 'staged') {
      return '[No staged diff output for this file.]'
    }
    return '[No worktree diff output for this file. It may be untracked or already staged.]'
  }

  return Get-BmoTruncatedText -Text $diff
}

function Get-BmoDocumentShortcuts {
  return @((Get-BmoDesktopManifest).documentShortcuts)
}

function Get-BmoDocumentContent {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $basePath = Get-BmoWorkspaceBasePath -WorkspacePath $WorkspacePath
  $targetPath = Join-Path $basePath $RelativePath
  if (-not (Test-Path $targetPath)) {
    return "Document not found in workspace: $RelativePath"
  }

  return Get-BmoTruncatedText -Text (Get-Content -LiteralPath $targetPath -Raw)
}

function Get-BmoRoutinePack {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $basePath = Get-BmoWorkspaceBasePath -WorkspacePath $WorkspacePath
  $path = Join-Path $basePath 'config\routines\bmo-core-routines.json'
  if (-not (Test-Path $path)) {
    return [pscustomobject]@{
      version = 1
      pack_name = ''
      description = ''
      routines = @()
    }
  }

  return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

function Get-BmoRoutineCatalog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $catalog = @()
  foreach ($routine in @((Get-BmoRoutinePack -WorkspacePath $WorkspacePath).routines)) {
    $resolution = Resolve-BmoManagedCommand -CommandText ([string]$routine.command) -ActionId ([string]$routine.name) -WorkspacePath $WorkspacePath
    $latest = @(Get-BmoLatestTaskRecord -WorkspacePath $WorkspacePath -TaskType 'routine' -Title ([string]$routine.name))
    $lastTask = if ($latest.Count -gt 0) { $latest[0] } else { $null }
    $catalog += [pscustomobject]@{
      name = [string]$routine.name
      owner_surface = [string]$routine.owner_surface
      purpose = [string]$routine.purpose
      related_files = @($routine.related_files)
      rawCommand = [string]$routine.command
      command = [string]$resolution.effectiveCommand
      managedActionId = [string]$resolution.managedActionId
      executionNote = [string]$resolution.executionNote
      ready = [bool]$resolution.readiness.ready
      readiness = [string]$resolution.readiness.status
      readinessReason = [string]$resolution.readiness.reason
      lastStatus = if ($null -ne $lastTask) { [string]$lastTask.status } else { 'never' }
      lastStartedAt = if ($null -ne $lastTask) { [string]$lastTask.startedAt } else { '' }
    }
  }

  return $catalog
}

function Get-BmoValidationActions {
  return @((Get-BmoDesktopManifest).validationActions)
}

function Get-BmoValidationCatalog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $catalog = @()
  foreach ($action in Get-BmoValidationActions) {
    $actionId = [string](Get-BmoPropertyValue -Object $action -Name 'id' -Default '')
    $actionName = [string](Get-BmoPropertyValue -Object $action -Name 'name' -Default $actionId)
    $resolution = Resolve-BmoManagedCommand -CommandText ([string]$action.command) -ActionId $actionId -WorkspacePath $WorkspacePath
    $latest = @(Get-BmoLatestTaskRecord -WorkspacePath $WorkspacePath -TaskType 'validation' -Title $actionName)
    $lastTask = if ($latest.Count -gt 0) { $latest[0] } else { $null }
    $catalog += [pscustomobject]@{
      id = $actionId
      name = $actionName
      description = [string](Get-BmoPropertyValue -Object $action -Name 'description' -Default '')
      rawCommand = [string](Get-BmoPropertyValue -Object $action -Name 'command' -Default '')
      command = [string]$resolution.effectiveCommand
      managedActionId = [string]$resolution.managedActionId
      executionNote = [string]$resolution.executionNote
      ready = [bool]$resolution.readiness.ready
      readiness = [string]$resolution.readiness.status
      readinessReason = [string]$resolution.readiness.reason
      lastStatus = if ($null -ne $lastTask) { [string]$lastTask.status } else { 'never' }
      lastStartedAt = if ($null -ne $lastTask) { [string]$lastTask.startedAt } else { '' }
    }
  }

  return $catalog
}

function Get-BmoRuntimeProfiles {
  return @((Get-BmoDesktopManifest).runtimeProfiles)
}

function Get-BmoRuntimeProfileCatalog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $catalog = @()
  foreach ($profile in Get-BmoRuntimeProfiles) {
    $profileId = [string](Get-BmoPropertyValue -Object $profile -Name 'id' -Default '')
    $profileName = [string](Get-BmoPropertyValue -Object $profile -Name 'name' -Default $profileId)
    $resolution = Resolve-BmoManagedCommand -CommandText ([string]$profile.command) -ActionId $profileId -WorkspacePath $WorkspacePath
    $latest = @(Get-BmoLatestTaskRecord -WorkspacePath $WorkspacePath -TaskType 'runtime-profile' -Title $profileName)
    $lastTask = if ($latest.Count -gt 0) { $latest[0] } else { $null }
    $catalog += [pscustomobject]@{
      id = $profileId
      name = $profileName
      description = [string](Get-BmoPropertyValue -Object $profile -Name 'description' -Default '')
      rawCommand = [string](Get-BmoPropertyValue -Object $profile -Name 'command' -Default '')
      command = [string]$resolution.effectiveCommand
      managedActionId = [string]$resolution.managedActionId
      executionNote = [string]$resolution.executionNote
      ready = [bool]$resolution.readiness.ready
      readiness = [string]$resolution.readiness.status
      readinessReason = [string]$resolution.readiness.reason
      lastStatus = if ($null -ne $lastTask) { [string]$lastTask.status } else { 'never' }
      lastStartedAt = if ($null -ne $lastTask) { [string]$lastTask.startedAt } else { '' }
    }
  }

  return $catalog
}

function Get-BmoSkillCatalog {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $basePath = Get-BmoWorkspaceBasePath -WorkspacePath $WorkspacePath
  $skillsDir = Join-Path $basePath 'skills'
  if (-not (Test-Path $skillsDir)) {
    return @()
  }

  $baselinePath = Join-Path $basePath 'config\skills\bmo-baseline-pack.json'
  $indexPath = Join-Path $skillsDir 'index.json'
  $manifest = Get-BmoDesktopManifest

  $baselineMap = @{}
  if (Test-Path $baselinePath) {
    try {
      $baseline = Get-Content -LiteralPath $baselinePath -Raw | ConvertFrom-Json
      foreach ($item in @($baseline.local_routines)) {
        $baselineMap[$item.name] = $item
      }
    } catch {
    }
  }

  $indexObject = $null
  if (Test-Path $indexPath) {
    try {
      $indexObject = Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json
    } catch {
      $indexObject = $null
    }
  }

  $skillActionMap = @{}
  foreach ($entry in @($manifest.skillActions)) {
    $skillActionMap[$entry.skillId] = $entry
  }

  $catalog = @()
  $directories = Get-ChildItem -LiteralPath $skillsDir -Directory | Sort-Object Name
  foreach ($directory in $directories) {
    $skillId = $directory.Name
    $readmePath = Join-Path $directory.FullName 'README.md'
    $relativeReadmePath = ''
    if (Test-Path $readmePath) {
      $relativeReadmePath = Get-BmoRelativePathFromRoot -RootPath $basePath -TargetPath $readmePath
    }

    $description = ''
    if ($baselineMap.ContainsKey($skillId)) {
      $description = [string]$baselineMap[$skillId].why
    }

    $skillAction = $null
    if ($skillActionMap.ContainsKey($skillId)) {
      $skillAction = $skillActionMap[$skillId]
      if ([string]::IsNullOrWhiteSpace($description)) {
        $description = [string]$skillAction.description
      }
    }

    $indexEntry = $null
    if ($null -ne $indexObject) {
      $skillsProperty = $indexObject.PSObject.Properties['skills']
      if ($null -ne $skillsProperty) {
        $indexEntry = Get-BmoPropertyValue -Object $skillsProperty.Value -Name $skillId -Default $null
      }
    }

    $triggers = @()
    $defaultAction = ''
    if ($null -ne $indexEntry) {
      $triggers = @((Get-BmoPropertyValue -Object $indexEntry -Name 'triggers' -Default @()))
      $defaultAction = [string](Get-BmoPropertyValue -Object $indexEntry -Name 'default_action' -Default '')
      if ([string]::IsNullOrWhiteSpace($description) -and $triggers.Count -gt 0) {
        $description = 'Triggers: ' + ($triggers -join ', ')
      }
    }

    if ([string]::IsNullOrWhiteSpace($description) -and (Test-Path $readmePath)) {
      $lines = Get-Content -LiteralPath $readmePath
      $bodyLines = $lines | Where-Object {
        $trimmed = $_.Trim()
        $trimmed.Length -gt 0 -and -not $trimmed.StartsWith('#')
      }
      if ($bodyLines.Count -gt 0) {
        $description = ($bodyLines | Select-Object -First 2) -join ' '
      }
    }

    $rawRecommendedCommand = if ($null -ne $skillAction) { [string](Get-BmoPropertyValue -Object $skillAction -Name 'command' -Default '') } else { '' }
    $resolution = Resolve-BmoManagedCommand -CommandText $rawRecommendedCommand -ActionId $skillId -WorkspacePath $WorkspacePath

    $catalog += [pscustomobject]@{
      id = $skillId
      name = $skillId
      description = $description
      defaultAction = $defaultAction
      triggers = $triggers
      rawRecommendedCommand = $rawRecommendedCommand
      recommendedCommand = [string]$resolution.effectiveCommand
      commandReady = [bool]$resolution.readiness.ready
      commandReadiness = [string]$resolution.readiness.status
      commandReadinessReason = [string]$resolution.readiness.reason
      executionNote = [string]$resolution.executionNote
      documentPath = if ($null -ne $skillAction -and -not [string]::IsNullOrWhiteSpace([string](Get-BmoPropertyValue -Object $skillAction -Name 'path' -Default ''))) {
        [string](Get-BmoPropertyValue -Object $skillAction -Name 'path' -Default '')
      } else {
        $relativeReadmePath
      }
      readmePath = $relativeReadmePath
    }
  }

  return $catalog
}

function Get-BmoNextStepGuidance {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $repoInfo = Get-BmoRepoInfo -WorkspacePath $WorkspacePath
  $recentTasks = Get-BmoTaskHistory -WorkspacePath $WorkspacePath -Limit 20
  $activeTaskCount = ($script:BmoProcessTasks.Keys).Count
  $lines = @()

  if (-not $repoInfo.isGitRepo) {
    $lines += 'Pick a repo root or worktree root so BMO can light up source control, routines, and validation.'
  } else {
    if ($repoInfo.dirty) {
      $lines += "Review $($repoInfo.changedFiles.Count) changed files in Source Control, then run a validation before claiming the repo is ready."
    } else {
      $lines += 'Repo is clean. Start with worker status, runtime doctor, or the operating-system validation.'
    }

    if ($repoInfo.worktrees.Count -gt 1) {
      $lines += 'Multiple worktrees are available. Use the Source Control tab to switch the active workspace deliberately.'
    }
  }

  $recentValidation = $recentTasks | Where-Object { $_.taskType -eq 'validation' } | Select-Object -First 1
  if ($null -eq $recentValidation) {
    $lines += 'No recent validation task is recorded for this workspace yet.'
  } elseif ($recentValidation.status -ne 'succeeded') {
    $lines += 'The most recent validation did not succeed. Inspect the task log before moving forward.'
  }

  if ($activeTaskCount -gt 0) {
    $lines += "There are $activeTaskCount running tasks. Watch the Tasks tab for completion and exact output."
  }

  if ($lines.Count -eq 0) {
    $lines += 'Open a repo, inspect diffs, run a routine, and keep validation results visible before making claims.'
  }

  return $lines -join "`r`n"
}

function Get-BmoCommitPrepNote {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $repoInfo = Get-BmoRepoInfo -WorkspacePath $WorkspacePath
  if (-not $repoInfo.isGitRepo) {
    return 'Commit prep note unavailable: active workspace is not a git repo.'
  }

  $recentTasks = Get-BmoTaskHistory -WorkspacePath $WorkspacePath -Limit 20 |
    Where-Object { $_.taskType -in @('validation', 'routine', 'command') } |
    Select-Object -First 5

  $lines = @(
    '# Change Summary',
    '',
    "Branch: $($repoInfo.branch)",
    "Repo root: $($repoInfo.repoRoot)",
    "Dirty: $($repoInfo.dirty)",
    "Staged changes: $($repoInfo.stagedCount)",
    "Unstaged changes: $($repoInfo.unstagedCount)",
    "Untracked files: $($repoInfo.untrackedCount)",
    ''
  )

  if ($repoInfo.changedFiles.Count -gt 0) {
    $lines += 'Changed files:'
    foreach ($change in $repoInfo.changedFiles) {
      $statusBits = @()
      if (-not [string]::IsNullOrWhiteSpace($change.stagedStatus)) { $statusBits += "staged:$($change.stagedStatus)" }
      if (-not [string]::IsNullOrWhiteSpace($change.worktreeStatus)) { $statusBits += "worktree:$($change.worktreeStatus)" }
      if ($change.isUntracked) { $statusBits += 'untracked' }
      $lines += "- $($change.path) ($($statusBits -join ', '))"
    }
    $lines += ''
  }

  if ($recentTasks.Count -gt 0) {
    $lines += 'Recent operator-visible tasks:'
    foreach ($task in $recentTasks) {
      $lines += "- [$($task.status)] $($task.title)"
    }
    $lines += ''
  }

  $lines += 'Validation note: include exact commands and task results that support this change.'
  return $lines -join "`r`n"
}

function Get-BmoTaskOutputTextFromPaths {
  param(
    [string]$StdOutPath = '',
    [string]$StdErrPath = ''
  )

  $parts = @()
  if (-not [string]::IsNullOrWhiteSpace($StdOutPath) -and (Test-Path $StdOutPath)) {
    $stdout = Get-Content -LiteralPath $StdOutPath -Raw
    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
      $parts += "[stdout]`r`n$stdout"
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($StdErrPath) -and (Test-Path $StdErrPath)) {
    $stderr = Get-Content -LiteralPath $StdErrPath -Raw
    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
      $parts += "[stderr]`r`n$stderr"
    }
  }

  if ($parts.Count -eq 0) {
    return '[No output captured yet.]'
  }

  return ($parts -join "`r`n`r`n")
}

function Get-BmoTaskOutput {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    [switch]$NoTruncate
  )

  $task = Get-BmoTaskRecord -TaskId $TaskId
  if ($null -eq $task) {
    return "Unknown task id: $TaskId"
  }

  $parts = @(
    "Title: $($task.title)",
    "Type: $($task.taskType)",
    "Status: $($task.status)",
    "Workspace: $($task.workspace)"
  )

  if (-not [string]::IsNullOrWhiteSpace($task.command)) {
    $parts += "Command: $($task.command)"
  }
  if ($null -ne $task.exitCode) {
    $parts += "Exit code: $($task.exitCode)"
  }
  $parts += ''
  $parts += (Get-BmoTaskOutputTextFromPaths -StdOutPath $task.stdoutPath -StdErrPath $task.stderrPath)

  $text = $parts -join "`r`n"
  if ($NoTruncate) {
    return $text
  }

  return Get-BmoTruncatedText -Text $text
}

function Start-BmoProcessTask {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$CommandText,
    [string]$TaskType = 'command',
    [string]$Title = '',
    [string]$InitiatedBy = 'operator',
    [string]$SourceTaskId = '',
    [switch]$Approved
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $classification = Get-BmoCommandClassification -CommandText $CommandText
  if ($classification.decision -eq 'deny') {
    throw "Command denied by policy: $($classification.reason)"
  }

  if ($classification.requiresApproval -and -not $Approved) {
    throw "Approval required before running: $CommandText"
  }

  Add-BmoRecentWorkspace -WorkspacePath $resolvedWorkspace

  if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = $CommandText
  }

  $task = New-BmoTaskRecord -Title $Title -TaskType $TaskType -WorkspacePath $resolvedWorkspace `
    -InitiatedBy $InitiatedBy -Command $CommandText -PolicyDecision $classification.decision `
    -Capability $classification.capability -Notes $classification.reason
  $task.status = 'running'
  $task.startedAt = (Get-Date).ToString('o')
  $task.sourceTaskId = $SourceTaskId

  $stdoutPath = Join-Path (Get-BmoTaskRuntimeDirectory) ($task.id + '.stdout.log')
  $stderrPath = Join-Path (Get-BmoTaskRuntimeDirectory) ($task.id + '.stderr.log')
  '' | Set-Content -LiteralPath $stdoutPath -Encoding UTF8
  '' | Set-Content -LiteralPath $stderrPath -Encoding UTF8

  $task.stdoutPath = $stdoutPath
  $task.stderrPath = $stderrPath
  Save-BmoTaskRecord -Task $task

  $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($CommandText))
  $process = Start-Process -FilePath 'powershell.exe' `
    -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $encodedCommand) `
    -WorkingDirectory $resolvedWorkspace `
    -RedirectStandardOutput $stdoutPath `
    -RedirectStandardError $stderrPath `
    -WindowStyle Hidden `
    -PassThru

  $task.pid = $process.Id
  Save-BmoTaskRecord -Task $task

  $script:BmoProcessTasks[$task.id] = @{
    process = $process
    stdoutPath = $stdoutPath
    stderrPath = $stderrPath
    cancelRequested = $false
  }

  Write-BmoLog -Category 'task-start' -Message ("task={0} type={1} workspace={2} command={3}" -f $task.id, $TaskType, $resolvedWorkspace, $CommandText)
  return $task
}

function Sync-BmoActiveTasks {
  $completed = @()
  foreach ($taskId in @($script:BmoProcessTasks.Keys)) {
    $entry = $script:BmoProcessTasks[$taskId]
    $process = $entry.process

    $process.Refresh()
    if ($process.HasExited) {
      $process.WaitForExit()
      $task = Get-BmoTaskRecord -TaskId $taskId
      if ($null -eq $task) {
        $script:BmoProcessTasks.Remove($taskId)
        continue
      }

      $exitCode = 1
      try {
        $exitCode = [int]$process.ExitCode
      } catch {
        $exitCode = 1
      }

      $status = if ($entry.cancelRequested) {
        'canceled'
      } elseif ($exitCode -eq 0) {
        'succeeded'
      } else {
        'failed'
      }

      $outputPreview = Get-BmoTaskOutputTextFromPaths -StdOutPath $task.stdoutPath -StdErrPath $task.stderrPath
      $task = Update-BmoTaskRecord -TaskId $taskId -Changes @{
        status = $status
        completedAt = (Get-Date).ToString('o')
        exitCode = $exitCode
        outputPreview = (Get-BmoTruncatedText -Text $outputPreview)
      }

      Write-BmoLog -Category 'task-finish' -Message ("task={0} status={1} exit={2}" -f $taskId, $status, $exitCode)
      $process.Dispose()
      $script:BmoProcessTasks.Remove($taskId)
      $completed += $task
    }
  }

  return $completed
}

function Get-BmoActiveTasks {
  Sync-BmoActiveTasks | Out-Null
  $taskIds = @($script:BmoProcessTasks.Keys)
  $tasks = @()
  foreach ($taskId in $taskIds) {
    $task = Get-BmoTaskRecord -TaskId $taskId
    if ($null -ne $task) {
      $tasks += $task
    }
  }
  return @($tasks)
}

function Stop-BmoTask {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId
  )

  if (-not $script:BmoProcessTasks.ContainsKey($TaskId)) {
    return $false
  }

  $entry = $script:BmoProcessTasks[$TaskId]
  $entry.cancelRequested = $true
  $script:BmoProcessTasks[$TaskId] = $entry
  Update-BmoTaskRecord -TaskId $TaskId -Changes @{ status = 'canceling' } | Out-Null
  Stop-Process -Id $entry.process.Id -Force
  Write-BmoLog -Category 'task-cancel' -Message ("task={0}" -f $TaskId)
  return $true
}

function Restart-BmoTask {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskId,
    [switch]$Approved
  )

  $task = Get-BmoTaskRecord -TaskId $TaskId
  if ($null -eq $task) {
    throw "Unknown task id: $TaskId"
  }

  if ([string]::IsNullOrWhiteSpace($task.command)) {
    throw 'Only command-backed tasks can be rerun.'
  }

  return Start-BmoProcessTask -WorkspacePath $task.workspace -CommandText $task.command `
    -TaskType $task.taskType -Title $task.title -InitiatedBy 'operator' -SourceTaskId $TaskId -Approved:$Approved
}

function Get-BmoRecentCommits {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [int]$Limit = 12
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $repoRoot = Get-BmoRepoRoot -WorkspacePath $resolvedWorkspace
  if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    return @()
  }

  $lines = @(& git -C $resolvedWorkspace log --oneline --decorate --max-count=$Limit 2>$null)
  $commits = @()
  foreach ($line in $lines) {
    $trimmed = [string]$line
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
      continue
    }

    $hash = ''
    $summary = $trimmed
    if ($trimmed -match '^(?<hash>[0-9a-f]+)\s+(?<summary>.+)$') {
      $hash = $Matches['hash']
      $summary = $Matches['summary']
    }

    $commits += [pscustomobject]@{
      hash = $hash
      summary = $summary
      line = $trimmed
    }
  }

  return $commits
}

function Invoke-BmoGitStageFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [string[]]$RelativePaths = @(),
    [switch]$Approved
  )

  $quotedPaths = @($RelativePaths | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { ConvertTo-BmoPowerShellLiteral -Text ([string]$_) })
  $command = if ($quotedPaths.Count -gt 0) {
    'git add -- ' + ($quotedPaths -join ' ')
  } else {
    'git add -A'
  }

  return Start-BmoProcessTask -WorkspacePath $WorkspacePath -CommandText $command `
    -TaskType 'git' -Title 'Stage changes' -InitiatedBy 'operator' -Approved:$Approved
}

function Invoke-BmoGitUnstageFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [string[]]$RelativePaths = @(),
    [switch]$Approved
  )

  $quotedPaths = @($RelativePaths | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { ConvertTo-BmoPowerShellLiteral -Text ([string]$_) })
  $command = if ($quotedPaths.Count -gt 0) {
    'git restore --staged -- ' + ($quotedPaths -join ' ')
  } else {
    'git restore --staged .'
  }

  return Start-BmoProcessTask -WorkspacePath $WorkspacePath -CommandText $command `
    -TaskType 'git' -Title 'Unstage changes' -InitiatedBy 'operator' -Approved:$Approved
}

function Invoke-BmoGitCommit {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [switch]$Approved
  )

  $trimmedMessage = $Message.Trim()
  if ([string]::IsNullOrWhiteSpace($trimmedMessage)) {
    throw 'Commit message cannot be empty.'
  }

  $command = 'git commit -m ' + (ConvertTo-BmoPowerShellLiteral -Text $trimmedMessage)
  return Start-BmoProcessTask -WorkspacePath $WorkspacePath -CommandText $command `
    -TaskType 'git' -Title ('Commit: ' + $trimmedMessage) -InitiatedBy 'operator' -Approved:$Approved
}

function Invoke-BmoValidationAction {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$ActionId,
    [switch]$Approved
  )

  $action = @((Get-BmoValidationActions) | Where-Object { $_.id -eq $ActionId } | Select-Object -First 1)
  if ($action.Count -eq 0) {
    throw "Unknown validation action: $ActionId"
  }

  $resolved = Resolve-BmoManagedCommand -CommandText ([string]$action[0].command) -ActionId $ActionId -WorkspacePath $WorkspacePath
  return Start-BmoProcessTask -WorkspacePath $WorkspacePath -CommandText $resolved.effectiveCommand `
    -TaskType 'validation' -Title $action[0].name -InitiatedBy 'operator' -Approved:$Approved
}

function Invoke-BmoRoutineAction {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RoutineName,
    [switch]$Approved
  )

  $pack = Get-BmoRoutinePack -WorkspacePath $WorkspacePath
  $routine = @($pack.routines | Where-Object { $_.name -eq $RoutineName } | Select-Object -First 1)
  if ($routine.Count -eq 0) {
    throw "Unknown routine: $RoutineName"
  }

  $resolved = Resolve-BmoManagedCommand -CommandText ([string]$routine[0].command) -ActionId $RoutineName -WorkspacePath $WorkspacePath
  return Start-BmoProcessTask -WorkspacePath $WorkspacePath -CommandText $resolved.effectiveCommand `
    -TaskType 'routine' -Title $routine[0].name -InitiatedBy 'operator' -Approved:$Approved
}

function Invoke-BmoRuntimeProfileAction {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$ProfileId,
    [switch]$Approved
  )

  $profile = @((Get-BmoRuntimeProfiles) | Where-Object { $_.id -eq $ProfileId } | Select-Object -First 1)
  if ($profile.Count -eq 0) {
    throw "Unknown runtime profile: $ProfileId"
  }

  $settings = Get-BmoSettings
  $settings.preferredRuntimeProfile = $ProfileId
  Save-BmoSettings -Settings $settings

  $resolved = Resolve-BmoManagedCommand -CommandText ([string]$profile[0].command) -ActionId $ProfileId -WorkspacePath $WorkspacePath
  return Start-BmoProcessTask -WorkspacePath $WorkspacePath -CommandText $resolved.effectiveCommand `
    -TaskType 'runtime-profile' -Title $profile[0].name -InitiatedBy 'operator' -Approved:$Approved
}

function Write-BmoTaskRecord {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt,
    [Parameter(Mandatory = $true)]
    [string]$Reply,
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [string]$Mode = 'chat'
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $title = '{0}: {1}' -f $Mode, (Get-BmoTruncatedText -Text $Prompt -MaxLength 80).Replace("`r", ' ').Replace("`n", ' ')
  $task = New-BmoTaskRecord -Title $title -TaskType $Mode -WorkspacePath $resolvedWorkspace -InitiatedBy 'agent'
  $task.status = 'succeeded'
  $task.startedAt = (Get-Date).ToString('o')
  $task.completedAt = $task.startedAt
  $task.prompt = $Prompt
  $task.reply = $Reply
  $task.outputPreview = Get-BmoTruncatedText -Text $Reply
  Save-BmoTaskRecord -Task $task
}

function Invoke-BmoProviderReply {
  param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Settings,
    [Parameter(Mandatory = $true)]
    [string]$Prompt
  )

  if ($Settings.provider.mode -ne 'openai-compatible') {
    return $null
  }

  if ([string]::IsNullOrWhiteSpace($Settings.provider.endpoint)) {
    throw 'Provider mode is openai-compatible but endpoint is empty.'
  }

  $headers = @{
    'Content-Type' = 'application/json'
  }

  if (-not [string]::IsNullOrWhiteSpace($Settings.provider.apiKey)) {
    $headers['Authorization'] = "Bearer $($Settings.provider.apiKey)"
  }

  $body = @{
    model = $Settings.provider.model
    messages = @(
      @{
        role = 'system'
        content = 'You are BMO. Be concise, practical, and honest about local workstation limits.'
      },
      @{
        role = 'user'
        content = $Prompt
      }
    )
  } | ConvertTo-Json -Depth 6

  $response = Invoke-RestMethod -Uri $Settings.provider.endpoint -Method Post -Headers $headers -Body $body
  if ($null -eq $response.choices -or $response.choices.Count -eq 0) {
    throw 'Provider returned no choices.'
  }

  return $response.choices[0].message.content
}

function Get-BmoOfflineReply {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt,
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $trimmed = $Prompt.Trim()
  $lower = $trimmed.ToLowerInvariant()

  if ($lower -match 'status|repo|workspace') {
    $summary = Get-BmoRepoSummary -WorkspacePath $WorkspacePath
    $items = if ($summary.topLevelItems.Count -gt 0) {
      ($summary.topLevelItems -join ', ')
    } else {
      'No files found.'
    }

    $git = if ([string]::IsNullOrWhiteSpace($summary.gitStatus)) {
      'No git status available.'
    } else {
      $summary.gitStatus
    }

    $guidance = Get-BmoNextStepGuidance -WorkspacePath $WorkspacePath
    return "Workspace: $($summary.workspace)`r`nTop-level items: $items`r`nGit: $git`r`n`r`nNext steps:`r`n$guidance"
  }

  if ($lower -match 'backlog') {
    return Get-BmoDocumentContent -WorkspacePath $WorkspacePath -RelativePath 'context\BACKLOG.md'
  }

  if ($lower -match 'runbook|startup|recovery') {
    return Get-BmoDocumentContent -WorkspacePath $WorkspacePath -RelativePath 'context\RUNBOOK.md'
  }

  if ($lower -match 'skill') {
    $skills = Get-BmoSkillCatalog -WorkspacePath $WorkspacePath
    if ($skills.Count -eq 0) {
      return 'No local skill catalog was found in this workspace.'
    }
    $lines = @('Local skills:')
    foreach ($skill in $skills) {
      $lines += "- $($skill.name): $($skill.description)"
    }
    return $lines -join "`r`n"
  }

  if ($lower -match 'routine') {
    $pack = Get-BmoRoutinePack -WorkspacePath $WorkspacePath
    if ($pack.routines.Count -eq 0) {
      return 'No routine pack was found in this workspace.'
    }
    $lines = @('BMO routines:')
    foreach ($routine in $pack.routines) {
      $lines += "- $($routine.name): $($routine.command)"
    }
    return $lines -join "`r`n"
  }

  return @"
BMO Desktop is running in local workstation mode.

What is real right now:
- repo and worktree inspection
- source control diff review
- editable workspace files
- supervised command, validation, and routine tasks
- skills and routine discovery from repo manifests

Use the Command Center tab for previewed command execution, the Tasks tab for logs and reruns, and the Source Control tab for diff review.
"@
}

function Invoke-BmoAssistant {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt,
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $settings = Get-BmoSettings
  $trimmed = $Prompt.Trim()

  if ($trimmed.StartsWith('/cmd ')) {
    $command = $trimmed.Substring(5).Trim()
    $classification = Get-BmoCommandClassification -CommandText $command
    if ($classification.decision -eq 'deny') {
      return "Command blocked by policy.`r`nDecision: $($classification.decision)`r`nCapability: $($classification.capability)`r`nReason: $($classification.reason)"
    }

    if ($classification.requiresApproval) {
      return "Command requires approval before it can run.`r`nDecision: $($classification.decision)`r`nCapability: $($classification.capability)`r`nReason: $($classification.reason)`r`n`r`nUse the Command Center tab or `/unsafe ...` to approve it intentionally."
    }

    $task = Start-BmoProcessTask -WorkspacePath $resolvedWorkspace -CommandText $command -TaskType 'command' -Title $command -InitiatedBy 'agent'
    return "Started command task $($task.id). Open the Tasks tab to watch output, cancel, or rerun it."
  }

  if ($trimmed.StartsWith('/unsafe ')) {
    $command = $trimmed.Substring(8).Trim()
    $classification = Get-BmoCommandClassification -CommandText $command
    if ($classification.decision -eq 'deny') {
      return "Command is hard-blocked by policy and cannot run from `/unsafe`.`r`nReason: $($classification.reason)"
    }

    $task = Start-BmoProcessTask -WorkspacePath $resolvedWorkspace -CommandText $command -TaskType 'command' -Title $command -InitiatedBy 'agent' -Approved
    return "Started approved command task $($task.id). The exact command, workspace, logs, and exit code are now tracked in Tasks."
  }

  if ($trimmed.StartsWith('/read ')) {
    $relativePath = $trimmed.Substring(6).Trim()
    $reply = Read-BmoWorkspaceFile -WorkspacePath $resolvedWorkspace -RelativePath $relativePath
    Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $resolvedWorkspace -Mode 'read'
    return $reply
  }

  if ($trimmed -eq '/policy') {
    $summary = Get-BmoPolicySummary
    $reply = @"
Default mode: $($summary.defaultMode)
Safe execution mode: $($summary.safeExecutionMode)

Exact safe commands:
$($summary.exactSafeCommands -join "`r`n")

Safe prefixes:
$($summary.safePrefixes -join "`r`n")

Blocked tokens:
$($summary.blockedTokens -join "`r`n")
"@
    Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $resolvedWorkspace -Mode 'policy'
    return $reply
  }

  if ($trimmed -eq '/tasks') {
    $tasks = Get-BmoTaskHistory -WorkspacePath $resolvedWorkspace -Limit 10
    if ($tasks.Count -eq 0) {
      return 'No recorded tasks yet for this workspace.'
    }

    $lines = @('Recent tasks:')
    foreach ($task in $tasks) {
      $lines += "- [$($task.status)] $($task.title)"
    }
    return $lines -join "`r`n"
  }

  try {
    $providerReply = Invoke-BmoProviderReply -Settings $settings -Prompt $trimmed
    if (-not [string]::IsNullOrWhiteSpace($providerReply)) {
      $reply = $providerReply.Trim()
      Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $resolvedWorkspace -Mode 'provider'
      return $reply
    }
  } catch {
    $reply = "Cloud provider failed, so BMO stayed local.`r`n`r`n$($_.Exception.Message)"
    Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $resolvedWorkspace -Mode 'provider-error'
    return $reply
  }

  $reply = Get-BmoOfflineReply -Prompt $trimmed -WorkspacePath $resolvedWorkspace
  Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $resolvedWorkspace -Mode 'offline'
  return $reply
}
