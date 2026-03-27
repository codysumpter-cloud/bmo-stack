Set-StrictMode -Version Latest

function Get-BmoAppRoot {
  return Split-Path -Parent $PSScriptRoot
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
      if (-not [string]::IsNullOrWhiteSpace($state.dataRoot)) {
        $configured = $state.dataRoot
      }
    } catch {
      $configured = $null
    }
  }

  $candidates = @()
  if (-not [string]::IsNullOrWhiteSpace($configured)) { $candidates += $configured }
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
    (Join-Path $root 'config'),
    (Join-Path $root 'logs'),
    (Join-Path $root 'tasks'),
    (Join-Path $root 'memory'),
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
  $appRoot = Get-BmoAppRoot
  return Join-Path $appRoot 'config\appsettings.example.json'
}

function Initialize-BmoSettings {
  Initialize-BmoDataDirs
  $settingsPath = Get-BmoSettingsPath
  $templatePath = Get-BmoSettingsTemplatePath

  if (-not (Test-Path $settingsPath)) {
    Copy-Item -LiteralPath $templatePath -Destination $settingsPath
  }

  return Get-BmoSettings
}

function Get-BmoSettings {
  $settingsPath = Get-BmoSettingsPath
  return Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
}

function Save-BmoSettings {
  param(
    [Parameter(Mandatory = $true)]
    [pscustomobject]$Settings
  )

  $settingsPath = Get-BmoSettingsPath
  $Settings | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $settingsPath -Encoding UTF8
}

function Get-BmoPolicy {
  $appRoot = Get-BmoAppRoot
  $policyPath = Join-Path $appRoot 'policies\capability-policy.example.json'
  return Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
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

  Initialize-BmoDataDirs
  $record = [pscustomobject]@{
    timestamp = (Get-Date).ToString('o')
    mode = $Mode
    workspace = $WorkspacePath
    prompt = $Prompt
    reply = $Reply
  }

  $fileName = '{0}.json' -f ([guid]::NewGuid().ToString())
  $path = Join-Path (Get-BmoDataRoot) ('tasks\' + $fileName)
  $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $path -Encoding UTF8
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
    [string]$WorkspacePath
  )

  if ([string]::IsNullOrWhiteSpace($WorkspacePath)) {
    throw 'Choose a workspace folder first.'
  }

  $resolved = Resolve-Path -LiteralPath $WorkspacePath -ErrorAction Stop
  return $resolved.Path
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
  $safe = Get-BmoSafeCommands
  return @($safe.exact)
}

function Get-BmoSafeCommandPrefixes {
  $safe = Get-BmoSafeCommands
  return @($safe.prefixes)
}

function Get-BmoBlockedTokens {
  $safe = Get-BmoSafeCommands
  return @($safe.blockedTokens)
}

function Test-BmoSafeCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandText
  )

  $normalized = $CommandText.Trim().ToLowerInvariant()

  foreach ($token in Get-BmoBlockedTokens) {
    if ($normalized.Contains($token.ToLowerInvariant())) {
      return $false
    }
  }

  foreach ($candidate in Get-BmoExactSafeCommands) {
    if ($normalized -eq $candidate.ToLowerInvariant()) {
      return $true
    }
  }

  foreach ($prefix in Get-BmoSafeCommandPrefixes) {
    if ($normalized.StartsWith($prefix.ToLowerInvariant())) {
      return $true
    }
  }

  return $false
}

function Get-BmoPolicySummary {
  $safe = Get-BmoSafeCommands
  $policy = Get-BmoPolicy
  return [pscustomobject]@{
    defaultMode = $policy.defaultMode
    exactSafeCommands = @($safe.exact)
    safePrefixes = @($safe.prefixes)
    blockedTokens = @($safe.blockedTokens)
  }
}

function Get-BmoRelativePath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$TargetPath
  )

  $workspaceUri = New-Object System.Uri((Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath).TrimEnd('\') + '\')
  $targetUri = New-Object System.Uri((Resolve-Path -LiteralPath $TargetPath -ErrorAction Stop).Path)
  $relative = $workspaceUri.MakeRelativeUri($targetUri).ToString()
  return [System.Uri]::UnescapeDataString($relative).Replace('/', '\')
}

function Read-BmoWorkspaceFile {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $candidate = Join-Path $resolvedWorkspace $RelativePath
  $resolvedFile = Resolve-Path -LiteralPath $candidate -ErrorAction Stop
  $resolvedFilePath = $resolvedFile.Path

  if (-not $resolvedFilePath.StartsWith($resolvedWorkspace, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Read blocked: file is outside the workspace root.'
  }

  if ((Get-Item -LiteralPath $resolvedFilePath).PSIsContainer) {
    throw 'Cannot read a directory. Choose a file instead.'
  }

  return Get-Content -LiteralPath $resolvedFilePath -Raw
}

function Invoke-BmoCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$CommandText,
    [switch]$AllowUnsafe
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  if (-not $AllowUnsafe -and -not (Test-BmoSafeCommand -CommandText $CommandText)) {
    throw "Command blocked by policy: $CommandText"
  }

  Push-Location $resolvedWorkspace
  try {
    $output = & powershell -NoProfile -ExecutionPolicy Bypass -Command $CommandText 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -and [string]::IsNullOrWhiteSpace($output)) {
      throw "Command failed with exit code $LASTEXITCODE"
    }
  } finally {
    Pop-Location
  }

  $result = [pscustomobject]@{
    command = $CommandText
    workspace = $resolvedWorkspace
    output = $output.Trim()
    safe = (Test-BmoSafeCommand -CommandText $CommandText)
  }

  Write-BmoLog -Category 'command' -Message ("workspace={0} safe={1} command={2}" -f $resolvedWorkspace, $result.safe, $CommandText)
  return $result
}

function Get-BmoRepoSummary {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $WorkspacePath
  $items = Get-ChildItem -LiteralPath $resolvedWorkspace -Force | Select-Object -First 20
  $names = $items | ForEach-Object { $_.Name }
  $gitStatus = ''

  if (Test-Path (Join-Path $resolvedWorkspace '.git')) {
    Push-Location $resolvedWorkspace
    try {
      $gitStatus = (& git status --short --branch 2>&1 | Out-String).Trim()
    } finally {
      Pop-Location
    }
  }

  return [pscustomobject]@{
    workspace = $resolvedWorkspace
    topLevelItems = $names
    gitStatus = $gitStatus
  }
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
        content = 'You are BMO. Be concise, helpful, and safe on Windows.'
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

    return "Workspace: $($summary.workspace)`r`nTop-level items: $items`r`nGit: $git"
  }

  if ($lower -match 'backlog') {
    $backlogPath = Join-Path $WorkspacePath 'context\BACKLOG.md'
    if (Test-Path $backlogPath) {
      return (Get-Content -LiteralPath $backlogPath -Raw)
    }
  }

  if ($lower -match 'runbook|startup|recovery') {
    $runbookPath = Join-Path $WorkspacePath 'context\RUNBOOK.md'
    if (Test-Path $runbookPath) {
      return (Get-Content -LiteralPath $runbookPath -Raw)
    }
  }

  return @"
BMO Desktop is running in offline mode.

What I can do right now:
- summarize the current workspace
- show the backlog or runbook
- run safe commands with `/cmd ...`
- read a file with `/read relative\path.txt`

To enable richer chat replies, set `provider.mode` to `openai-compatible` in
`config\appsettings.json` and add an endpoint, API key, and model.
"@
}

function Invoke-BmoAssistant {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt,
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath
  )

  $settings = Get-BmoSettings
  $trimmed = $Prompt.Trim()

  if ($trimmed.StartsWith('/cmd ')) {
    $command = $trimmed.Substring(5).Trim()
    $result = Invoke-BmoCommand -WorkspacePath $WorkspacePath -CommandText $command
    $reply = "[command] $($result.command)`r`n`r`n$($result.output)"
    Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $WorkspacePath -Mode 'command'
    return $reply
  }

  if ($trimmed.StartsWith('/unsafe ')) {
    $command = $trimmed.Substring(8).Trim()
    $result = Invoke-BmoCommand -WorkspacePath $WorkspacePath -CommandText $command -AllowUnsafe
    $reply = "[unsafe command] $($result.command)`r`n`r`n$($result.output)"
    Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $WorkspacePath -Mode 'unsafe-command'
    return $reply
  }

  if ($trimmed.StartsWith('/read ')) {
    $relativePath = $trimmed.Substring(6).Trim()
    $reply = Read-BmoWorkspaceFile -WorkspacePath $WorkspacePath -RelativePath $relativePath
    Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $WorkspacePath -Mode 'read'
    return $reply
  }

  if ($trimmed -eq '/policy') {
    $summary = Get-BmoPolicySummary
    $reply = @"
Default mode: $($summary.defaultMode)

Exact safe commands:
$($summary.exactSafeCommands -join "`r`n")

Safe prefixes:
$($summary.safePrefixes -join "`r`n")

Blocked tokens:
$($summary.blockedTokens -join "`r`n")
"@
    Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $WorkspacePath -Mode 'policy'
    return $reply
  }

  try {
    $providerReply = Invoke-BmoProviderReply -Settings $settings -Prompt $trimmed
    if (-not [string]::IsNullOrWhiteSpace($providerReply)) {
      $reply = $providerReply.Trim()
      Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $WorkspacePath -Mode 'provider'
      return $reply
    }
  } catch {
    $reply = "Cloud provider failed, so I stayed local.`r`n`r`n$($_.Exception.Message)"
    Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $WorkspacePath -Mode 'provider-error'
    return $reply
  }

  $reply = Get-BmoOfflineReply -Prompt $trimmed -WorkspacePath $WorkspacePath
  Write-BmoTaskRecord -Prompt $Prompt -Reply $reply -WorkspacePath $WorkspacePath -Mode 'offline'
  return $reply
}
