# OpenClawShell Starter

A native SwiftUI iPhone shell app for local-LLM workflows.

This starter gives you:
- **Models** tab with custom model downloads and local storage
- **Chat** tab with conversation history and file-context attachments
- **Files** tab with persistent imported files in the app sandbox
- **Editor** tab with a web-backed code editor bridge you can later swap for Monaco
- Clean backend protocols so you can plug in **MLC** or **llama.cpp** next

## What works now
- Builds as a native iOS app
- Installs to your iPhone from Xcode
- Downloads arbitrary files from URLs into `Application Support/OpenClaw/Models`
- Imports multiple files into `Documents/OpenClawWorkspace`
- Opens and edits text-based files
- Persists conversations and selected file context locally

## What is stubbed on purpose
- Real on-device LLM inference. The starter uses `StubLLMEngine` so the app compiles immediately.
- Replace the stub with either:
  - **MLC** if you want the fastest path to a working on-device model UI
  - **llama.cpp** if you want broader GGUF-style model support later

## Generate the Xcode project
This repo uses **XcodeGen** so you do not have to hand-build a `.xcodeproj`.

```bash
brew install xcodegen
cd OpenClawShellStarter
xcodegen generate
open OpenClawShell.xcodeproj
```

## Run on your iPhone
1. Connect your iPhone to your Mac.
2. Open `OpenClawShell.xcodeproj`.
3. Select the **OpenClawShell** target.
4. In **Signing & Capabilities**, choose your Apple ID team (`Personal Team` is fine).
5. Change the bundle identifier to something unique like `com.prismtek.openclawshell`.
6. Choose your iPhone as the run destination.
7. Build and run.

## Project layout

```text
OpenClawShellStarter/
  project.yml
  README.md
  OpenClawShell/
    OpenClawShellApp.swift
    ContentView.swift
    Models/
    Services/
    Views/
    Assets/editor.html
```

## Swap in a real engine later
The integration point is:
- `Services/LLMEngine.swift`
- `Services/StubLLMEngine.swift`
- `Services/AppState.swift`

Replace `StubLLMEngine()` in `OpenClawShellApp.swift` with your real implementation.

### Example shape
```swift
final class MLCBridgeEngine: LocalLLMEngine {
    func installedModelIDs() async -> [String] { ... }
    func loadModel(at localURL: URL) async throws { ... }
    func generate(prompt: String, fileContexts: [WorkspaceFile]) async throws -> String { ... }
}
```

## Notes
- The editor bridge is intentionally simple. It uses a bundled HTML editor shell so you can later drop Monaco in without changing the Swift side.
- The file importer copies files into your app sandbox so they remain available later.
- The download store keeps models out of the user-visible documents folder.
