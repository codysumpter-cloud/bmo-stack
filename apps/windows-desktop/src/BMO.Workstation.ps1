function New-BmoFont {
  param(
    [string]$Name = 'Segoe UI',
    [float]$Size = 9.5,
    [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular
  )

  return New-Object System.Drawing.Font($Name, $Size, $Style)
}

function Get-BmoToolStatusText {
  param(
    [Parameter(Mandatory = $true)]
    [object[]]$ToolStatus
  )

  $lines = @()
  foreach ($tool in $ToolStatus) {
    $status = if ($tool.available) { 'ok' } else { 'missing' }
    $path = if ($tool.available) { $tool.path } else { '-' }
    $lines += ('{0,-12} {1,-8} {2}' -f $tool.name, $status, $path)
  }
  return $lines -join "`r`n"
}

function Invoke-BmoDesktopSmokeTest {
  param(
    [string]$WorkspacePath = ''
  )

  $settings = Initialize-BmoSettings
  $targetWorkspace = $WorkspacePath
  if ([string]::IsNullOrWhiteSpace($targetWorkspace)) {
    if (-not [string]::IsNullOrWhiteSpace($settings.defaultWorkspace) -and (Test-BmoWorkspace -WorkspacePath $settings.defaultWorkspace)) {
      $targetWorkspace = $settings.defaultWorkspace
    } else {
      $targetWorkspace = (Resolve-Path '.').Path
    }
  }

  $resolvedWorkspace = Resolve-BmoWorkspacePath -WorkspacePath $targetWorkspace
  $manifest = Get-BmoDesktopManifest
  $repoInfo = Get-BmoRepoInfo -WorkspacePath $resolvedWorkspace
  $routines = Get-BmoRoutinePack -WorkspacePath $resolvedWorkspace
  $skills = Get-BmoSkillCatalog -WorkspacePath $resolvedWorkspace

  $task = Start-BmoProcessTask -WorkspacePath $resolvedWorkspace -CommandText 'git status --short --branch' -TaskType 'smoke-test' -Title 'Smoke Test: git status'
  $deadline = (Get-Date).AddSeconds(20)
  do {
    Start-Sleep -Milliseconds 250
    Sync-BmoActiveTasks | Out-Null
    $completedTask = Get-BmoTaskRecord -TaskId $task.id
  } while (($completedTask.status -eq 'running' -or $completedTask.status -eq 'queued') -and (Get-Date) -lt $deadline)

  $summary = [pscustomobject][ordered]@{
    workspace = $resolvedWorkspace
    repoRoot = $repoInfo.repoRoot
    isGitRepo = $repoInfo.isGitRepo
    branch = $repoInfo.branch
    manifestVersion = $manifest.version
    routineCount = @($routines.routines).Count
    skillCount = @($skills).Count
    taskId = $task.id
    taskStatus = $completedTask.status
    taskExitCode = $completedTask.exitCode
    taskOutput = Get-BmoTaskOutput -TaskId $task.id
  }

  return ($summary | ConvertTo-Json -Depth 6)
}

function Start-BmoDesktopApp {
  param(
    [string]$InitialWorkspace = ''
  )

  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.Drawing
  Add-Type -AssemblyName Microsoft.VisualBasic

  $settings = Initialize-BmoSettings

  $initial = $InitialWorkspace
  if ([string]::IsNullOrWhiteSpace($initial)) {
    $initial = $settings.defaultWorkspace
  }
  if ([string]::IsNullOrWhiteSpace($initial) -or -not (Test-BmoWorkspace -WorkspacePath $initial)) {
    $initial = (Resolve-Path '.').Path
  }

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
    Danger = [System.Drawing.Color]::Firebrick
  }

  $state = [ordered]@{
    workspace = (Resolve-BmoWorkspacePath -WorkspacePath $initial)
    currentFileRelative = ''
    currentFileOriginal = ''
    loadingFile = $false
    diffMode = 'worktree'
  }

  $form = New-Object System.Windows.Forms.Form
  $form.Text = 'BMO Workstation'
  $form.Width = 1460
  $form.Height = 960
  $form.StartPosition = 'CenterScreen'
  $form.MinimumSize = New-Object System.Drawing.Size(1220, 820)
  $form.BackColor = $palette.Window

  $headerPanel = New-Object System.Windows.Forms.Panel
  $headerPanel.Dock = 'Top'
  $headerPanel.Height = 90
  $headerPanel.BackColor = $palette.PanelStrong
  $headerPanel.Padding = New-Object System.Windows.Forms.Padding(16, 12, 16, 12)

  $titleLabel = New-Object System.Windows.Forms.Label
  $titleLabel.Text = 'BMO Workstation'
  $titleLabel.Font = New-BmoFont -Size 18 -Style Bold
  $titleLabel.ForeColor = $palette.Accent
  $titleLabel.AutoSize = $true
  $titleLabel.Location = New-Object System.Drawing.Point(16, 10)

  $subtitleLabel = New-Object System.Windows.Forms.Label
  $subtitleLabel.Text = 'Local BMO command center for repo supervision, safe execution, validation, skills, and source control.'
  $subtitleLabel.Font = New-BmoFont -Size 9.5
  $subtitleLabel.ForeColor = $palette.Muted
  $subtitleLabel.AutoSize = $true
  $subtitleLabel.Location = New-Object System.Drawing.Point(18, 42)

  $workspaceLabel = New-Object System.Windows.Forms.Label
  $workspaceLabel.Text = 'Workspace'
  $workspaceLabel.Font = New-BmoFont -Size 9.5 -Style Bold
  $workspaceLabel.ForeColor = $palette.Text
  $workspaceLabel.AutoSize = $true
  $workspaceLabel.Location = New-Object System.Drawing.Point(700, 16)

  $workspaceCombo = New-Object System.Windows.Forms.ComboBox
  $workspaceCombo.Left = 780
  $workspaceCombo.Top = 12
  $workspaceCombo.Width = 460
  $workspaceCombo.DropDownStyle = 'DropDown'
  $workspaceCombo.Font = New-BmoFont -Size 9.5

  $browseButton = New-Object System.Windows.Forms.Button
  $browseButton.Text = 'Browse'
  $browseButton.Left = 1250
  $browseButton.Top = 10
  $browseButton.Width = 88
  $browseButton.Height = 28
  $browseButton.BackColor = $palette.Accent
  $browseButton.ForeColor = $palette.White
  $browseButton.FlatStyle = 'Flat'

  $saveWorkspaceButton = New-Object System.Windows.Forms.Button
  $saveWorkspaceButton.Text = 'Save'
  $saveWorkspaceButton.Left = 1250
  $saveWorkspaceButton.Top = 44
  $saveWorkspaceButton.Width = 88
  $saveWorkspaceButton.Height = 26
  $saveWorkspaceButton.BackColor = $palette.Panel
  $saveWorkspaceButton.ForeColor = $palette.Text
  $saveWorkspaceButton.FlatStyle = 'Flat'

  $refreshAllButton = New-Object System.Windows.Forms.Button
  $refreshAllButton.Text = 'Refresh'
  $refreshAllButton.Left = 1346
  $refreshAllButton.Top = 10
  $refreshAllButton.Width = 88
  $refreshAllButton.Height = 28
  $refreshAllButton.BackColor = $palette.Panel
  $refreshAllButton.ForeColor = $palette.Text
  $refreshAllButton.FlatStyle = 'Flat'

  $openLogsButton = New-Object System.Windows.Forms.Button
  $openLogsButton.Text = 'Open Logs'
  $openLogsButton.Left = 1346
  $openLogsButton.Top = 44
  $openLogsButton.Width = 88
  $openLogsButton.Height = 26
  $openLogsButton.BackColor = $palette.Panel
  $openLogsButton.ForeColor = $palette.Text
  $openLogsButton.FlatStyle = 'Flat'

  [void]$headerPanel.Controls.Add($titleLabel)
  [void]$headerPanel.Controls.Add($subtitleLabel)
  [void]$headerPanel.Controls.Add($workspaceLabel)
  [void]$headerPanel.Controls.Add($workspaceCombo)
  [void]$headerPanel.Controls.Add($browseButton)
  [void]$headerPanel.Controls.Add($saveWorkspaceButton)
  [void]$headerPanel.Controls.Add($refreshAllButton)
  [void]$headerPanel.Controls.Add($openLogsButton)

  $tabControl = New-Object System.Windows.Forms.TabControl
  $tabControl.Dock = 'Fill'
  $tabControl.Font = New-BmoFont -Size 9.5

  $dashboardTab = New-Object System.Windows.Forms.TabPage('Dashboard')
  $filesTab = New-Object System.Windows.Forms.TabPage('Files')
  $sourceControlTab = New-Object System.Windows.Forms.TabPage('Source Control')
  $tasksTab = New-Object System.Windows.Forms.TabPage('Tasks')
  $operationsTab = New-Object System.Windows.Forms.TabPage('Operations')

  [void]$tabControl.TabPages.Add($dashboardTab)
  [void]$tabControl.TabPages.Add($filesTab)
  [void]$tabControl.TabPages.Add($sourceControlTab)
  [void]$tabControl.TabPages.Add($tasksTab)
  [void]$tabControl.TabPages.Add($operationsTab)

  $statusBar = New-Object System.Windows.Forms.StatusStrip
  $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
  $statusLabel.Text = 'Ready'
  $repoStatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
  $repoStatusLabel.Text = 'Repo: unknown'
  $taskStatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
  $taskStatusLabel.Text = 'Tasks: 0'
  [void]$statusBar.Items.Add($statusLabel)
  [void]$statusBar.Items.Add((New-Object System.Windows.Forms.ToolStripStatusLabel('   ')))
  [void]$statusBar.Items.Add($repoStatusLabel)
  [void]$statusBar.Items.Add((New-Object System.Windows.Forms.ToolStripStatusLabel('   ')))
  [void]$statusBar.Items.Add($taskStatusLabel)

  [void]$form.Controls.Add($tabControl)
  [void]$form.Controls.Add($headerPanel)
  [void]$form.Controls.Add($statusBar)

  $dashboardSplit = New-Object System.Windows.Forms.SplitContainer
  $dashboardSplit.Dock = 'Fill'
  $dashboardSplit.Orientation = 'Horizontal'
  $dashboardSplit.SplitterDistance = 300

  $dashboardTop = New-Object System.Windows.Forms.SplitContainer
  $dashboardTop.Dock = 'Fill'
  $dashboardTop.SplitterDistance = 720

  $overviewBox = New-Object System.Windows.Forms.RichTextBox
  $overviewBox.Dock = 'Fill'
  $overviewBox.ReadOnly = $true
  $overviewBox.Font = New-BmoFont -Name 'Consolas' -Size 9.5
  $overviewBox.BackColor = $palette.White

  $commandPanel = New-Object System.Windows.Forms.Panel
  $commandPanel.Dock = 'Fill'
  $commandPanel.BackColor = $palette.Panel
  $commandPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $commandLabel = New-Object System.Windows.Forms.Label
  $commandLabel.Text = 'Command Preview'
  $commandLabel.Font = New-BmoFont -Size 11 -Style Bold
  $commandLabel.ForeColor = $palette.Accent
  $commandLabel.AutoSize = $true
  $commandLabel.Location = New-Object System.Drawing.Point(10, 8)

  $commandInputBox = New-Object System.Windows.Forms.TextBox
  $commandInputBox.Left = 10
  $commandInputBox.Top = 38
  $commandInputBox.Width = 620
  $commandInputBox.Font = New-BmoFont -Name 'Consolas' -Size 9.5

  $previewCommandButton = New-Object System.Windows.Forms.Button
  $previewCommandButton.Text = 'Preview'
  $previewCommandButton.Left = 638
  $previewCommandButton.Top = 36
  $previewCommandButton.Width = 96
  $previewCommandButton.FlatStyle = 'Flat'

  $runCommandButton = New-Object System.Windows.Forms.Button
  $runCommandButton.Text = 'Run'
  $runCommandButton.Left = 638
  $runCommandButton.Top = 68
  $runCommandButton.Width = 96
  $runCommandButton.BackColor = $palette.Accent
  $runCommandButton.ForeColor = $palette.White
  $runCommandButton.FlatStyle = 'Flat'

  $commandPreviewBox = New-Object System.Windows.Forms.RichTextBox
  $commandPreviewBox.Left = 10
  $commandPreviewBox.Top = 74
  $commandPreviewBox.Width = 620
  $commandPreviewBox.Height = 180
  $commandPreviewBox.ReadOnly = $true
  $commandPreviewBox.Font = New-BmoFont -Name 'Consolas' -Size 9
  $commandPreviewBox.BackColor = $palette.White

  [void]$commandPanel.Controls.Add($commandLabel)
  [void]$commandPanel.Controls.Add($commandInputBox)
  [void]$commandPanel.Controls.Add($previewCommandButton)
  [void]$commandPanel.Controls.Add($runCommandButton)
  [void]$commandPanel.Controls.Add($commandPreviewBox)

  [void]$dashboardTop.Panel1.Controls.Add($overviewBox)
  [void]$dashboardTop.Panel2.Controls.Add($commandPanel)

  $transcript = New-Object System.Windows.Forms.RichTextBox
  $transcript.Dock = 'Fill'
  $transcript.ReadOnly = $true
  $transcript.Font = New-BmoFont -Name 'Consolas' -Size 10
  $transcript.BackColor = $palette.White

  $composerPanel = New-Object System.Windows.Forms.Panel
  $composerPanel.Dock = 'Bottom'
  $composerPanel.Height = 140
  $composerPanel.Padding = New-Object System.Windows.Forms.Padding(10)
  $composerPanel.BackColor = $palette.Panel

  $promptHintLabel = New-Object System.Windows.Forms.Label
  $promptHintLabel.Text = 'Ask BMO for local repo context, use /read, /cmd, /unsafe, or /tasks, and keep the real task log in view.'
  $promptHintLabel.AutoSize = $true
  $promptHintLabel.ForeColor = $palette.Muted
  $promptHintLabel.Location = New-Object System.Drawing.Point(10, 8)

  $promptInputBox = New-Object System.Windows.Forms.TextBox
  $promptInputBox.Left = 10
  $promptInputBox.Top = 32
  $promptInputBox.Width = 1080
  $promptInputBox.Height = 84
  $promptInputBox.Multiline = $true
  $promptInputBox.AcceptsReturn = $true
  $promptInputBox.Font = New-BmoFont -Size 10

  $sendPromptButton = New-Object System.Windows.Forms.Button
  $sendPromptButton.Text = 'Send'
  $sendPromptButton.Left = 1104
  $sendPromptButton.Top = 32
  $sendPromptButton.Width = 96
  $sendPromptButton.Height = 36
  $sendPromptButton.BackColor = $palette.Accent
  $sendPromptButton.ForeColor = $palette.White
  $sendPromptButton.FlatStyle = 'Flat'

  $clearTranscriptButton = New-Object System.Windows.Forms.Button
  $clearTranscriptButton.Text = 'Clear'
  $clearTranscriptButton.Left = 1104
  $clearTranscriptButton.Top = 78
  $clearTranscriptButton.Width = 96
  $clearTranscriptButton.Height = 36
  $clearTranscriptButton.FlatStyle = 'Flat'

  [void]$composerPanel.Controls.Add($promptHintLabel)
  [void]$composerPanel.Controls.Add($promptInputBox)
  [void]$composerPanel.Controls.Add($sendPromptButton)
  [void]$composerPanel.Controls.Add($clearTranscriptButton)

  [void]$dashboardSplit.Panel1.Controls.Add($dashboardTop)
  [void]$dashboardSplit.Panel2.Controls.Add($transcript)
  [void]$dashboardSplit.Panel2.Controls.Add($composerPanel)
  [void]$dashboardTab.Controls.Add($dashboardSplit)

  $filesSplit = New-Object System.Windows.Forms.SplitContainer
  $filesSplit.Dock = 'Fill'
  $filesSplit.SplitterDistance = 380

  $fileTreePanel = New-Object System.Windows.Forms.Panel
  $fileTreePanel.Dock = 'Fill'
  $fileTreePanel.Padding = New-Object System.Windows.Forms.Padding(10)
  $fileTreePanel.BackColor = $palette.Panel

  $refreshTreeButton = New-Object System.Windows.Forms.Button
  $refreshTreeButton.Text = 'Refresh'
  $refreshTreeButton.Left = 10
  $refreshTreeButton.Top = 10
  $refreshTreeButton.Width = 90
  $refreshTreeButton.FlatStyle = 'Flat'

  $insertReadButton = New-Object System.Windows.Forms.Button
  $insertReadButton.Text = 'Insert /read'
  $insertReadButton.Left = 108
  $insertReadButton.Top = 10
  $insertReadButton.Width = 102
  $insertReadButton.FlatStyle = 'Flat'

  $openFileExternalButton = New-Object System.Windows.Forms.Button
  $openFileExternalButton.Text = 'Open External'
  $openFileExternalButton.Left = 218
  $openFileExternalButton.Top = 10
  $openFileExternalButton.Width = 112
  $openFileExternalButton.FlatStyle = 'Flat'

  $newFileButton = New-Object System.Windows.Forms.Button
  $newFileButton.Text = 'New File'
  $newFileButton.Left = 10
  $newFileButton.Top = 42
  $newFileButton.Width = 90
  $newFileButton.FlatStyle = 'Flat'

  $newFolderButton = New-Object System.Windows.Forms.Button
  $newFolderButton.Text = 'New Folder'
  $newFolderButton.Left = 108
  $newFolderButton.Top = 42
  $newFolderButton.Width = 102
  $newFolderButton.FlatStyle = 'Flat'

  $fileTree = New-Object System.Windows.Forms.TreeView
  $fileTree.Left = 10
  $fileTree.Top = 78
  $fileTree.Width = 350
  $fileTree.Height = 730
  $fileTree.Font = New-BmoFont -Size 9.5

  [void]$fileTreePanel.Controls.Add($refreshTreeButton)
  [void]$fileTreePanel.Controls.Add($insertReadButton)
  [void]$fileTreePanel.Controls.Add($openFileExternalButton)
  [void]$fileTreePanel.Controls.Add($newFileButton)
  [void]$fileTreePanel.Controls.Add($newFolderButton)
  [void]$fileTreePanel.Controls.Add($fileTree)

  $editorPanel = New-Object System.Windows.Forms.Panel
  $editorPanel.Dock = 'Fill'
  $editorPanel.Padding = New-Object System.Windows.Forms.Padding(10)
  $editorPanel.BackColor = $palette.Window

  $filePathLabel = New-Object System.Windows.Forms.Label
  $filePathLabel.Text = 'No file selected.'
  $filePathLabel.Font = New-BmoFont -Size 10 -Style Bold
  $filePathLabel.ForeColor = $palette.Text
  $filePathLabel.AutoSize = $true
  $filePathLabel.Location = New-Object System.Drawing.Point(10, 10)

  $saveFileButton = New-Object System.Windows.Forms.Button
  $saveFileButton.Text = 'Save'
  $saveFileButton.Left = 760
  $saveFileButton.Top = 6
  $saveFileButton.Width = 80
  $saveFileButton.FlatStyle = 'Flat'
  $saveFileButton.Enabled = $false

  $revertFileButton = New-Object System.Windows.Forms.Button
  $revertFileButton.Text = 'Revert'
  $revertFileButton.Left = 848
  $revertFileButton.Top = 6
  $revertFileButton.Width = 80
  $revertFileButton.FlatStyle = 'Flat'
  $revertFileButton.Enabled = $false

  $fileEditor = New-Object System.Windows.Forms.RichTextBox
  $fileEditor.Left = 10
  $fileEditor.Top = 40
  $fileEditor.Width = 920
  $fileEditor.Height = 768
  $fileEditor.Font = New-BmoFont -Name 'Consolas' -Size 10
  $fileEditor.BackColor = $palette.White

  [void]$editorPanel.Controls.Add($filePathLabel)
  [void]$editorPanel.Controls.Add($saveFileButton)
  [void]$editorPanel.Controls.Add($revertFileButton)
  [void]$editorPanel.Controls.Add($fileEditor)

  [void]$filesSplit.Panel1.Controls.Add($fileTreePanel)
  [void]$filesSplit.Panel2.Controls.Add($editorPanel)
  [void]$filesTab.Controls.Add($filesSplit)

  $sourceSplit = New-Object System.Windows.Forms.SplitContainer
  $sourceSplit.Dock = 'Fill'
  $sourceSplit.SplitterDistance = 500

  $sourceLeft = New-Object System.Windows.Forms.SplitContainer
  $sourceLeft.Dock = 'Fill'
  $sourceLeft.Orientation = 'Horizontal'
  $sourceLeft.SplitterDistance = 430

  $changesPanel = New-Object System.Windows.Forms.Panel
  $changesPanel.Dock = 'Fill'
  $changesPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $refreshRepoButton = New-Object System.Windows.Forms.Button
  $refreshRepoButton.Text = 'Refresh'
  $refreshRepoButton.Left = 10
  $refreshRepoButton.Top = 10
  $refreshRepoButton.Width = 78
  $refreshRepoButton.FlatStyle = 'Flat'

  $worktreeDiffButton = New-Object System.Windows.Forms.Button
  $worktreeDiffButton.Text = 'Worktree Diff'
  $worktreeDiffButton.Left = 96
  $worktreeDiffButton.Top = 10
  $worktreeDiffButton.Width = 98
  $worktreeDiffButton.FlatStyle = 'Flat'

  $stagedDiffButton = New-Object System.Windows.Forms.Button
  $stagedDiffButton.Text = 'Staged Diff'
  $stagedDiffButton.Left = 202
  $stagedDiffButton.Top = 10
  $stagedDiffButton.Width = 88
  $stagedDiffButton.FlatStyle = 'Flat'

  $openChangedFileButton = New-Object System.Windows.Forms.Button
  $openChangedFileButton.Text = 'Open File'
  $openChangedFileButton.Left = 298
  $openChangedFileButton.Top = 10
  $openChangedFileButton.Width = 82
  $openChangedFileButton.FlatStyle = 'Flat'

  $copyChangeSummaryButton = New-Object System.Windows.Forms.Button
  $copyChangeSummaryButton.Text = 'Copy Prep'
  $copyChangeSummaryButton.Left = 388
  $copyChangeSummaryButton.Top = 10
  $copyChangeSummaryButton.Width = 92
  $copyChangeSummaryButton.FlatStyle = 'Flat'

  $stageSelectedButton = New-Object System.Windows.Forms.Button
  $stageSelectedButton.Text = 'Stage Selected'
  $stageSelectedButton.Left = 10
  $stageSelectedButton.Top = 44
  $stageSelectedButton.Width = 110
  $stageSelectedButton.FlatStyle = 'Flat'

  $unstageSelectedButton = New-Object System.Windows.Forms.Button
  $unstageSelectedButton.Text = 'Unstage Selected'
  $unstageSelectedButton.Left = 128
  $unstageSelectedButton.Top = 44
  $unstageSelectedButton.Width = 118
  $unstageSelectedButton.FlatStyle = 'Flat'

  $stageAllButton = New-Object System.Windows.Forms.Button
  $stageAllButton.Text = 'Stage All'
  $stageAllButton.Left = 254
  $stageAllButton.Top = 44
  $stageAllButton.Width = 88
  $stageAllButton.FlatStyle = 'Flat'

  $unstageAllButton = New-Object System.Windows.Forms.Button
  $unstageAllButton.Text = 'Unstage All'
  $unstageAllButton.Left = 350
  $unstageAllButton.Top = 44
  $unstageAllButton.Width = 96
  $unstageAllButton.FlatStyle = 'Flat'

  $changedFilesList = New-Object System.Windows.Forms.ListView
  $changedFilesList.Left = 10
  $changedFilesList.Top = 80
  $changedFilesList.Width = 470
  $changedFilesList.Height = 328
  $changedFilesList.View = 'Details'
  $changedFilesList.FullRowSelect = $true
  $changedFilesList.GridLines = $true
  [void]$changedFilesList.Columns.Add('Path', 320)
  [void]$changedFilesList.Columns.Add('Summary', 130)

  [void]$changesPanel.Controls.Add($refreshRepoButton)
  [void]$changesPanel.Controls.Add($worktreeDiffButton)
  [void]$changesPanel.Controls.Add($stagedDiffButton)
  [void]$changesPanel.Controls.Add($openChangedFileButton)
  [void]$changesPanel.Controls.Add($copyChangeSummaryButton)
  [void]$changesPanel.Controls.Add($stageSelectedButton)
  [void]$changesPanel.Controls.Add($unstageSelectedButton)
  [void]$changesPanel.Controls.Add($stageAllButton)
  [void]$changesPanel.Controls.Add($unstageAllButton)
  [void]$changesPanel.Controls.Add($changedFilesList)

  $worktreePanel = New-Object System.Windows.Forms.Panel
  $worktreePanel.Dock = 'Fill'
  $worktreePanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $useWorktreeButton = New-Object System.Windows.Forms.Button
  $useWorktreeButton.Text = 'Use Selected Worktree'
  $useWorktreeButton.Left = 10
  $useWorktreeButton.Top = 10
  $useWorktreeButton.Width = 150
  $useWorktreeButton.FlatStyle = 'Flat'

  $worktreesList = New-Object System.Windows.Forms.ListView
  $worktreesList.Left = 10
  $worktreesList.Top = 48
  $worktreesList.Width = 470
  $worktreesList.Height = 150
  $worktreesList.View = 'Details'
  $worktreesList.FullRowSelect = $true
  $worktreesList.GridLines = $true
  [void]$worktreesList.Columns.Add('Branch', 120)
  [void]$worktreesList.Columns.Add('Path', 330)

  $copyCommitPrepButton = New-Object System.Windows.Forms.Button
  $copyCommitPrepButton.Text = 'Copy Commit Prep'
  $copyCommitPrepButton.Left = 10
  $copyCommitPrepButton.Top = 208
  $copyCommitPrepButton.Width = 120
  $copyCommitPrepButton.FlatStyle = 'Flat'

  $commitStagedButton = New-Object System.Windows.Forms.Button
  $commitStagedButton.Text = 'Commit Staged'
  $commitStagedButton.Left = 138
  $commitStagedButton.Top = 208
  $commitStagedButton.Width = 104
  $commitStagedButton.FlatStyle = 'Flat'

  $commitMessageLabel = New-Object System.Windows.Forms.Label
  $commitMessageLabel.Text = 'Commit message'
  $commitMessageLabel.AutoSize = $true
  $commitMessageLabel.Left = 10
  $commitMessageLabel.Top = 244

  $commitMessageBox = New-Object System.Windows.Forms.TextBox
  $commitMessageBox.Left = 10
  $commitMessageBox.Top = 266
  $commitMessageBox.Width = 470
  $commitMessageBox.Height = 70
  $commitMessageBox.Multiline = $true
  $commitMessageBox.Font = New-BmoFont -Size 9.5

  $recentCommitsLabel = New-Object System.Windows.Forms.Label
  $recentCommitsLabel.Text = 'Recent commits'
  $recentCommitsLabel.AutoSize = $true
  $recentCommitsLabel.Left = 10
  $recentCommitsLabel.Top = 346

  $recentCommitsBox = New-Object System.Windows.Forms.RichTextBox
  $recentCommitsBox.Left = 10
  $recentCommitsBox.Top = 368
  $recentCommitsBox.Width = 470
  $recentCommitsBox.Height = 110
  $recentCommitsBox.ReadOnly = $true
  $recentCommitsBox.Font = New-BmoFont -Name 'Consolas' -Size 9
  $recentCommitsBox.BackColor = $palette.White

  [void]$worktreePanel.Controls.Add($useWorktreeButton)
  [void]$worktreePanel.Controls.Add($worktreesList)
  [void]$worktreePanel.Controls.Add($copyCommitPrepButton)
  [void]$worktreePanel.Controls.Add($commitStagedButton)
  [void]$worktreePanel.Controls.Add($commitMessageLabel)
  [void]$worktreePanel.Controls.Add($commitMessageBox)
  [void]$worktreePanel.Controls.Add($recentCommitsLabel)
  [void]$worktreePanel.Controls.Add($recentCommitsBox)

  [void]$sourceLeft.Panel1.Controls.Add($changesPanel)
  [void]$sourceLeft.Panel2.Controls.Add($worktreePanel)

  $diffPanel = New-Object System.Windows.Forms.Panel
  $diffPanel.Dock = 'Fill'
  $diffPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $repoSummaryLabel = New-Object System.Windows.Forms.Label
  $repoSummaryLabel.Text = 'Repo summary unavailable.'
  $repoSummaryLabel.AutoSize = $true
  $repoSummaryLabel.Location = New-Object System.Drawing.Point(10, 10)

  $diffView = New-Object System.Windows.Forms.RichTextBox
  $diffView.Left = 10
  $diffView.Top = 40
  $diffView.Width = 900
  $diffView.Height = 760
  $diffView.ReadOnly = $true
  $diffView.Font = New-BmoFont -Name 'Consolas' -Size 9.5
  $diffView.BackColor = $palette.White

  [void]$diffPanel.Controls.Add($repoSummaryLabel)
  [void]$diffPanel.Controls.Add($diffView)

  [void]$sourceSplit.Panel1.Controls.Add($sourceLeft)
  [void]$sourceSplit.Panel2.Controls.Add($diffPanel)
  [void]$sourceControlTab.Controls.Add($sourceSplit)

  $tasksSplit = New-Object System.Windows.Forms.SplitContainer
  $tasksSplit.Dock = 'Fill'
  $tasksSplit.SplitterDistance = 560

  $tasksListPanel = New-Object System.Windows.Forms.Panel
  $tasksListPanel.Dock = 'Fill'
  $tasksListPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $refreshTasksButton = New-Object System.Windows.Forms.Button
  $refreshTasksButton.Text = 'Refresh'
  $refreshTasksButton.Left = 10
  $refreshTasksButton.Top = 10
  $refreshTasksButton.Width = 88
  $refreshTasksButton.FlatStyle = 'Flat'

  $cancelTaskButton = New-Object System.Windows.Forms.Button
  $cancelTaskButton.Text = 'Cancel'
  $cancelTaskButton.Left = 106
  $cancelTaskButton.Top = 10
  $cancelTaskButton.Width = 88
  $cancelTaskButton.FlatStyle = 'Flat'

  $rerunTaskButton = New-Object System.Windows.Forms.Button
  $rerunTaskButton.Text = 'Rerun'
  $rerunTaskButton.Left = 202
  $rerunTaskButton.Top = 10
  $rerunTaskButton.Width = 88
  $rerunTaskButton.FlatStyle = 'Flat'

  $copyTaskOutputButton = New-Object System.Windows.Forms.Button
  $copyTaskOutputButton.Text = 'Copy Output'
  $copyTaskOutputButton.Left = 298
  $copyTaskOutputButton.Top = 10
  $copyTaskOutputButton.Width = 96
  $copyTaskOutputButton.FlatStyle = 'Flat'

  $tasksList = New-Object System.Windows.Forms.ListView
  $tasksList.Left = 10
  $tasksList.Top = 48
  $tasksList.Width = 530
  $tasksList.Height = 760
  $tasksList.View = 'Details'
  $tasksList.FullRowSelect = $true
  $tasksList.GridLines = $true
  [void]$tasksList.Columns.Add('Status', 90)
  [void]$tasksList.Columns.Add('Type', 110)
  [void]$tasksList.Columns.Add('By', 80)
  [void]$tasksList.Columns.Add('Started', 130)
  [void]$tasksList.Columns.Add('Title', 260)

  [void]$tasksListPanel.Controls.Add($refreshTasksButton)
  [void]$tasksListPanel.Controls.Add($cancelTaskButton)
  [void]$tasksListPanel.Controls.Add($rerunTaskButton)
  [void]$tasksListPanel.Controls.Add($copyTaskOutputButton)
  [void]$tasksListPanel.Controls.Add($tasksList)

  $taskOutputPanel = New-Object System.Windows.Forms.Panel
  $taskOutputPanel.Dock = 'Fill'
  $taskOutputPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $taskOutputLabel = New-Object System.Windows.Forms.Label
  $taskOutputLabel.Text = 'Select a task to inspect logs and exact output.'
  $taskOutputLabel.AutoSize = $true
  $taskOutputLabel.Location = New-Object System.Drawing.Point(10, 10)

  $taskOutputBox = New-Object System.Windows.Forms.RichTextBox
  $taskOutputBox.Left = 10
  $taskOutputBox.Top = 40
  $taskOutputBox.Width = 830
  $taskOutputBox.Height = 768
  $taskOutputBox.ReadOnly = $true
  $taskOutputBox.Font = New-BmoFont -Name 'Consolas' -Size 9.5
  $taskOutputBox.BackColor = $palette.White

  [void]$taskOutputPanel.Controls.Add($taskOutputLabel)
  [void]$taskOutputPanel.Controls.Add($taskOutputBox)

  [void]$tasksSplit.Panel1.Controls.Add($tasksListPanel)
  [void]$tasksSplit.Panel2.Controls.Add($taskOutputPanel)
  [void]$tasksTab.Controls.Add($tasksSplit)

  $operationsTopPanel = New-Object System.Windows.Forms.Panel
  $operationsTopPanel.Dock = 'Top'
  $operationsTopPanel.Height = 160
  $operationsTopPanel.Padding = New-Object System.Windows.Forms.Padding(10)
  $operationsTopPanel.BackColor = $palette.Panel

  $healthBox = New-Object System.Windows.Forms.RichTextBox
  $healthBox.Left = 10
  $healthBox.Top = 10
  $healthBox.Width = 760
  $healthBox.Height = 130
  $healthBox.ReadOnly = $true
  $healthBox.Font = New-BmoFont -Name 'Consolas' -Size 9.25
  $healthBox.BackColor = $palette.White

  $profileLabel = New-Object System.Windows.Forms.Label
  $profileLabel.Text = 'Preferred runtime profile'
  $profileLabel.AutoSize = $true
  $profileLabel.Left = 790
  $profileLabel.Top = 16

  $profileCombo = New-Object System.Windows.Forms.ComboBox
  $profileCombo.Left = 790
  $profileCombo.Top = 40
  $profileCombo.Width = 220
  $profileCombo.DropDownStyle = 'DropDownList'

  $applyProfileButton = New-Object System.Windows.Forms.Button
  $applyProfileButton.Text = 'Apply Profile'
  $applyProfileButton.Left = 1020
  $applyProfileButton.Top = 38
  $applyProfileButton.Width = 110
  $applyProfileButton.FlatStyle = 'Flat'

  [void]$operationsTopPanel.Controls.Add($healthBox)
  [void]$operationsTopPanel.Controls.Add($profileLabel)
  [void]$operationsTopPanel.Controls.Add($profileCombo)
  [void]$operationsTopPanel.Controls.Add($applyProfileButton)

  $operationsTabs = New-Object System.Windows.Forms.TabControl
  $operationsTabs.Dock = 'Fill'

  $routinesTab = New-Object System.Windows.Forms.TabPage('Routines')
  $skillsTab = New-Object System.Windows.Forms.TabPage('Skills')
  $validationTab = New-Object System.Windows.Forms.TabPage('Validation')
  $docsTab = New-Object System.Windows.Forms.TabPage('Docs')
  $settingsTab = New-Object System.Windows.Forms.TabPage('Settings')

  [void]$operationsTabs.TabPages.Add($routinesTab)
  [void]$operationsTabs.TabPages.Add($skillsTab)
  [void]$operationsTabs.TabPages.Add($validationTab)
  [void]$operationsTabs.TabPages.Add($docsTab)
  [void]$operationsTabs.TabPages.Add($settingsTab)

  $routinesSplit = New-Object System.Windows.Forms.SplitContainer
  $routinesSplit.Dock = 'Fill'
  $routinesSplit.SplitterDistance = 520

  $routinesList = New-Object System.Windows.Forms.ListView
  $routinesList.Dock = 'Fill'
  $routinesList.View = 'Details'
  $routinesList.FullRowSelect = $true
  $routinesList.GridLines = $true
  [void]$routinesList.Columns.Add('Routine', 180)
  [void]$routinesList.Columns.Add('Ready', 70)
  [void]$routinesList.Columns.Add('Last', 70)
  [void]$routinesList.Columns.Add('Command', 180)

  $routineDetailPanel = New-Object System.Windows.Forms.Panel
  $routineDetailPanel.Dock = 'Fill'
  $routineDetailPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $runRoutineButton = New-Object System.Windows.Forms.Button
  $runRoutineButton.Text = 'Run Routine'
  $runRoutineButton.Left = 10
  $runRoutineButton.Top = 10
  $runRoutineButton.Width = 100
  $runRoutineButton.FlatStyle = 'Flat'

  $copyRoutineCommandButton = New-Object System.Windows.Forms.Button
  $copyRoutineCommandButton.Text = 'Copy Command'
  $copyRoutineCommandButton.Left = 118
  $copyRoutineCommandButton.Top = 10
  $copyRoutineCommandButton.Width = 110
  $copyRoutineCommandButton.FlatStyle = 'Flat'

  $routineDetailsBox = New-Object System.Windows.Forms.RichTextBox
  $routineDetailsBox.Left = 10
  $routineDetailsBox.Top = 46
  $routineDetailsBox.Width = 720
  $routineDetailsBox.Height = 530
  $routineDetailsBox.ReadOnly = $true
  $routineDetailsBox.Font = New-BmoFont -Name 'Consolas' -Size 9.25

  [void]$routineDetailPanel.Controls.Add($runRoutineButton)
  [void]$routineDetailPanel.Controls.Add($copyRoutineCommandButton)
  [void]$routineDetailPanel.Controls.Add($routineDetailsBox)
  [void]$routinesSplit.Panel1.Controls.Add($routinesList)
  [void]$routinesSplit.Panel2.Controls.Add($routineDetailPanel)
  [void]$routinesTab.Controls.Add($routinesSplit)

  $skillsSplit = New-Object System.Windows.Forms.SplitContainer
  $skillsSplit.Dock = 'Fill'
  $skillsSplit.SplitterDistance = 520

  $skillsList = New-Object System.Windows.Forms.ListView
  $skillsList.Dock = 'Fill'
  $skillsList.View = 'Details'
  $skillsList.FullRowSelect = $true
  $skillsList.GridLines = $true
  [void]$skillsList.Columns.Add('Skill', 200)
  [void]$skillsList.Columns.Add('Ready', 80)
  [void]$skillsList.Columns.Add('Command', 230)

  $skillDetailPanel = New-Object System.Windows.Forms.Panel
  $skillDetailPanel.Dock = 'Fill'
  $skillDetailPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $runSkillButton = New-Object System.Windows.Forms.Button
  $runSkillButton.Text = 'Run Suggested'
  $runSkillButton.Left = 10
  $runSkillButton.Top = 10
  $runSkillButton.Width = 110
  $runSkillButton.FlatStyle = 'Flat'

  $openSkillDocButton = New-Object System.Windows.Forms.Button
  $openSkillDocButton.Text = 'Open Doc'
  $openSkillDocButton.Left = 128
  $openSkillDocButton.Top = 10
  $openSkillDocButton.Width = 90
  $openSkillDocButton.FlatStyle = 'Flat'

  $skillDetailsBox = New-Object System.Windows.Forms.RichTextBox
  $skillDetailsBox.Left = 10
  $skillDetailsBox.Top = 46
  $skillDetailsBox.Width = 720
  $skillDetailsBox.Height = 530
  $skillDetailsBox.ReadOnly = $true
  $skillDetailsBox.Font = New-BmoFont -Name 'Consolas' -Size 9.25

  [void]$skillDetailPanel.Controls.Add($runSkillButton)
  [void]$skillDetailPanel.Controls.Add($openSkillDocButton)
  [void]$skillDetailPanel.Controls.Add($skillDetailsBox)
  [void]$skillsSplit.Panel1.Controls.Add($skillsList)
  [void]$skillsSplit.Panel2.Controls.Add($skillDetailPanel)
  [void]$skillsTab.Controls.Add($skillsSplit)

  $validationSplit = New-Object System.Windows.Forms.SplitContainer
  $validationSplit.Dock = 'Fill'
  $validationSplit.SplitterDistance = 520

  $validationList = New-Object System.Windows.Forms.ListView
  $validationList.Dock = 'Fill'
  $validationList.View = 'Details'
  $validationList.FullRowSelect = $true
  $validationList.GridLines = $true
  [void]$validationList.Columns.Add('Validation', 220)
  [void]$validationList.Columns.Add('Ready', 80)
  [void]$validationList.Columns.Add('Last', 80)
  [void]$validationList.Columns.Add('Command', 200)

  $validationDetailPanel = New-Object System.Windows.Forms.Panel
  $validationDetailPanel.Dock = 'Fill'
  $validationDetailPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $runValidationButton = New-Object System.Windows.Forms.Button
  $runValidationButton.Text = 'Run Validation'
  $runValidationButton.Left = 10
  $runValidationButton.Top = 10
  $runValidationButton.Width = 110
  $runValidationButton.FlatStyle = 'Flat'

  $validationDetailsBox = New-Object System.Windows.Forms.RichTextBox
  $validationDetailsBox.Left = 10
  $validationDetailsBox.Top = 46
  $validationDetailsBox.Width = 720
  $validationDetailsBox.Height = 530
  $validationDetailsBox.ReadOnly = $true
  $validationDetailsBox.Font = New-BmoFont -Name 'Consolas' -Size 9.25

  [void]$validationDetailPanel.Controls.Add($runValidationButton)
  [void]$validationDetailPanel.Controls.Add($validationDetailsBox)
  [void]$validationSplit.Panel1.Controls.Add($validationList)
  [void]$validationSplit.Panel2.Controls.Add($validationDetailPanel)
  [void]$validationTab.Controls.Add($validationSplit)

  $docsSplit = New-Object System.Windows.Forms.SplitContainer
  $docsSplit.Dock = 'Fill'
  $docsSplit.SplitterDistance = 360

  $docsList = New-Object System.Windows.Forms.ListView
  $docsList.Dock = 'Fill'
  $docsList.View = 'Details'
  $docsList.FullRowSelect = $true
  $docsList.GridLines = $true
  [void]$docsList.Columns.Add('Document', 140)
  [void]$docsList.Columns.Add('Path', 200)

  $docPreview = New-Object System.Windows.Forms.RichTextBox
  $docPreview.Dock = 'Fill'
  $docPreview.ReadOnly = $true
  $docPreview.Font = New-BmoFont -Name 'Consolas' -Size 9.25

  [void]$docsSplit.Panel1.Controls.Add($docsList)
  [void]$docsSplit.Panel2.Controls.Add($docPreview)
  [void]$docsTab.Controls.Add($docsSplit)

  $settingsPanel = New-Object System.Windows.Forms.Panel
  $settingsPanel.Dock = 'Fill'
  $settingsPanel.Padding = New-Object System.Windows.Forms.Padding(10)

  $safeModeLabel = New-Object System.Windows.Forms.Label
  $safeModeLabel.Text = 'Safe execution mode'
  $safeModeLabel.AutoSize = $true
  $safeModeLabel.Left = 10
  $safeModeLabel.Top = 12

  $safeModeCombo = New-Object System.Windows.Forms.ComboBox
  $safeModeCombo.Left = 10
  $safeModeCombo.Top = 34
  $safeModeCombo.Width = 220
  $safeModeCombo.DropDownStyle = 'DropDownList'
  [void]$safeModeCombo.Items.Add('prompt')
  [void]$safeModeCombo.Items.Add('deny-unknown')

  $maxOutputLabel = New-Object System.Windows.Forms.Label
  $maxOutputLabel.Text = 'Max output characters'
  $maxOutputLabel.AutoSize = $true
  $maxOutputLabel.Left = 10
  $maxOutputLabel.Top = 78

  $maxOutputBox = New-Object System.Windows.Forms.TextBox
  $maxOutputBox.Left = 10
  $maxOutputBox.Top = 100
  $maxOutputBox.Width = 140
  $maxOutputBox.Font = New-BmoFont -Name 'Consolas' -Size 9.5

  $providerModeLabel = New-Object System.Windows.Forms.Label
  $providerModeLabel.Text = 'Provider mode'
  $providerModeLabel.AutoSize = $true
  $providerModeLabel.Left = 280
  $providerModeLabel.Top = 12

  $providerModeCombo = New-Object System.Windows.Forms.ComboBox
  $providerModeCombo.Left = 280
  $providerModeCombo.Top = 34
  $providerModeCombo.Width = 220
  $providerModeCombo.DropDownStyle = 'DropDownList'
  [void]$providerModeCombo.Items.Add('offline')
  [void]$providerModeCombo.Items.Add('openai-compatible')

  $providerEndpointLabel = New-Object System.Windows.Forms.Label
  $providerEndpointLabel.Text = 'Provider endpoint'
  $providerEndpointLabel.AutoSize = $true
  $providerEndpointLabel.Left = 280
  $providerEndpointLabel.Top = 78

  $providerEndpointBox = New-Object System.Windows.Forms.TextBox
  $providerEndpointBox.Left = 280
  $providerEndpointBox.Top = 100
  $providerEndpointBox.Width = 420
  $providerEndpointBox.Font = New-BmoFont -Name 'Consolas' -Size 9.5

  $providerModelLabel = New-Object System.Windows.Forms.Label
  $providerModelLabel.Text = 'Provider model'
  $providerModelLabel.AutoSize = $true
  $providerModelLabel.Left = 280
  $providerModelLabel.Top = 144

  $providerModelBox = New-Object System.Windows.Forms.TextBox
  $providerModelBox.Left = 280
  $providerModelBox.Top = 166
  $providerModelBox.Width = 220
  $providerModelBox.Font = New-BmoFont -Name 'Consolas' -Size 9.5

  $providerApiKeyLabel = New-Object System.Windows.Forms.Label
  $providerApiKeyLabel.Text = 'Provider API key'
  $providerApiKeyLabel.AutoSize = $true
  $providerApiKeyLabel.Left = 280
  $providerApiKeyLabel.Top = 210

  $providerApiKeyBox = New-Object System.Windows.Forms.TextBox
  $providerApiKeyBox.Left = 280
  $providerApiKeyBox.Top = 232
  $providerApiKeyBox.Width = 420
  $providerApiKeyBox.Font = New-BmoFont -Name 'Consolas' -Size 9.5
  $providerApiKeyBox.UseSystemPasswordChar = $true

  $saveSettingsButton = New-Object System.Windows.Forms.Button
  $saveSettingsButton.Text = 'Save Settings'
  $saveSettingsButton.Left = 10
  $saveSettingsButton.Top = 150
  $saveSettingsButton.Width = 110
  $saveSettingsButton.FlatStyle = 'Flat'

  $openDataRootButton = New-Object System.Windows.Forms.Button
  $openDataRootButton.Text = 'Open Data Root'
  $openDataRootButton.Left = 128
  $openDataRootButton.Top = 150
  $openDataRootButton.Width = 110
  $openDataRootButton.FlatStyle = 'Flat'

  $settingsInfoBox = New-Object System.Windows.Forms.RichTextBox
  $settingsInfoBox.Left = 10
  $settingsInfoBox.Top = 290
  $settingsInfoBox.Width = 900
  $settingsInfoBox.Height = 290
  $settingsInfoBox.ReadOnly = $true
  $settingsInfoBox.Font = New-BmoFont -Name 'Consolas' -Size 9.25
  $settingsInfoBox.BackColor = $palette.White

  [void]$settingsPanel.Controls.Add($safeModeLabel)
  [void]$settingsPanel.Controls.Add($safeModeCombo)
  [void]$settingsPanel.Controls.Add($maxOutputLabel)
  [void]$settingsPanel.Controls.Add($maxOutputBox)
  [void]$settingsPanel.Controls.Add($providerModeLabel)
  [void]$settingsPanel.Controls.Add($providerModeCombo)
  [void]$settingsPanel.Controls.Add($providerEndpointLabel)
  [void]$settingsPanel.Controls.Add($providerEndpointBox)
  [void]$settingsPanel.Controls.Add($providerModelLabel)
  [void]$settingsPanel.Controls.Add($providerModelBox)
  [void]$settingsPanel.Controls.Add($providerApiKeyLabel)
  [void]$settingsPanel.Controls.Add($providerApiKeyBox)
  [void]$settingsPanel.Controls.Add($saveSettingsButton)
  [void]$settingsPanel.Controls.Add($openDataRootButton)
  [void]$settingsPanel.Controls.Add($settingsInfoBox)
  [void]$settingsTab.Controls.Add($settingsPanel)

  [void]$operationsTab.Controls.Add($operationsTabs)
  [void]$operationsTab.Controls.Add($operationsTopPanel)

  function Set-StatusText {
    param([string]$Text)
    $statusLabel.Text = $Text
  }

  function Get-WorkspaceOrThrow {
    $value = $workspaceCombo.Text.Trim()
    if (-not (Test-BmoWorkspace -WorkspacePath $value)) {
      throw 'Choose a valid workspace or worktree root first.'
    }
    $resolved = Resolve-BmoWorkspacePath -WorkspacePath $value
    $state.workspace = $resolved
    return $resolved
  }

  function Load-WorkspaceChoices {
    $currentText = $workspaceCombo.Text
    $workspaceCombo.Items.Clear()
    $currentSettings = Get-BmoSettings
    $choices = @()
    if (-not [string]::IsNullOrWhiteSpace($state.workspace)) {
      $choices += $state.workspace
    }
    $choices += @($currentSettings.recentWorkspaces)
    foreach ($choice in ($choices | Select-Object -Unique)) {
      if (-not [string]::IsNullOrWhiteSpace([string]$choice)) {
        [void]$workspaceCombo.Items.Add([string]$choice)
      }
    }
    if (-not [string]::IsNullOrWhiteSpace($currentText)) {
      $workspaceCombo.Text = $currentText
    } else {
      $workspaceCombo.Text = $state.workspace
    }
  }

  function Append-TranscriptLine {
    param(
      [string]$Speaker,
      [string]$Text
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $transcript.AppendText("[$stamp] $Speaker`r`n")
    $transcript.AppendText("$Text`r`n`r`n")
    $transcript.SelectionStart = $transcript.TextLength
    $transcript.ScrollToCaret()
  }

  function Copy-TextToClipboard {
    param([string]$Text)

    try {
      [System.Windows.Forms.Clipboard]::SetText($Text)
      Set-StatusText 'Copied to clipboard.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show('Clipboard copy failed in this session.', 'Clipboard')
    }
  }

  function Get-SelectedWorkspaceItemPath {
    if ($null -eq $fileTree.SelectedNode -or $null -eq $fileTree.SelectedNode.Tag) {
      return $state.workspace
    }

    $selectedPath = [string]$fileTree.SelectedNode.Tag
    try {
      $item = Get-Item -LiteralPath $selectedPath -ErrorAction Stop
      if ($item.PSIsContainer) {
        return $selectedPath
      }
      return (Split-Path -Parent $selectedPath)
    } catch {
      return $state.workspace
    }
  }

  function Prompt-WorkspaceRelativePath {
    param(
      [string]$Title,
      [string]$Prompt,
      [string]$DefaultValue = ''
    )

    return [Microsoft.VisualBasic.Interaction]::InputBox($Prompt, $Title, $DefaultValue)
  }

  function Update-ProviderFieldState {
    $isProviderEnabled = ($providerModeCombo.SelectedItem -eq 'openai-compatible')
    $providerEndpointBox.Enabled = $isProviderEnabled
    $providerModelBox.Enabled = $isProviderEnabled
    $providerApiKeyBox.Enabled = $isProviderEnabled
  }

  function Refresh-Settings {
    $settings = Get-BmoSettings
    if ($safeModeCombo.Items.Contains($settings.safeExecutionMode)) {
      $safeModeCombo.SelectedItem = $settings.safeExecutionMode
    } else {
      $safeModeCombo.SelectedItem = 'prompt'
    }

    $maxOutputBox.Text = [string]$settings.maxOutputCharacters
    if ($providerModeCombo.Items.Contains($settings.provider.mode)) {
      $providerModeCombo.SelectedItem = $settings.provider.mode
    } else {
      $providerModeCombo.SelectedItem = 'offline'
    }
    $providerEndpointBox.Text = [string]$settings.provider.endpoint
    $providerModelBox.Text = [string]$settings.provider.model
    $providerApiKeyBox.Text = [string]$settings.provider.apiKey
    Update-ProviderFieldState

    $settingsInfoBox.Text = @"
Settings file:
$(Get-BmoSettingsPath)

Data root:
$(Get-BmoDataRoot)

Current workspace:
$($state.workspace)

Safe execution mode:
$($settings.safeExecutionMode)

Provider mode:
$($settings.provider.mode)

Preferred runtime profile:
$($settings.preferredRuntimeProfile)
"@
  }

  function Confirm-CommandApproval {
    param(
      [string]$CommandText,
      [string]$ActionLabel
    )

    $classification = Get-BmoCommandClassification -CommandText $CommandText
    if ($classification.decision -eq 'deny') {
      [System.Windows.Forms.MessageBox]::Show(
        "Blocked: $($classification.reason)`r`n`r`n$CommandText",
        'Command blocked',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
      ) | Out-Null
      return $null
    }

    if (-not $classification.requiresApproval) {
      return [pscustomobject]@{
        approved = $false
        classification = $classification
      }
    }

    $message = @"
Approve this $ActionLabel?

Decision: $($classification.decision)
Capability: $($classification.capability)
Risk: $($classification.riskLevel)
Reason: $($classification.reason)

Workspace:
$($state.workspace)

Command:
$CommandText
"@

    $answer = [System.Windows.Forms.MessageBox]::Show(
      $message,
      'Approve command',
      [System.Windows.Forms.MessageBoxButtons]::YesNo,
      [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
      return $null
    }

    return [pscustomobject]@{
      approved = $true
      classification = $classification
    }
  }

  function Update-CommandPreview {
    $commandText = $commandInputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($commandText)) {
      $commandPreviewBox.Text = "Enter a command to see the workspace, policy decision, and approval path before execution."
      return
    }

    try {
      $workspace = Get-WorkspaceOrThrow
      $classification = Get-BmoCommandClassification -CommandText $commandText
      $commandPreviewBox.Text = @"
Workspace:
$workspace

Decision: $($classification.decision)
Capability: $($classification.capability)
Risk: $($classification.riskLevel)
Safe allowlist match: $($classification.safe)

Reason:
$($classification.reason)

Exact command:
$commandText
"@
    } catch {
      $commandPreviewBox.Text = "Command preview unavailable.`r`n`r`n$($_.Exception.Message)"
    }
  }

  function Add-PlaceholderNode {
    param([System.Windows.Forms.TreeNode]$Node)
    [void]$Node.Nodes.Add('__placeholder__')
  }

  function New-FileTreeNode {
    param([System.IO.FileSystemInfo]$Item)

    $node = New-Object System.Windows.Forms.TreeNode
    $node.Text = $Item.Name
    $node.Tag = $Item.FullName
    if ($Item.PSIsContainer) {
      Add-PlaceholderNode -Node $node
      $node.ForeColor = $palette.Accent
    }
    return $node
  }

  function Populate-DirectoryNode {
    param([System.Windows.Forms.TreeNode]$Node)

    $Node.Nodes.Clear()
    $path = [string]$Node.Tag
    try {
      $items = Get-ChildItem -LiteralPath $path -Force | Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name
      foreach ($item in $items) {
        if ($item.Name -in @('.git', 'node_modules', 'dist', 'build')) {
          continue
        }
        [void]$Node.Nodes.Add((New-FileTreeNode -Item $item))
      }
    } catch {
      [void]$Node.Nodes.Add('[Unable to read]')
    }
  }

  function Load-FileIntoEditor {
    param([string]$AbsolutePath)

    $workspace = Get-WorkspaceOrThrow
    $relative = Get-BmoRelativePath -WorkspacePath $workspace -TargetPath $AbsolutePath
    $state.loadingFile = $true
    try {
      $content = Read-BmoWorkspaceFile -WorkspacePath $workspace -RelativePath $relative -NoTruncate
      $state.currentFileRelative = $relative
      $state.currentFileOriginal = $content
      $fileEditor.ReadOnly = $false
      $fileEditor.Text = $content
      $filePathLabel.Text = $relative
      $saveFileButton.Enabled = $false
      $revertFileButton.Enabled = $true
    } catch {
      $state.currentFileRelative = ''
      $state.currentFileOriginal = ''
      $fileEditor.ReadOnly = $true
      $fileEditor.Text = $_.Exception.Message
      $filePathLabel.Text = 'No editable file selected.'
      $saveFileButton.Enabled = $false
      $revertFileButton.Enabled = $false
    } finally {
      $state.loadingFile = $false
    }
  }

  function Refresh-FileTree {
    try {
      $workspace = Get-WorkspaceOrThrow
      $fileTree.BeginUpdate()
      $fileTree.Nodes.Clear()
      $rootNode = New-Object System.Windows.Forms.TreeNode((Split-Path $workspace -Leaf))
      $rootNode.Tag = $workspace
      Add-PlaceholderNode -Node $rootNode
      [void]$fileTree.Nodes.Add($rootNode)
      Populate-DirectoryNode -Node $rootNode
      $rootNode.Expand()
    } catch {
      $fileTree.Nodes.Clear()
      [void]$fileTree.Nodes.Add('[Workspace unavailable]')
    } finally {
      $fileTree.EndUpdate()
    }
  }

  function Refresh-SourceControl {
    try {
      $workspace = Get-WorkspaceOrThrow
      $repo = Get-BmoRepoInfo -WorkspacePath $workspace
      $repoSummaryLabel.Text = if ($repo.isGitRepo) {
        "Branch: $($repo.branch) | Dirty: $($repo.dirty) | Staged: $($repo.stagedCount) | Unstaged: $($repo.unstagedCount) | Untracked: $($repo.untrackedCount)"
      } else {
        'Workspace is not a git repo.'
      }

      $changedFilesList.Items.Clear()
      foreach ($change in $repo.changedFiles) {
        $item = New-Object System.Windows.Forms.ListViewItem($change.path)
        [void]$item.SubItems.Add($change.summary)
        $item.Tag = $change.path
        [void]$changedFilesList.Items.Add($item)
      }

      $worktreesList.Items.Clear()
      foreach ($worktree in $repo.worktrees) {
        $branchText = if ($worktree.isCurrent) { "$($worktree.branch) *" } else { $worktree.branch }
        $item = New-Object System.Windows.Forms.ListViewItem($branchText)
        [void]$item.SubItems.Add($worktree.path)
        $item.Tag = $worktree.path
        [void]$worktreesList.Items.Add($item)
      }

      $recentCommits = Get-BmoRecentCommits -WorkspacePath $workspace -Limit 10
      $recentCommitsBox.Text = if (@($recentCommits).Count -gt 0) {
        (@($recentCommits | ForEach-Object { $_.line }) -join "`r`n")
      } elseif ($repo.isGitRepo) {
        'No commit history is available yet.'
      } else {
        'Open a git repo to inspect recent commits.'
      }

      if ($changedFilesList.Items.Count -eq 0) {
        $diffView.Text = if ($repo.isGitRepo) { 'No changed files.' } else { 'Open a git repo to inspect diffs.' }
      }
    } catch {
      $repoSummaryLabel.Text = 'Repo inspection failed.'
      $diffView.Text = $_.Exception.Message
      $recentCommitsBox.Text = $_.Exception.Message
    }
  }

  function Refresh-Tasks {
    $selectedId = if ($tasksList.SelectedItems.Count -gt 0) { [string]$tasksList.SelectedItems[0].Tag } else { '' }
    $tasksList.Items.Clear()
    $tasks = Get-BmoTaskHistory -WorkspacePath $state.workspace -Limit 200
    foreach ($task in $tasks) {
      $started = if ($task.startedAt) { ([datetime]$task.startedAt).ToString('MM-dd HH:mm') } else { '' }
      $item = New-Object System.Windows.Forms.ListViewItem([string]$task.status)
      [void]$item.SubItems.Add([string]$task.taskType)
      [void]$item.SubItems.Add([string]$task.initiatedBy)
      [void]$item.SubItems.Add($started)
      [void]$item.SubItems.Add([string]$task.title)
      $item.Tag = $task.id
      [void]$tasksList.Items.Add($item)
      if ($task.id -eq $selectedId) {
        $item.Selected = $true
      }
    }

    if ($tasksList.SelectedItems.Count -gt 0) {
      $selectedTaskId = [string]$tasksList.SelectedItems[0].Tag
      $taskOutputBox.Text = Get-BmoTaskOutput -TaskId $selectedTaskId -NoTruncate
      $taskOutputLabel.Text = "Task: $selectedTaskId"
    }
  }

  function Refresh-Operations {
    $workspace = Get-WorkspaceOrThrow
    $toolText = Get-BmoToolStatusText -ToolStatus (Get-BmoToolStatus)
    $guidance = Get-BmoNextStepGuidance -WorkspacePath $workspace
    $settings = Get-BmoSettings
    $validationCatalog = Get-BmoValidationCatalog -WorkspacePath $workspace
    $validationSummary = if (@($validationCatalog).Count -gt 0) {
      @($validationCatalog | Select-Object -First 4 | ForEach-Object { "- $($_.name): $($_.lastStatus)" }) -join "`r`n"
    } else {
      'No validation actions are registered.'
    }
    $healthBox.Text = @"
Workspace:
$workspace

Data root:
$(Get-BmoDataRoot)

Safe mode:
$($settings.safeExecutionMode)

Provider mode:
$($settings.provider.mode)

Tooling:
$toolText

Latest validation status:
$validationSummary

Next steps:
$guidance
"@

    $profileCombo.Items.Clear()
    $profiles = Get-BmoRuntimeProfileCatalog -WorkspacePath $workspace
    foreach ($profile in $profiles) {
      [void]$profileCombo.Items.Add($profile.id)
    }
    if ($profileCombo.Items.Count -gt 0) {
      $preferred = $settings.preferredRuntimeProfile
      if ($profileCombo.Items.Contains($preferred)) {
        $profileCombo.SelectedItem = $preferred
      } else {
        $profileCombo.SelectedIndex = 0
      }
    }

    $routinesList.Items.Clear()
    foreach ($routine in Get-BmoRoutineCatalog -WorkspacePath $workspace) {
      $item = New-Object System.Windows.Forms.ListViewItem([string]$routine.name)
      [void]$item.SubItems.Add([string]$routine.readiness)
      [void]$item.SubItems.Add([string]$routine.lastStatus)
      [void]$item.SubItems.Add([string]$routine.command)
      $item.Tag = $routine
      [void]$routinesList.Items.Add($item)
    }

    $skillsList.Items.Clear()
    foreach ($skill in Get-BmoSkillCatalog -WorkspacePath $workspace) {
      $item = New-Object System.Windows.Forms.ListViewItem([string]$skill.name)
      [void]$item.SubItems.Add([string]$skill.commandReadiness)
      [void]$item.SubItems.Add([string]$skill.recommendedCommand)
      $item.Tag = $skill
      [void]$skillsList.Items.Add($item)
    }

    $validationList.Items.Clear()
    foreach ($validation in $validationCatalog) {
      $item = New-Object System.Windows.Forms.ListViewItem([string]$validation.name)
      [void]$item.SubItems.Add([string]$validation.readiness)
      [void]$item.SubItems.Add([string]$validation.lastStatus)
      [void]$item.SubItems.Add([string]$validation.command)
      $item.Tag = $validation
      [void]$validationList.Items.Add($item)
    }

    $docsList.Items.Clear()
    foreach ($doc in Get-BmoDocumentShortcuts) {
      $item = New-Object System.Windows.Forms.ListViewItem([string]$doc.name)
      [void]$item.SubItems.Add([string]$doc.path)
      $item.Tag = $doc
      [void]$docsList.Items.Add($item)
    }

    Refresh-Settings
  }

  function Refresh-Overview {
    $workspace = Get-WorkspaceOrThrow
    $repo = Get-BmoRepoInfo -WorkspacePath $workspace
    $repoText = if ($repo.isGitRepo) {
      @"
Workspace: $workspace
Repo root: $($repo.repoRoot)
Branch: $($repo.branch)
Dirty: $($repo.dirty)
Staged: $($repo.stagedCount)
Unstaged: $($repo.unstagedCount)
Untracked: $($repo.untrackedCount)
Active tasks: $((Get-BmoActiveTasks).Count)

Next steps:
$(Get-BmoNextStepGuidance -WorkspacePath $workspace)
"@
    } else {
      @"
Workspace: $workspace
Repo root: not a git repo
Active tasks: $((Get-BmoActiveTasks).Count)

Next steps:
$(Get-BmoNextStepGuidance -WorkspacePath $workspace)
"@
    }

    $overviewBox.Text = $repoText
    $repoStatusLabel.Text = if ($repo.isGitRepo) { "Repo: $($repo.branch)" } else { 'Repo: non-git workspace' }
    $taskStatusLabel.Text = "Tasks: $((Get-BmoActiveTasks).Count)"
  }

  function Refresh-All {
    Load-WorkspaceChoices
    Update-CommandPreview
    Refresh-Overview
    Refresh-FileTree
    Refresh-SourceControl
    Refresh-Tasks
    Refresh-Operations
  }

  function Show-SelectedDiff {
    if ($changedFilesList.SelectedItems.Count -eq 0) {
      return
    }

    $relativePath = [string]$changedFilesList.SelectedItems[0].Tag
    $diffView.Text = Get-BmoRepoDiff -WorkspacePath $state.workspace -RelativePath $relativePath -Mode $state.diffMode
  }

  function Show-SelectedTaskOutput {
    if ($tasksList.SelectedItems.Count -eq 0) {
      return
    }

    $taskId = [string]$tasksList.SelectedItems[0].Tag
    $taskOutputLabel.Text = "Task: $taskId"
    $taskOutputBox.Text = Get-BmoTaskOutput -TaskId $taskId -NoTruncate
  }

  function Show-SelectedRoutineDetails {
    if ($routinesList.SelectedItems.Count -eq 0) {
      return
    }

    $routine = $routinesList.SelectedItems[0].Tag
    $routineDetailsBox.Text = @"
Name: $($routine.name)
Raw command: $($routine.rawCommand)
Effective command: $($routine.command)
Owner: $($routine.owner_surface)
Readiness: $($routine.readiness)
Readiness note: $($routine.readinessReason)
Execution note: $($routine.executionNote)
Last task status: $($routine.lastStatus)

Purpose:
$($routine.purpose)

Related files:
$(@($routine.related_files) -join "`r`n")
"@
  }

  function Show-SelectedSkillDetails {
    if ($skillsList.SelectedItems.Count -eq 0) {
      return
    }

    $skill = $skillsList.SelectedItems[0].Tag
    $skillDetailsBox.Text = @"
Skill: $($skill.name)
Default action: $($skill.defaultAction)
Raw suggested command: $($skill.rawRecommendedCommand)
Suggested command: $($skill.recommendedCommand)
Readiness: $($skill.commandReadiness)
Readiness note: $($skill.commandReadinessReason)
Execution note: $($skill.executionNote)
Document: $($skill.documentPath)

Description:
$($skill.description)

Triggers:
$(@($skill.triggers) -join ', ')
"@
  }

  function Show-SelectedValidationDetails {
    if ($validationList.SelectedItems.Count -eq 0) {
      return
    }

    $validation = $validationList.SelectedItems[0].Tag
    $validationDetailsBox.Text = @"
Validation: $($validation.name)
Raw command: $($validation.rawCommand)
Effective command: $($validation.command)
Readiness: $($validation.readiness)
Readiness note: $($validation.readinessReason)
Execution note: $($validation.executionNote)
Last task status: $($validation.lastStatus)

Description:
$($validation.description)
"@
  }

  function Show-SelectedDocument {
    if ($docsList.SelectedItems.Count -eq 0) {
      return
    }

    $doc = $docsList.SelectedItems[0].Tag
    $docPreview.Text = Get-BmoDocumentContent -WorkspacePath $state.workspace -RelativePath $doc.path
  }

  $browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Choose the repo or worktree root BMO should operate in'
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
      $workspaceCombo.Text = $dialog.SelectedPath
      $state.workspace = Resolve-BmoWorkspacePath -WorkspacePath $dialog.SelectedPath
      Add-BmoRecentWorkspace -WorkspacePath $state.workspace
      Refresh-All
      Set-StatusText "Workspace selected: $($state.workspace)"
    }
  })

  $saveWorkspaceButton.Add_Click({
    try {
      $workspace = Get-WorkspaceOrThrow
      $currentSettings = Get-BmoSettings
      $currentSettings.defaultWorkspace = $workspace
      Save-BmoSettings -Settings $currentSettings
      Add-BmoRecentWorkspace -WorkspacePath $workspace
      Load-WorkspaceChoices
      Set-StatusText 'Workspace saved as default.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Save workspace')
    }
  })

  $refreshAllButton.Add_Click({ Refresh-All; Set-StatusText 'Refreshed workstation state.' })

  $openLogsButton.Add_Click({
    try {
      Start-Process explorer.exe (Join-Path (Get-BmoDataRoot) 'logs') | Out-Null
      Set-StatusText 'Opened logs folder.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Open logs')
    }
  })

  $commandInputBox.Add_TextChanged({ Update-CommandPreview })
  $previewCommandButton.Add_Click({ Update-CommandPreview })
  $runCommandButton.Add_Click({
    try {
      $workspace = Get-WorkspaceOrThrow
      $command = $commandInputBox.Text.Trim()
      $approval = Confirm-CommandApproval -CommandText $command -ActionLabel 'command'
      if ($null -eq $approval) {
        Set-StatusText 'Command canceled.'
        return
      }
      $task = Start-BmoProcessTask -WorkspacePath $workspace -CommandText $command -TaskType 'command' -Title $command -InitiatedBy 'operator' -Approved:$approval.approved
      Append-TranscriptLine -Speaker 'BMO' -Text "Started command task $($task.id). Watch the Tasks tab for live status and exact output."
      Refresh-Tasks
      Refresh-Overview
      Set-StatusText "Started task $($task.id)"
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Run command')
    }
  })

  $sendPromptButton.Add_Click({
    $prompt = $promptInputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($prompt)) {
      return
    }

    try {
      $workspace = Get-WorkspaceOrThrow
      Append-TranscriptLine -Speaker 'You' -Text $prompt

      if ($prompt.StartsWith('/unsafe ')) {
        $unsafeCommand = $prompt.Substring(8).Trim()
        $approval = Confirm-CommandApproval -CommandText $unsafeCommand -ActionLabel 'unsafe command'
        if ($null -eq $approval) {
          Append-TranscriptLine -Speaker 'BMO' -Text 'Unsafe command canceled.'
          return
        }
        $task = Start-BmoProcessTask -WorkspacePath $workspace -CommandText $unsafeCommand -TaskType 'command' -Title $unsafeCommand -InitiatedBy 'agent' -Approved:$approval.approved
        Append-TranscriptLine -Speaker 'BMO' -Text "Started approved command task $($task.id)."
      } else {
        $reply = Invoke-BmoAssistant -Prompt $prompt -WorkspacePath $workspace
        Append-TranscriptLine -Speaker 'BMO' -Text $reply
      }

      $promptInputBox.Clear()
      Refresh-Tasks
      Refresh-Overview
      Set-StatusText 'Prompt processed.'
    } catch {
      Append-TranscriptLine -Speaker 'BMO' -Text "Error: $($_.Exception.Message)"
      Set-StatusText 'Prompt failed.'
    }
  })

  $promptInputBox.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter -and -not $_.Shift) {
      $sendPromptButton.PerformClick()
      $_.SuppressKeyPress = $true
    }
  })

  $clearTranscriptButton.Add_Click({ $transcript.Clear(); Append-TranscriptLine -Speaker 'BMO' -Text 'Transcript cleared. Task history and logs remain intact.' })

  $refreshTreeButton.Add_Click({ Refresh-FileTree })
  $fileTree.add_BeforeExpand({
    if ($_.Node.Nodes.Count -eq 1 -and $_.Node.Nodes[0].Text -eq '__placeholder__') {
      Populate-DirectoryNode -Node $_.Node
    }
  })

  $fileTree.add_AfterSelect({
    try {
      $selectedPath = [string]$fileTree.SelectedNode.Tag
      if ((Get-Item -LiteralPath $selectedPath).PSIsContainer) {
        $state.loadingFile = $true
        $filePathLabel.Text = $selectedPath
        $fileEditor.ReadOnly = $true
        $fileEditor.Text = ((Get-ChildItem -LiteralPath $selectedPath -Force | Select-Object -First 100 | ForEach-Object { $_.Name }) -join "`r`n")
        $saveFileButton.Enabled = $false
        $revertFileButton.Enabled = $false
        $state.loadingFile = $false
      } else {
        Load-FileIntoEditor -AbsolutePath $selectedPath
      }
    } catch {
      $fileEditor.Text = $_.Exception.Message
    }
  })

  $insertReadButton.Add_Click({
    try {
      if ($null -eq $fileTree.SelectedNode -or $null -eq $fileTree.SelectedNode.Tag) {
        throw 'Select a file first.'
      }
      $selectedPath = [string]$fileTree.SelectedNode.Tag
      if ((Get-Item -LiteralPath $selectedPath).PSIsContainer) {
        throw 'Select a file, not a directory.'
      }
      $relative = Get-BmoRelativePath -WorkspacePath $state.workspace -TargetPath $selectedPath
      $promptInputBox.Text = "/read $relative"
      $tabControl.SelectedTab = $dashboardTab
      $promptInputBox.Focus()
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Insert /read')
    }
  })

  $openFileExternalButton.Add_Click({
    try {
      if ($null -eq $fileTree.SelectedNode -or $null -eq $fileTree.SelectedNode.Tag) {
        throw 'Select a file or folder first.'
      }
      $selectedPath = [string]$fileTree.SelectedNode.Tag
      Start-Process explorer.exe "/select,$selectedPath" | Out-Null
      Set-StatusText 'Opened item in Explorer.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Open external')
    }
  })

  $newFileButton.Add_Click({
    try {
      $workspace = Get-WorkspaceOrThrow
      $defaultBase = Get-BmoRelativePath -WorkspacePath $workspace -TargetPath (Get-SelectedWorkspaceItemPath)
      if ($defaultBase -eq '.') {
        $defaultBase = 'notes.txt'
      } elseif (-not [string]::IsNullOrWhiteSpace($defaultBase)) {
        $defaultBase = (Join-Path $defaultBase 'new-file.txt')
      }
      $relativePath = Prompt-WorkspaceRelativePath -Title 'New File' -Prompt 'Enter a relative file path inside the workspace.' -DefaultValue $defaultBase
      if ([string]::IsNullOrWhiteSpace($relativePath)) {
        return
      }
      [void](New-BmoWorkspaceFile -WorkspacePath $workspace -RelativePath $relativePath)
      Refresh-FileTree
      Load-FileIntoEditor -AbsolutePath (Join-Path $workspace $relativePath)
      Set-StatusText "Created file $relativePath"
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'New file')
    }
  })

  $newFolderButton.Add_Click({
    try {
      $workspace = Get-WorkspaceOrThrow
      $defaultBase = Get-BmoRelativePath -WorkspacePath $workspace -TargetPath (Get-SelectedWorkspaceItemPath)
      if ($defaultBase -eq '.') {
        $defaultBase = 'new-folder'
      } elseif (-not [string]::IsNullOrWhiteSpace($defaultBase)) {
        $defaultBase = (Join-Path $defaultBase 'new-folder')
      }
      $relativePath = Prompt-WorkspaceRelativePath -Title 'New Folder' -Prompt 'Enter a relative folder path inside the workspace.' -DefaultValue $defaultBase
      if ([string]::IsNullOrWhiteSpace($relativePath)) {
        return
      }
      [void](New-BmoWorkspaceDirectory -WorkspacePath $workspace -RelativePath $relativePath)
      Refresh-FileTree
      Set-StatusText "Created folder $relativePath"
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'New folder')
    }
  })

  $fileEditor.Add_TextChanged({
    if (-not $state.loadingFile -and -not [string]::IsNullOrWhiteSpace($state.currentFileRelative)) {
      $saveFileButton.Enabled = ($fileEditor.Text -ne $state.currentFileOriginal)
      $revertFileButton.Enabled = $true
    }
  })

  $saveFileButton.Add_Click({
    try {
      $workspace = Get-WorkspaceOrThrow
      if ([string]::IsNullOrWhiteSpace($state.currentFileRelative)) {
        throw 'No file is selected.'
      }
      [void](Write-BmoWorkspaceFile -WorkspacePath $workspace -RelativePath $state.currentFileRelative -Content $fileEditor.Text)
      $state.currentFileOriginal = $fileEditor.Text
      $saveFileButton.Enabled = $false
      Refresh-SourceControl
      Refresh-Overview
      Set-StatusText "Saved $($state.currentFileRelative)"
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Save file')
    }
  })

  $revertFileButton.Add_Click({
    if (-not [string]::IsNullOrWhiteSpace($state.currentFileRelative)) {
      Load-FileIntoEditor -AbsolutePath (Join-Path $state.workspace $state.currentFileRelative)
      Set-StatusText "Reloaded $($state.currentFileRelative)"
    }
  })

  $refreshRepoButton.Add_Click({ Refresh-SourceControl })
  $worktreeDiffButton.Add_Click({ $state.diffMode = 'worktree'; Show-SelectedDiff })
  $stagedDiffButton.Add_Click({ $state.diffMode = 'staged'; Show-SelectedDiff })
  $changedFilesList.Add_SelectedIndexChanged({ Show-SelectedDiff })
  $openChangedFileButton.Add_Click({
    if ($changedFilesList.SelectedItems.Count -gt 0) {
      $relativePath = [string]$changedFilesList.SelectedItems[0].Tag
      Load-FileIntoEditor -AbsolutePath (Join-Path $state.workspace $relativePath)
      $tabControl.SelectedTab = $filesTab
    }
  })

  $copyChangeSummaryButton.Add_Click({
    try {
      Copy-TextToClipboard -Text (Get-BmoCommitPrepNote -WorkspacePath $state.workspace)
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Copy summary')
    }
  })

  $stageSelectedButton.Add_Click({
    if ($changedFilesList.SelectedItems.Count -eq 0) {
      return
    }

    try {
      $relativePath = [string]$changedFilesList.SelectedItems[0].Tag
      $approval = Confirm-CommandApproval -CommandText ("git add -- " + (ConvertTo-BmoPowerShellLiteral -Text $relativePath)) -ActionLabel 'stage selected file'
      if ($null -eq $approval) {
        return
      }
      [void](Invoke-BmoGitStageFiles -WorkspacePath $state.workspace -RelativePaths @($relativePath) -Approved:$approval.approved)
      Refresh-Tasks
      Refresh-Overview
      Set-StatusText "Staging $relativePath"
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Stage selected')
    }
  })

  $unstageSelectedButton.Add_Click({
    if ($changedFilesList.SelectedItems.Count -eq 0) {
      return
    }

    try {
      $relativePath = [string]$changedFilesList.SelectedItems[0].Tag
      $approval = Confirm-CommandApproval -CommandText ("git restore --staged -- " + (ConvertTo-BmoPowerShellLiteral -Text $relativePath)) -ActionLabel 'unstage selected file'
      if ($null -eq $approval) {
        return
      }
      [void](Invoke-BmoGitUnstageFiles -WorkspacePath $state.workspace -RelativePaths @($relativePath) -Approved:$approval.approved)
      Refresh-Tasks
      Refresh-Overview
      Set-StatusText "Unstaging $relativePath"
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Unstage selected')
    }
  })

  $stageAllButton.Add_Click({
    try {
      $approval = Confirm-CommandApproval -CommandText 'git add -A' -ActionLabel 'stage all changes'
      if ($null -eq $approval) {
        return
      }
      [void](Invoke-BmoGitStageFiles -WorkspacePath $state.workspace -Approved:$approval.approved)
      Refresh-Tasks
      Refresh-Overview
      Set-StatusText 'Staging all changes.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Stage all')
    }
  })

  $unstageAllButton.Add_Click({
    try {
      $approval = Confirm-CommandApproval -CommandText 'git restore --staged .' -ActionLabel 'unstage all changes'
      if ($null -eq $approval) {
        return
      }
      [void](Invoke-BmoGitUnstageFiles -WorkspacePath $state.workspace -Approved:$approval.approved)
      Refresh-Tasks
      Refresh-Overview
      Set-StatusText 'Unstaging all changes.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Unstage all')
    }
  })

  $useWorktreeButton.Add_Click({
    if ($worktreesList.SelectedItems.Count -eq 0) {
      return
    }
    $path = [string]$worktreesList.SelectedItems[0].Tag
    $workspaceCombo.Text = $path
    $state.workspace = Resolve-BmoWorkspacePath -WorkspacePath $path
    Add-BmoRecentWorkspace -WorkspacePath $state.workspace
    Refresh-All
    Set-StatusText "Switched workspace to $path"
  })

  $copyCommitPrepButton.Add_Click({
    try {
      Copy-TextToClipboard -Text (Get-BmoCommitPrepNote -WorkspacePath $state.workspace)
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Copy commit prep')
    }
  })

  $commitStagedButton.Add_Click({
    try {
      $message = $commitMessageBox.Text.Trim()
      if ([string]::IsNullOrWhiteSpace($message)) {
        throw 'Enter a commit message first.'
      }
      $previewCommand = 'git commit -m ' + (ConvertTo-BmoPowerShellLiteral -Text $message)
      $approval = Confirm-CommandApproval -CommandText $previewCommand -ActionLabel 'local commit'
      if ($null -eq $approval) {
        return
      }
      [void](Invoke-BmoGitCommit -WorkspacePath $state.workspace -Message $message -Approved:$approval.approved)
      Refresh-Tasks
      Refresh-Overview
      Set-StatusText 'Started local commit task.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Commit staged')
    }
  })

  $refreshTasksButton.Add_Click({ Refresh-Tasks })
  $tasksList.Add_SelectedIndexChanged({ Show-SelectedTaskOutput })
  $cancelTaskButton.Add_Click({
    if ($tasksList.SelectedItems.Count -eq 0) {
      return
    }
    $taskId = [string]$tasksList.SelectedItems[0].Tag
    if (Stop-BmoTask -TaskId $taskId) {
      Refresh-Tasks
      Set-StatusText "Cancel requested for task $taskId"
    }
  })

  $rerunTaskButton.Add_Click({
    if ($tasksList.SelectedItems.Count -eq 0) {
      return
    }

    $taskId = [string]$tasksList.SelectedItems[0].Tag
    $task = Get-BmoTaskRecord -TaskId $taskId
    if ($null -eq $task -or [string]::IsNullOrWhiteSpace($task.command)) {
      [System.Windows.Forms.MessageBox]::Show('Only command-backed tasks can be rerun.', 'Rerun task')
      return
    }

    $approval = Confirm-CommandApproval -CommandText $task.command -ActionLabel 'rerun'
    if ($null -eq $approval) {
      return
    }

    [void](Restart-BmoTask -TaskId $taskId -Approved:$approval.approved)
    Refresh-Tasks
    Refresh-Overview
  })

  $copyTaskOutputButton.Add_Click({
    if ($tasksList.SelectedItems.Count -eq 0) {
      return
    }
    Copy-TextToClipboard -Text (Get-BmoTaskOutput -TaskId ([string]$tasksList.SelectedItems[0].Tag) -NoTruncate)
  })

  $routinesList.Add_SelectedIndexChanged({ Show-SelectedRoutineDetails })
  $runRoutineButton.Add_Click({
    if ($routinesList.SelectedItems.Count -eq 0) {
      return
    }
    $routine = $routinesList.SelectedItems[0].Tag
    if (-not $routine.ready) {
      [System.Windows.Forms.MessageBox]::Show($routine.readinessReason, 'Routine blocked')
      return
    }
    $approval = Confirm-CommandApproval -CommandText $routine.command -ActionLabel 'routine'
    if ($null -eq $approval) {
      return
    }
    [void](Invoke-BmoRoutineAction -WorkspacePath $state.workspace -RoutineName $routine.name -Approved:$approval.approved)
    Refresh-Tasks
    Refresh-Overview
    Set-StatusText "Started routine $($routine.name)"
  })

  $copyRoutineCommandButton.Add_Click({
    if ($routinesList.SelectedItems.Count -gt 0) {
      $routine = $routinesList.SelectedItems[0].Tag
      Copy-TextToClipboard -Text $routine.command
    }
  })

  $skillsList.Add_SelectedIndexChanged({ Show-SelectedSkillDetails })
  $runSkillButton.Add_Click({
    if ($skillsList.SelectedItems.Count -eq 0) {
      return
    }
    $skill = $skillsList.SelectedItems[0].Tag
    if ([string]::IsNullOrWhiteSpace($skill.recommendedCommand)) {
      [System.Windows.Forms.MessageBox]::Show('This skill is documentation-only in the current repo. Open the doc instead.', 'Skill command')
      return
    }
    if (-not $skill.commandReady) {
      [System.Windows.Forms.MessageBox]::Show($skill.commandReadinessReason, 'Skill action blocked')
      return
    }
    $approval = Confirm-CommandApproval -CommandText $skill.recommendedCommand -ActionLabel 'skill action'
    if ($null -eq $approval) {
      return
    }
    [void](Start-BmoProcessTask -WorkspacePath $state.workspace -CommandText $skill.recommendedCommand -TaskType 'skill' -Title ("Skill: " + $skill.name) -InitiatedBy 'operator' -Approved:$approval.approved)
    Refresh-Tasks
    Refresh-Overview
  })

  $openSkillDocButton.Add_Click({
    if ($skillsList.SelectedItems.Count -eq 0) {
      return
    }
    $skill = $skillsList.SelectedItems[0].Tag
    if ([string]::IsNullOrWhiteSpace($skill.documentPath)) {
      return
    }
    $docPreview.Text = Get-BmoDocumentContent -WorkspacePath $state.workspace -RelativePath $skill.documentPath
    $operationsTabs.SelectedTab = $docsTab
  })

  $validationList.Add_SelectedIndexChanged({ Show-SelectedValidationDetails })
  $runValidationButton.Add_Click({
    if ($validationList.SelectedItems.Count -eq 0) {
      return
    }
    $validation = $validationList.SelectedItems[0].Tag
    if (-not $validation.ready) {
      [System.Windows.Forms.MessageBox]::Show($validation.readinessReason, 'Validation blocked')
      return
    }
    $approval = Confirm-CommandApproval -CommandText $validation.command -ActionLabel 'validation'
    if ($null -eq $approval) {
      return
    }
    [void](Invoke-BmoValidationAction -WorkspacePath $state.workspace -ActionId $validation.id -Approved:$approval.approved)
    Refresh-Tasks
    Refresh-Overview
  })

  $docsList.Add_SelectedIndexChanged({ Show-SelectedDocument })
  $applyProfileButton.Add_Click({
    if ($null -eq $profileCombo.SelectedItem) {
      return
    }

    $selectedProfile = [string]$profileCombo.SelectedItem
    $profile = @(Get-BmoRuntimeProfileCatalog -WorkspacePath $state.workspace | Where-Object { $_.id -eq $selectedProfile } | Select-Object -First 1)
    if ($profile.Count -eq 0) {
      return
    }
    if (-not $profile[0].ready) {
      [System.Windows.Forms.MessageBox]::Show($profile[0].readinessReason, 'Profile action blocked')
      return
    }
    $approval = Confirm-CommandApproval -CommandText $profile[0].command -ActionLabel 'runtime profile'
    if ($null -eq $approval) {
      return
    }
    [void](Invoke-BmoRuntimeProfileAction -WorkspacePath $state.workspace -ProfileId $selectedProfile -Approved:$approval.approved)
    Refresh-Tasks
    Refresh-Overview
    Set-StatusText "Started profile action $selectedProfile"
  })

  $providerModeCombo.Add_SelectedIndexChanged({ Update-ProviderFieldState })
  $saveSettingsButton.Add_Click({
    try {
      $settings = Get-BmoSettings
      $safeMode = [string]$safeModeCombo.SelectedItem
      $providerMode = [string]$providerModeCombo.SelectedItem
      $maxOutput = 0
      if (-not [int]::TryParse($maxOutputBox.Text.Trim(), [ref]$maxOutput)) {
        throw 'Max output characters must be an integer.'
      }
      if ($maxOutput -lt 1000) {
        throw 'Max output characters must be at least 1000.'
      }

      $settings.safeExecutionMode = if ([string]::IsNullOrWhiteSpace($safeMode)) { 'prompt' } else { $safeMode }
      $settings.maxOutputCharacters = $maxOutput
      $settings.provider.mode = if ([string]::IsNullOrWhiteSpace($providerMode)) { 'offline' } else { $providerMode }
      $settings.provider.endpoint = $providerEndpointBox.Text.Trim()
      $settings.provider.model = $providerModelBox.Text.Trim()
      $settings.provider.apiKey = $providerApiKeyBox.Text
      Save-BmoSettings -Settings $settings
      Refresh-Settings
      Refresh-Overview
      Refresh-Operations
      Set-StatusText 'Saved workstation settings.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Save settings')
    }
  })

  $openDataRootButton.Add_Click({
    try {
      Start-Process explorer.exe (Get-BmoDataRoot) | Out-Null
      Set-StatusText 'Opened BMO data root.'
    } catch {
      [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Open data root')
    }
  })

  $timer = New-Object System.Windows.Forms.Timer
  $timer.Interval = 1000
  $timer.Add_Tick({
    $completed = Sync-BmoActiveTasks
    if (@($completed).Count -gt 0) {
      Refresh-Tasks
      Refresh-Overview
      Refresh-SourceControl
      Refresh-Operations
      if ($tasksList.SelectedItems.Count -gt 0) {
        Show-SelectedTaskOutput
      }
      Set-StatusText ("Completed task update: " + (@($completed | ForEach-Object { $_.title }) -join ', '))
    } else {
      $taskStatusLabel.Text = "Tasks: $((Get-BmoActiveTasks).Count)"
    }
  })

  Load-WorkspaceChoices
  $workspaceCombo.Text = $state.workspace
  Refresh-All
  Append-TranscriptLine -Speaker 'BMO' -Text 'BMO Workstation is ready. Open Source Control for diffs, Tasks for logs, and Operations for real routines, validations, and skills.'
  $timer.Start()

  try {
    [void]$form.ShowDialog()
  } finally {
    $timer.Stop()
  }
}
