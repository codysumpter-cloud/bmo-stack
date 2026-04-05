# BMO for VS Code

Thin local VS Code shell over OpenClaw.

## What it does

V1 includes:
- Chat panel inside VS Code
- Ask about current selection
- Ask about current file
- Calls OpenClaw through the local OpenAI-compatible `/v1/chat/completions` endpoint

## Requirements

- OpenClaw gateway running locally
- OpenClaw HTTP chat completions enabled
- A valid gateway token
- VS Code installed

## Configure OpenClaw

Enable the HTTP endpoint in OpenClaw config:

```json
{
  "gateway": {
    "http": {
      "endpoints": {
        "chatCompletions": { "enabled": true }
      }
    }
  }
}
```

Then restart OpenClaw.

## Extension settings

In VS Code settings:

- `bmo.openclaw.baseUrl` → `http://127.0.0.1:18789/v1`
- `bmo.openclaw.token` → your OpenClaw gateway token
- `bmo.openclaw.model` → `openclaw/default`

## Dev install

```bash
cd apps/vscode-bmo
npm install
npm run compile
```

Then in VS Code:

1. Open this folder
2. Run `Developer: Reload Window` if needed
3. Press `F5` to launch an Extension Development Host
4. Run:
   - `BMO: Open Chat`
   - `BMO: Ask About Selection`
   - `BMO: Ask About Current File`

## Notes

This is the thin-shell version on purpose.

It does **not** yet do:
- structured patch apply
- streaming tokens
- background task log views
- sandbox/session controls in the UI

Those can be added next without throwing away this scaffold.
