"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
function activate(context) {
    const panel = new BmoChatPanel(context);
    context.subscriptions.push(vscode.commands.registerCommand('bmo.openChat', async () => {
        await panel.show();
    }), vscode.commands.registerCommand('bmo.askAboutSelection', async () => {
        await panel.show();
        const seed = buildSelectionPrompt();
        if (!seed) {
            void vscode.window.showInformationMessage('No editor selection found.');
            return;
        }
        panel.seedComposer(seed);
    }), vscode.commands.registerCommand('bmo.askAboutCurrentFile', async () => {
        await panel.show();
        const seed = await buildCurrentFilePrompt();
        if (!seed) {
            void vscode.window.showInformationMessage('No active file found.');
            return;
        }
        panel.seedComposer(seed);
    }));
}
function deactivate() { }
class BmoChatPanel {
    panel;
    context;
    messages = [
        {
            role: 'assistant',
            content: 'BMO is ready. Ask something, or use “Ask About Selection” / “Ask About Current File”.'
        }
    ];
    constructor(context) {
        this.context = context;
    }
    async show() {
        if (!this.panel) {
            this.panel = vscode.window.createWebviewPanel('bmoChat', 'BMO Chat', vscode.ViewColumn.Beside, {
                enableScripts: true,
                retainContextWhenHidden: true
            });
            this.panel.webview.html = this.getHtml(this.panel.webview);
            this.panel.webview.onDidReceiveMessage(async (event) => {
                if (event?.type === 'send') {
                    await this.handleSend(String(event.text ?? ''));
                }
            });
            this.panel.onDidDispose(() => {
                this.panel = undefined;
            });
        }
        this.panel.reveal(vscode.ViewColumn.Beside);
        this.pushState();
    }
    seedComposer(text) {
        this.panel?.webview.postMessage({ type: 'seed', text });
    }
    async handleSend(rawText) {
        const text = rawText.trim();
        if (!text)
            return;
        this.messages.push({ role: 'user', content: text });
        this.pushState();
        try {
            const response = await callOpenClaw(this.messages);
            this.messages.push({ role: 'assistant', content: response });
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            this.messages.push({
                role: 'assistant',
                content: `Couldn’t reach OpenClaw. ${message}\n\n` +
                    `Check: (1) the gateway is running, (2) chat completions are enabled, and (3) bmo.openclaw.token is set.`
            });
        }
        this.pushState();
    }
    pushState() {
        this.panel?.webview.postMessage({ type: 'messages', messages: this.messages });
    }
    getHtml(webview) {
        const nonce = String(Date.now());
        return `<!doctype html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-${nonce}';">
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; color: var(--vscode-foreground); background: var(--vscode-editor-background); }
    .wrap { display: grid; grid-template-rows: 1fr auto; height: 100vh; }
    .messages { padding: 16px; overflow-y: auto; display: flex; flex-direction: column; gap: 12px; }
    .msg { padding: 10px 12px; border-radius: 10px; white-space: pre-wrap; line-height: 1.45; }
    .user { background: var(--vscode-textBlockQuote-background); }
    .assistant { background: color-mix(in srgb, var(--vscode-button-background) 12%, transparent); }
    .composer { border-top: 1px solid var(--vscode-panel-border); padding: 12px; display: grid; gap: 8px; }
    textarea { width: 100%; min-height: 110px; resize: vertical; box-sizing: border-box; border-radius: 8px; padding: 10px; border: 1px solid var(--vscode-input-border, transparent); background: var(--vscode-input-background); color: var(--vscode-input-foreground); }
    button { justify-self: end; border: 0; border-radius: 6px; padding: 8px 12px; cursor: pointer; background: var(--vscode-button-background); color: var(--vscode-button-foreground); }
    .hint { font-size: 12px; opacity: 0.75; }
  </style>
</head>
<body>
  <div class="wrap">
    <div id="messages" class="messages"></div>
    <div class="composer">
      <div class="hint">Thin local shell over OpenClaw. Configure base URL + token in VS Code settings.</div>
      <textarea id="input" placeholder="Ask BMO about this project..."></textarea>
      <button id="send">Send</button>
    </div>
  </div>
  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    const messagesEl = document.getElementById('messages');
    const inputEl = document.getElementById('input');
    const sendEl = document.getElementById('send');

    function render(messages) {
      messagesEl.innerHTML = '';
      for (const m of messages) {
        const div = document.createElement('div');
        div.className = 'msg ' + (m.role === 'user' ? 'user' : 'assistant');
        div.textContent = m.content;
        messagesEl.appendChild(div);
      }
      messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    sendEl.addEventListener('click', () => {
      const text = inputEl.value;
      if (!text.trim()) return;
      vscode.postMessage({ type: 'send', text });
      inputEl.value = '';
      inputEl.focus();
    });

    inputEl.addEventListener('keydown', (event) => {
      if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
        sendEl.click();
      }
    });

    window.addEventListener('message', (event) => {
      const msg = event.data;
      if (msg.type === 'messages') render(msg.messages || []);
      if (msg.type === 'seed') {
        inputEl.value = msg.text || '';
        inputEl.focus();
      }
    });
  </script>
</body>
</html>`;
    }
}
async function callOpenClaw(history) {
    const config = vscode.workspace.getConfiguration('bmo');
    const baseUrl = String(config.get('openclaw.baseUrl') ?? 'http://127.0.0.1:18789/v1').replace(/\/$/, '');
    const token = String(config.get('openclaw.token') ?? '').trim();
    const model = String(config.get('openclaw.model') ?? 'openclaw/default');
    const user = String(config.get('openclaw.user') ?? 'vscode-bmo');
    const includeWorkspacePath = Boolean(config.get('openclaw.includeWorkspacePath') ?? true);
    if (!token) {
        throw new Error('Missing bmo.openclaw.token.');
    }
    const messages = [...history];
    const contextBits = [];
    const folder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    const editor = vscode.window.activeTextEditor;
    if (includeWorkspacePath && folder) {
        contextBits.push(`Workspace: ${folder}`);
    }
    if (editor) {
        contextBits.push(`Active file: ${editor.document.uri.fsPath}`);
    }
    if (contextBits.length > 0) {
        messages.unshift({ role: 'system', content: contextBits.join('\n') });
    }
    const response = await fetch(`${baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
            model,
            user,
            messages,
            stream: false
        })
    });
    if (!response.ok) {
        const body = await response.text();
        throw new Error(`HTTP ${response.status}: ${body.slice(0, 400)}`);
    }
    const json = (await response.json());
    const content = extractContent(json);
    if (!content) {
        if (json.error?.message)
            throw new Error(json.error.message);
        throw new Error('No assistant message returned.');
    }
    return content;
}
function extractContent(json) {
    const content = json.choices?.[0]?.message?.content;
    if (typeof content === 'string')
        return content;
    if (Array.isArray(content)) {
        return content.map((part) => part.text ?? '').join('').trim();
    }
    return '';
}
function buildSelectionPrompt() {
    const editor = vscode.window.activeTextEditor;
    if (!editor)
        return undefined;
    const selection = editor.selection;
    if (selection.isEmpty)
        return undefined;
    const text = editor.document.getText(selection);
    const file = editor.document.uri.fsPath;
    const language = editor.document.languageId;
    return `Please help with this selected code from ${file}.\n\n\
\`\`\`${language}\n${text}\n\`\`\``;
}
async function buildCurrentFilePrompt() {
    const editor = vscode.window.activeTextEditor;
    if (!editor)
        return undefined;
    const config = vscode.workspace.getConfiguration('bmo');
    const maxChars = Number(config.get('chat.maxFileChars') ?? 12000);
    const file = editor.document.uri.fsPath;
    const language = editor.document.languageId;
    const raw = editor.document.getText();
    const text = raw.length > maxChars ? `${raw.slice(0, maxChars)}\n\n[truncated]` : raw;
    const relative = vscode.workspace.asRelativePath(file);
    return `Please help with this file: ${relative}\n\n\
\`\`\`${language}\n${text}\n\`\`\``;
}
//# sourceMappingURL=extension.js.map