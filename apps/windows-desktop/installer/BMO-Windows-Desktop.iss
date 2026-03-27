#define MyAppName "BMO Windows Desktop"
#define MyAppVersion "0.1.0"
#define MyAppPublisher "BMO Stack"
#define MyAppURL "https://github.com/codysumpter-cloud/bmo-stack"
#define MyAppExeName "BMO Windows Desktop.exe"

[Setup]
AppId={{F6A7B9E3-46A4-4CE2-A032-E8F0A8C7E8AB}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={localappdata}\Programs\BMO Windows Desktop
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\dist\installer-exe
OutputBaseFilename=BMO-Windows-Desktop-Setup
Compression=lzma
SolidCompression=yes
PrivilegesRequired=lowest
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "..\dist\exe-stage\app\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
Source: "..\dist\exe-stage\launcher\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
