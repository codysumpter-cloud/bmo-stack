Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. (Join-Path $PSScriptRoot 'BMO.Broker.ps1')

$settings = Initialize-BmoSettings
Write-BmoLog -Category 'startup' -Message 'Desktop app launched.'

$palette = @{
  Window = [System.Drawing.Color]::FromArgb(244, 250, 248)
  Panel = [System.Drawing.Color]::FromArgb(229, 241, 238)
  PanelStrong = [System.Drawing.Color]::FromArgb(205, 230, 225)
  Accent = [System.Drawing.Color]::FromArgb(34, 102, 102)
  AccentSoft = [System.Drawing.Color]::FromArgb(106, 165, 156)
  Border = [System.Drawing.Color]::FromArgb(176, 205, 199)
  Text = [System.Drawing.Color]::FromArgb(34, 49, 52)
  Muted = [System.Drawing.Color]::FromArgb(88, 105, 108)
  White = [System.Drawing.Color]::White
}

function New-BmoFont {
  param(
    [string]$Name = 'Segoe UI',
    [float]$Size = 10,
    [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
  )

  return New-Object System.Drawing.Font($Name, $Size, $Style)
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'BMO Windows Desktop'
$form.Width = 1320
$form.Height = 860
$form.StartPosition = 'CenterScreen'
$form.BackColor = $palette.Window
$form.MinimumSize = New-Object System.Drawing.Size(1100, 760)

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = 'Top'
$headerPanel.Height = 84
$headerPanel.BackColor = $palette.PanelStrong
$headerPanel.Padding = New-Object System.Windows.Forms.Padding(16, 14, 16, 12)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = 'BMO Windows Desktop'
$titleLabel.Font = New-BmoFont -Size 18 -Style Bold
$titleLabel.ForeColor = $palette.Accent
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(16, 12)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = 'Workspace-aware assistant with a safer command broker, file browser, and installable Windows runtime.'
$subtitleLabel.Font = New-BmoFont -Size 9.5
$subtitleLabel.ForeColor = $palette.Muted
$subtitleLabel.AutoSize = $true
$subtitleLabel.Location = New-Object System.Drawing.Point(18, 44)

$workspaceLabel = New-Object System.Windows.Forms.Label
$workspaceLabel.Text = 'Workspace'
$workspaceLabel.Font = New-BmoFont -Size 9.5 -Style Bold
$workspaceLabel.ForeColor = $palette.Text
$workspaceLabel.AutoSize = $true
$workspaceLabel.Location = New-Object System.Drawing.Point(680, 18)

$workspaceText = New-Object System.Windows.Forms.TextBox
$workspaceText.Left = 760
$workspaceText.Top = 14
$workspaceText.Width = 400
$workspaceText.Text = $settings.defaultWorkspace
$workspaceText.Font = New-BmoFont -Size 9.5

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = 'Browse'
$browseButton.Left = 1170
$browseButton.Top = 12
$browseButton.Width = 110
$browseButton.Height = 28
$browseButton.BackColor = $palette.Accent
$browseButton.ForeColor = $palette.White
$browseButton.FlatStyle = 'Flat'

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = 'Save'
$saveButton.Left = 1170
$saveButton.Top = 44
$saveButton.Width = 110
$saveButton.Height = 26
$saveButton.BackColor = $palette.Panel
$saveButton.ForeColor = $palette.Text
$saveButton.FlatStyle = 'Flat'

[void]$headerPanel.Controls.Add($titleLabel)
[void]$headerPanel.Controls.Add($subtitleLabel)
[void]$headerPanel.Controls.Add($workspaceLabel)
[void]$headerPanel.Controls.Add($workspaceText)
[void]$headerPanel.Controls.Add($browseButton)
[void]$headerPanel.Controls.Add($saveButton)

$mainSplit = New-Object System.Windows.Forms.SplitContainer
$mainSplit.Dock = 'Fill'
$mainSplit.SplitterDistance = 390
$mainSplit.BackColor = $palette.Border

$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Dock = 'Fill'
$leftPanel.BackColor = $palette.Panel
$leftPanel.Padding = New-Object System.Windows.Forms.Padding(14)

$leftTitle = New-Object System.Windows.Forms.Label
$leftTitle.Text = 'Workspace Browser'
$leftTitle.Font = New-BmoFont -Size 12 -Style Bold
$leftTitle.ForeColor = $palette.Accent
$leftTitle.AutoSize = $true
$leftTitle.Location = New-Object System.Drawing.Point(14, 12)

$leftHint = New-Object System.Windows.Forms.Label
$leftHint.Text = 'Browse files, preview content, and send a selected file into chat.'
$leftHint.Font = New-BmoFont -Size 9
$leftHint.ForeColor = $palette.Muted
$leftHint.AutoSize = $true
$leftHint.Location = New-Object System.Drawing.Point(14, 36)

$refreshTreeButton = New-Object System.Windows.Forms.Button
$refreshTreeButton.Text = 'Refresh'
$refreshTreeButton.Left = 14
$refreshTreeButton.Top = 62
$refreshTreeButton.Width = 90
$refreshTreeButton.FlatStyle = 'Flat'

$readSelectedButton = New-Object System.Windows.Forms.Button
$readSelectedButton.Text = 'Read Selected'
$readSelectedButton.Left = 112
$readSelectedButton.Top = 62
$readSelectedButton.Width = 110
$readSelectedButton.FlatStyle = 'Flat'

$insertReadButton = New-Object System.Windows.Forms.Button
$insertReadButton.Text = 'Insert /read'
$insertReadButton.Left = 230
$insertReadButton.Top = 62
$insertReadButton.Width = 100
$insertReadButton.FlatStyle = 'Flat'

$browserSplit = New-Object System.Windows.Forms.SplitContainer
$browserSplit.Dock = 'Bottom'
$browserSplit.Orientation = 'Horizontal'
$browserSplit.SplitterDistance = 350
$browserSplit.Height = 680
$browserSplit.Top = 100

$fileTree = New-Object System.Windows.Forms.TreeView
$fileTree.Dock = 'Fill'
$fileTree.HideSelection = $false
$fileTree.Font = New-BmoFont -Size 9.5
$fileTree.BorderStyle = 'FixedSingle'

$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Dock = 'Fill'
$previewPanel.BackColor = $palette.White
$previewPanel.Padding = New-Object System.Windows.Forms.Padding(0)

$previewPathLabel = New-Object System.Windows.Forms.Label
$previewPathLabel.Text = 'Preview'
$previewPathLabel.Dock = 'Top'
$previewPathLabel.Height = 30
$previewPathLabel.Padding = New-Object System.Windows.Forms.Padding(8, 8, 8, 0)
$previewPathLabel.Font = New-BmoFont -Size 9 -Style Bold
$previewPathLabel.ForeColor = $palette.Text

$previewBox = New-Object System.Windows.Forms.RichTextBox
$previewBox.Dock = 'Fill'
$previewBox.ReadOnly = $true
$previewBox.Font = New-BmoFont -Name 'Consolas' -Size 9.5
$previewBox.BackColor = $palette.White
$previewBox.BorderStyle = 'FixedSingle'

[void]$previewPanel.Controls.Add($previewBox)
[void]$previewPanel.Controls.Add($previewPathLabel)

$browserSplit.Panel1.BackColor = $palette.Panel
$browserSplit.Panel2.BackColor = $palette.Panel
[void]$browserSplit.Panel1.Controls.Add($fileTree)
[void]$browserSplit.Panel2.Controls.Add($previewPanel)

[void]$leftPanel.Controls.Add($leftTitle)
[void]$leftPanel.Controls.Add($leftHint)
[void]$leftPanel.Controls.Add($refreshTreeButton)
[void]$leftPanel.Controls.Add($readSelectedButton)
[void]$leftPanel.Controls.Add($insertReadButton)
[void]$leftPanel.Controls.Add($browserSplit)

$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Dock = 'Fill'
$rightPanel.BackColor = $palette.Window
$rightPanel.Padding = New-Object System.Windows.Forms.Padding(16, 14, 16, 12)

$chatTitle = New-Object System.Windows.Forms.Label
$chatTitle.Text = 'Chat + Actions'
$chatTitle.Font = New-BmoFont -Size 12 -Style Bold
$chatTitle.ForeColor = $palette.Accent
$chatTitle.AutoSize = $true
$chatTitle.Location = New-Object System.Drawing.Point(16, 12)

$chatHint = New-Object System.Windows.Forms.Label
$chatHint.Text = 'Use quick actions for repo context, `/cmd ...` for safe commands, `/policy` to inspect the broker rules, or `/unsafe ...` for explicitly approved commands.'
$chatHint.Font = New-BmoFont -Size 9
$chatHint.ForeColor = $palette.Muted
$chatHint.Width = 860
$chatHint.Height = 34
$chatHint.Location = New-Object System.Drawing.Point(16, 36)

$actionPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$actionPanel.Left = 16
$actionPanel.Top = 76
$actionPanel.Width = 860
$actionPanel.Height = 38
$actionPanel.WrapContents = $false
$actionPanel.AutoScroll = $false

function New-BmoActionButton {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  $button = New-Object System.Windows.Forms.Button
  $button.Text = $Text
  $button.Width = 110
  $button.Height = 28
  $button.Margin = New-Object System.Windows.Forms.Padding(0, 0, 10, 0)
  $button.FlatStyle = 'Flat'
  $button.BackColor = $palette.Panel
  $button.ForeColor = $palette.Text
  return $button
}

$quickStatusButton = New-BmoActionButton -Text 'Repo Status'
$quickBacklogButton = New-BmoActionButton -Text 'Backlog'
$quickRunbookButton = New-BmoActionButton -Text 'Runbook'
$quickPolicyButton = New-BmoActionButton -Text 'Policy'
$quickLogsButton = New-BmoActionButton -Text 'Open Logs'

[void]$actionPanel.Controls.Add($quickStatusButton)
[void]$actionPanel.Controls.Add($quickBacklogButton)
[void]$actionPanel.Controls.Add($quickRunbookButton)
[void]$actionPanel.Controls.Add($quickPolicyButton)
[void]$actionPanel.Controls.Add($quickLogsButton)

$transcript = New-Object System.Windows.Forms.RichTextBox
$transcript.Left = 16
$transcript.Top = 124
$transcript.Width = 860
$transcript.Height = 510
$transcript.ReadOnly = $true
$transcript.Font = New-BmoFont -Name 'Consolas' -Size 10
$transcript.BackColor = $palette.White
$transcript.BorderStyle = 'FixedSingle'

$composerLabel = New-Object System.Windows.Forms.Label
$composerLabel.Text = 'Message'
$composerLabel.Font = New-BmoFont -Size 9.5 -Style Bold
$composerLabel.ForeColor = $palette.Text
$composerLabel.AutoSize = $true
$composerLabel.Location = New-Object System.Drawing.Point(16, 646)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Left = 16
$inputBox.Top = 670
$inputBox.Width = 730
$inputBox.Height = 84
$inputBox.Multiline = $true
$inputBox.AcceptsReturn = $true
$inputBox.AcceptsTab = $false
$inputBox.Font = New-BmoFont -Size 10
$inputBox.BorderStyle = 'FixedSingle'

$sendButton = New-Object System.Windows.Forms.Button
$sendButton.Text = 'Send'
$sendButton.Left = 758
$sendButton.Top = 670
$sendButton.Width = 118
$sendButton.Height = 38
$sendButton.BackColor = $palette.Accent
$sendButton.ForeColor = $palette.White
$sendButton.FlatStyle = 'Flat'

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = 'Clear Chat'
$clearButton.Left = 758
$clearButton.Top = 716
$clearButton.Width = 118
$clearButton.Height = 38
$clearButton.BackColor = $palette.Panel
$clearButton.ForeColor = $palette.Text
$clearButton.FlatStyle = 'Flat'

$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = 'Ready'
$statusLabel.ForeColor = $palette.Text
$dataRootLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$dataRootLabel.Text = "Data: $(Get-BmoDataRoot)"
$dataRootLabel.ForeColor = $palette.Muted
[void]$statusBar.Items.Add($statusLabel)
[void]$statusBar.Items.Add((New-Object System.Windows.Forms.ToolStripStatusLabel('   ')))
[void]$statusBar.Items.Add($dataRootLabel)

[void]$rightPanel.Controls.Add($chatTitle)
[void]$rightPanel.Controls.Add($chatHint)
[void]$rightPanel.Controls.Add($actionPanel)
[void]$rightPanel.Controls.Add($transcript)
[void]$rightPanel.Controls.Add($composerLabel)
[void]$rightPanel.Controls.Add($inputBox)
[void]$rightPanel.Controls.Add($sendButton)
[void]$rightPanel.Controls.Add($clearButton)
[void]$rightPanel.Controls.Add($statusBar)

$mainSplit.Panel1.Controls.Add($leftPanel)
$mainSplit.Panel2.Controls.Add($rightPanel)

[void]$form.Controls.Add($mainSplit)
[void]$form.Controls.Add($headerPanel)

function Add-TranscriptLine {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Speaker,
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $headerColor = if ($Speaker -eq 'BMO') { $palette.Accent } else { $palette.Text }

  $transcript.SelectionStart = $transcript.TextLength
  $transcript.SelectionColor = $headerColor
  $transcript.SelectionFont = New-BmoFont -Name 'Consolas' -Size 10 -Style Bold
  $transcript.AppendText("[$timestamp] $Speaker`r`n")
  $transcript.SelectionColor = $palette.Text
  $transcript.SelectionFont = New-BmoFont -Name 'Consolas' -Size 10
  $transcript.AppendText("$Text`r`n`r`n")
  $transcript.SelectionStart = $transcript.TextLength
  $transcript.ScrollToCaret()
}

function Get-WorkspaceOrThrow {
  $workspace = $workspaceText.Text.Trim()
  if (-not (Test-BmoWorkspace -WorkspacePath $workspace)) {
    throw 'Choose a valid workspace folder first.'
  }
  return $workspace
}

function Set-StatusText {
  param([string]$Text)
  $statusLabel.Text = $Text
}

function Save-WorkspaceSetting {
  $latest = Get-BmoSettings
  $latest.defaultWorkspace = $workspaceText.Text.Trim()
  Save-BmoSettings -Settings $latest
  Write-BmoLog -Category 'settings' -Message ("Saved default workspace: {0}" -f $latest.defaultWorkspace)
}

function Add-PlaceholderNode {
  param([System.Windows.Forms.TreeNode]$Node)
  [void]$Node.Nodes.Add('__placeholder__')
}

function New-FileTreeNode {
  param(
    [Parameter(Mandatory = $true)]
    [System.IO.FileSystemInfo]$Item
  )

  $node = New-Object System.Windows.Forms.TreeNode
  $node.Text = $Item.Name
  $node.Tag = $Item.FullName

  if ($Item.PSIsContainer) {
    $node.ForeColor = $palette.Accent
    Add-PlaceholderNode -Node $node
  } else {
    $node.ForeColor = $palette.Text
  }

  return $node
}

function Populate-DirectoryNode {
  param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.TreeNode]$Node
  )

  $path = [string]$Node.Tag
  $Node.Nodes.Clear()

  try {
    $items = Get-ChildItem -LiteralPath $path -Force | Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name
    foreach ($item in $items) {
      if ($item.Name -in @('.git', 'node_modules', 'dist', 'build')) {
        continue
      }
      [void]$Node.Nodes.Add((New-FileTreeNode -Item $item))
    }
  } catch {
    $errorNode = New-Object System.Windows.Forms.TreeNode('[Unable to read]')
    $errorNode.ForeColor = [System.Drawing.Color]::Firebrick
    [void]$Node.Nodes.Add($errorNode)
  }
}

function Refresh-WorkspaceBrowser {
  try {
    $workspace = Get-WorkspaceOrThrow
    $fileTree.BeginUpdate()
    $fileTree.Nodes.Clear()

    $rootNode = New-Object System.Windows.Forms.TreeNode((Split-Path $workspace -Leaf))
    $rootNode.Tag = $workspace
    $rootNode.ForeColor = $palette.Accent
    Add-PlaceholderNode -Node $rootNode
    [void]$fileTree.Nodes.Add($rootNode)
    Populate-DirectoryNode -Node $rootNode
    $rootNode.Expand()
    Set-StatusText "Loaded workspace browser for $workspace"
  } catch {
    $previewPathLabel.Text = 'Preview'
    $previewBox.Text = "Choose a valid workspace to browse files.`r`n`r`n$($_.Exception.Message)"
    Set-StatusText 'Workspace browser unavailable'
  } finally {
    $fileTree.EndUpdate()
  }
}

function Show-FilePreview {
  param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspacePath,
    [Parameter(Mandatory = $true)]
    [string]$FilePath
  )

  try {
    $item = Get-Item -LiteralPath $FilePath -ErrorAction Stop
    if ($item.PSIsContainer) {
      $previewPathLabel.Text = (Get-BmoRelativePath -WorkspacePath $WorkspacePath -TargetPath $FilePath)
      $children = Get-ChildItem -LiteralPath $FilePath -Force | Select-Object -First 100
      $previewBox.Text = ($children | ForEach-Object {
        if ($_.PSIsContainer) { "[dir]  $($_.Name)" } else { "[file] $($_.Name)" }
      }) -join "`r`n"
      return
    }

    $relative = Get-BmoRelativePath -WorkspacePath $WorkspacePath -TargetPath $FilePath
    $previewPathLabel.Text = $relative
    $content = Read-BmoWorkspaceFile -WorkspacePath $WorkspacePath -RelativePath $relative
    if ($content.Length -gt 12000) {
      $content = $content.Substring(0, 12000) + "`r`n`r`n[Preview truncated]"
    }
    $previewBox.Text = $content
  } catch {
    $previewPathLabel.Text = 'Preview'
    $previewBox.Text = "Unable to preview selection.`r`n`r`n$($_.Exception.Message)"
  }
}

function Get-SelectedTreePath {
  if ($null -eq $fileTree.SelectedNode -or $null -eq $fileTree.SelectedNode.Tag) {
    throw 'Choose a file or folder in the workspace browser first.'
  }
  return [string]$fileTree.SelectedNode.Tag
}

function Submit-Prompt {
  $prompt = $inputBox.Text.Trim()
  if ([string]::IsNullOrWhiteSpace($prompt)) {
    return
  }

  try {
    $workspace = Get-WorkspaceOrThrow
    Add-TranscriptLine -Speaker 'You' -Text $prompt
    Set-StatusText 'BMO is thinking...'
    Write-BmoLog -Category 'prompt' -Message ("workspace={0} prompt={1}" -f $workspace, $prompt)

    if ($prompt.Trim().StartsWith('/unsafe ')) {
      $answer = [System.Windows.Forms.MessageBox]::Show(
        "This will run an unrestricted command inside the chosen workspace.`r`n`r`nContinue?",
        'Approve unsafe command',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
      )
      if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        Add-TranscriptLine -Speaker 'BMO' -Text 'Unsafe command canceled.'
        Set-StatusText 'Canceled'
        Write-BmoLog -Category 'approval' -Message 'Unsafe command denied by user.'
        return
      }
      Write-BmoLog -Category 'approval' -Message 'Unsafe command approved by user.'
    }

    $reply = Invoke-BmoAssistant -Prompt $prompt -WorkspacePath $workspace
    Add-TranscriptLine -Speaker 'BMO' -Text $reply
    $inputBox.Clear()
    Set-StatusText 'Ready'
  } catch {
    Add-TranscriptLine -Speaker 'BMO' -Text "Error: $($_.Exception.Message)"
    Set-StatusText 'Error'
    Write-BmoLog -Category 'error' -Message $_.Exception.Message
  }
}

$browseButton.Add_Click({
  $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
  $dialog.Description = 'Choose the workspace BMO should operate in'
  $dialog.ShowNewFolderButton = $true

  if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $workspaceText.Text = $dialog.SelectedPath
    Refresh-WorkspaceBrowser
    Set-StatusText "Workspace selected: $($dialog.SelectedPath)"
  }
})

$saveButton.Add_Click({
  try {
    Save-WorkspaceSetting
    Refresh-WorkspaceBrowser
    Set-StatusText 'Workspace saved.'
  } catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Save failed')
  }
})

$refreshTreeButton.Add_Click({ Refresh-WorkspaceBrowser })

$readSelectedButton.Add_Click({
  try {
    $workspace = Get-WorkspaceOrThrow
    $selectedPath = Get-SelectedTreePath
    $item = Get-Item -LiteralPath $selectedPath
    if ($item.PSIsContainer) {
      Show-FilePreview -WorkspacePath $workspace -FilePath $selectedPath
    } else {
      $inputBox.Text = "/read $(Get-BmoRelativePath -WorkspacePath $workspace -TargetPath $selectedPath)"
      Submit-Prompt
    }
  } catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Read selected')
  }
})

$insertReadButton.Add_Click({
  try {
    $workspace = Get-WorkspaceOrThrow
    $selectedPath = Get-SelectedTreePath
    $item = Get-Item -LiteralPath $selectedPath
    if ($item.PSIsContainer) {
      throw 'Choose a file, not a folder.'
    }
    $inputBox.Text = "/read $(Get-BmoRelativePath -WorkspacePath $workspace -TargetPath $selectedPath)"
    $inputBox.Focus()
  } catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Insert /read')
  }
})

$fileTree.add_BeforeExpand({
  if ($_.Node.Nodes.Count -eq 1 -and $_.Node.Nodes[0].Text -eq '__placeholder__') {
    Populate-DirectoryNode -Node $_.Node
  }
})

$fileTree.add_AfterSelect({
  try {
    $workspace = Get-WorkspaceOrThrow
    $selectedPath = Get-SelectedTreePath
    Show-FilePreview -WorkspacePath $workspace -FilePath $selectedPath
  } catch {
  }
})

$sendButton.Add_Click({ Submit-Prompt })

$clearButton.Add_Click({
  $transcript.Clear()
  Add-TranscriptLine -Speaker 'BMO' -Text 'Chat cleared. Workspace state and logs are still preserved.'
})

$inputBox.Add_KeyDown({
  if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter -and -not $_.Shift) {
    Submit-Prompt
    $_.SuppressKeyPress = $true
  }
})

$quickStatusButton.Add_Click({
  $inputBox.Text = 'show repo status'
  Submit-Prompt
})

$quickBacklogButton.Add_Click({
  $inputBox.Text = 'show backlog'
  Submit-Prompt
})

$quickRunbookButton.Add_Click({
  $inputBox.Text = 'show startup runbook'
  Submit-Prompt
})

$quickPolicyButton.Add_Click({
  $inputBox.Text = '/policy'
  Submit-Prompt
})

$quickLogsButton.Add_Click({
  try {
    $logsPath = Join-Path (Get-BmoDataRoot) 'logs'
    if (Test-Path $logsPath) {
      Start-Process explorer.exe $logsPath | Out-Null
      Set-StatusText 'Opened logs folder.'
    }
  } catch {
    [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Open logs')
  }
})

Add-TranscriptLine -Speaker 'BMO' -Text @"
BMO Windows Desktop is ready.

What changed in this build:
- a real workspace browser and preview pane
- stronger command allowlists and blocked tokens
- install-aware data storage
- logs and task history under $(Get-BmoDataRoot)
"@

Refresh-WorkspaceBrowser
[void]$form.ShowDialog()
