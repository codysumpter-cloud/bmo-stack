import * as vscode from 'vscode';

interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

interface OpenClawChatChoice {
  message?: {
    content?: string | Array<{ type?: string; text?: string }>;
  };
  delta?: {
    content?: string | Array<{ type?: string; text?: string }>;
  };
}

interface OpenClawChatResponse {
  choices?: OpenClawChatChoice[];
  error?: { message?: string };
}

// Agent and model configuration
interface AgentConfig {
  id: string;
  name: string;
  emoji: string;
  model: string;
}

const AVAILABLE_AGENTS: AgentConfig[] = [
  { id: 'main', name: 'BMO', emoji: '🤖', model: 'openai-codex/gpt-5.4' },
  { id: 'bmo-tron', name: 'BMO Secure Worker', emoji: '🛡️', model: 'nvidia/openai/gpt-oss-120b' },
  { id: 'prismo', name: 'Prismo', emoji: '🌀', model: 'openai-codex/gpt-5.4' },
  { id: 'neptr', name: 'NEPTR', emoji: '🧪', model: 'ollama/gemma4:latest' },
  { id: 'princess-bubblegum', name: 'Princess Bubblegum', emoji: '🧬', model: 'nvidia/meta/llama-3.3-70b-instruct' },
  { id: 'finn', name: 'Finn', emoji: '🗡️', model: 'ollama/gemma4:e2b' },
  { id: 'jake', name: 'Jake', emoji: '🟡', model: 'ollama/llama3.2:3b' },
  { id: 'marceline', name: 'Marceline', emoji: '🎸', model: 'ollama/gemma4:e2b' },
  { id: 'simon', name: 'Simon', emoji: '📚', model: 'ollama/gemma4:latest' },
  { id: 'peppermint-butler', name: 'Peppermint Butler', emoji: '🕯️', model: 'nvidia/meta/llama-3.3-70b-instruct' },
  { id: 'lady-rainicorn', name: 'Lady Rainicorn', emoji: '🌈', model: 'nvidia/openai/gpt-oss-120b' },
  { id: 'lemongrab', name: 'Lemongrab', emoji: '🍋', model: 'ollama/omni-core:phase2' },
  { id: 'flame-princess', name: 'Flame Princess', emoji: '🔥', model: 'ollama/omni-core:phase3' },
  { id: 'huntress-wizard', name: 'Huntress Wizard', emoji: '🏹', model: 'ollama/omni-core:phase3' }
];

// Default agent
let CURRENT_AGENT = AVAILABLE_AGENTS.find(agent => agent.id === 'main') || AVAILABLE_AGENTS[0];

export function activate(context: vscode.ExtensionContext) {
  const panel = new BmoChatPanel();

  context.subscriptions.push(
    vscode.commands.registerCommand('bmo.openChat', async () => {
      await panel.show();
    }),
    vscode.commands.registerCommand('bmo.askAboutSelection', async () => {
      await panel.show();
      const seed = buildSelectionPrompt();
      if (!seed) {
        void vscode.window.showInformationMessage('No editor selection found.');
        return;
      }
      panel.seedComposer(seed);
    }),
    vscode.commands.registerCommand('bmo.askAboutCurrentFile', async () => {
      await panel.show();
      const seed = await buildCurrentFilePrompt();
      if (!seed) {
        void vscode.window.showInformationMessage('No active file found.');
        return;
      }
      panel.seedComposer(seed);
    }),
    vscode.commands.registerCommand('bmo.rewriteSelection', async () => {
      await rewriteSelection();
    })
  );
}

export function deactivate() {}

class BmoChatPanel {
  private panel: vscode.WebviewPanel | undefined;
  private readonly messages: ChatMessage[] = [
    {
      role: 'assistant',
      content: 'BMO is ready. Ask something, or use Ask About Selection / Ask About Current File / Rewrite Selection.'
    }
  ];
  private busy = false;

  async show() {
    if (!this.panel) {
      this.panel = vscode.window.createWebviewPanel(
        'bmoChat',
        'BMO Chat',
        vscode.ViewColumn.Beside,
        {
          enableScripts: true,
          retainContextWhenHidden: true
        }
      );

      this.panel.webview.html = this.getHtml();
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

  seedComposer(text: string) {
    this.panel?.webview.postMessage({ type: 'seed', text });
  }

  private async handleSend(rawText: string) {
    const text = rawText.trim();
    if (!text || this.busy) return;

    this.busy = true;
    this.messages.push({ role: 'user', content: text });
    this.messages.push({ role: 'assistant', content: '' });
    const assistantIndex = this.messages.length - 1;
    this.pushState('BMO is thinking...');

    try {
      await callOpenClawStream(this.messages.slice(0, -1), (delta) => {
        this.messages[assistantIndex].content += delta;
        this.pushState('Streaming reply...');
      });

      if (!this.messages[assistantIndex].content.trim()) {
        this.messages[assistantIndex].content = 'No assistant message returned.';
      }
      this.pushState();
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.messages[assistantIndex].content =
        `Couldn’t reach OpenClaw. ${message}\n\n` +
        `Check: (1) the gateway is running, (2) chat completions are enabled, and (3) bmo.openclaw.token is set.`;
      this.pushState();
    } finally {
      this.busy = false;
      this.pushState();
    }
  }

  private pushState(status?: string) {
    this.panel?.webview.postMessage({
      type: 'state',
      messages: this.messages,
      busy: this.busy,
      status: status ?? (this.busy ? 'Working...' : 'Ready')
    });
  }

  private getHtml() {
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
    .actions { display: flex; align-items: center; justify-content: space-between; gap: 12px; }
    button { border: 0; border-radius: 6px; padding: 8px 12px; cursor: pointer; background: var(--vscode-button-background); color: var(--vscode-button-foreground); }
    button[disabled] { opacity: 0.6; cursor: default; }
    .hint { font-size: 12px; opacity: 0.75; }
    .status { font-size: 12px; opacity: 0.75; }
  </style>
</head>
<body>
  <div class="wrap">
    <div id="messages" class="messages"></div>
    <div class="composer">
      <div class="hint">Thin local shell over OpenClaw. Configure base URL + token in VS Code settings.</div>
      <textarea id="input" placeholder="Ask BMO about this project..."></textarea>
      <div class="actions">
        <div id="status" class="status">Ready</div>
        <button id="send">Send</button>
      </div>
    </div>
  </div>
  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    const messagesEl = document.getElementById('messages');
    const inputEl = document.getElementById('input');
    const sendEl = document.getElementById('send');
    const statusEl = document.getElementById('status');

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
      if (!text.trim() || sendEl.disabled) return;
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
      if (msg.type === 'state') {
        render(msg.messages || []);
        sendEl.disabled = !!msg.busy;
        statusEl.textContent = msg.status || 'Ready';
      }
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

async function callOpenClawStream(history: ChatMessage[], onDelta: (text: string) => void): Promise<void> {
  const config = vscode.workspace.getConfiguration('bmo');
  const baseUrl = String(config.get('openclaw.baseUrl') ?? 'http://127.0.0.1:18789/v1').replace(/\/$/, '');
  const token = String(config.get('openclaw.token') ?? '').trim();
  const model = String(config.get('openclaw.model') ?? 'openclaw/default');
  const user = String(config.get('openclaw.user') ?? 'vscode-bmo');
  const includeWorkspacePath = Boolean(config.get('openclaw.includeWorkspacePath') ?? true);

  if (!token) throw new Error('Missing bmo.openclaw.token.');

  const messages = withEditorContext(history, includeWorkspacePath);
  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({
      model,
      user,
      messages,
      stream: true
    })
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`HTTP ${response.status}: ${body.slice(0, 400)}`);
  }

  const reader = response.body?.getReader();
  if (!reader) throw new Error('Streaming response body unavailable.');

  const decoder = new TextDecoder();
  let buffer = '';

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });

    const parts = buffer.split('\n\n');
    buffer = parts.pop() ?? '';

    for (const part of parts) {
      const lines = part
        .split('\n')
        .map((line) => line.trim())
        .filter((line) => line.startsWith('data:'));

      for (const line of lines) {
        const payload = line.slice(5).trim();
        if (!payload || payload === '[DONE]') continue;
        const parsed = JSON.parse(payload) as OpenClawChatResponse;
        const delta = extractStreamContent(parsed);
        if (delta) onDelta(delta);
      }
    }
  }
}

async function callOpenClaw(history: ChatMessage[]): Promise<string> {
  const config = vscode.workspace.getConfiguration('bmo');
  const baseUrl = String(config.get('openclaw.baseUrl') ?? 'http://127.0.0.1:18789/v1').replace(/\/$/, '');
  const token = String(config.get('openclaw.token') ?? '').trim();
  const model = String(config.get('openclaw.model') ?? 'openclaw/default');
  const user = String(config.get('openclaw.user') ?? 'vscode-bmo');
  const includeWorkspacePath = Boolean(config.get('openclaw.includeWorkspacePath') ?? true);

  if (!token) throw new Error('Missing bmo.openclaw.token.');

  const response = await fetch(`${baseUrl}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`
    },
    body: JSON.stringify({
      model,
      user,
      messages: withEditorContext(history, includeWorkspacePath),
      stream: false
    })
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`HTTP ${response.status}: ${body.slice(0, 400)}`);
  }

  const json = (await response.json()) as OpenClawChatResponse;
  const content = extractContent(json);
  if (!content) {
    if (json.error?.message) throw new Error(json.error.message);
    throw new Error('No assistant message returned.');
  }
  return content;
}

function withEditorContext(history: ChatMessage[], includeWorkspacePath: boolean): ChatMessage[] {
  const messages = [...history];
  const contextBits: string[] = [];
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

  return messages;
}

function extractContent(json: OpenClawChatResponse): string {
  const content = json.choices?.[0]?.message?.content;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) return content.map((part) => part.text ?? '').join('').trim();
  return '';
}

function extractStreamContent(json: OpenClawChatResponse): string {
  const content = json.choices?.[0]?.delta?.content;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) return content.map((part) => part.text ?? '').join('');
  return '';
}

function buildSelectionPrompt(): string | undefined {
  const editor = vscode.window.activeTextEditor;
  if (!editor) return undefined;
  const selection = editor.selection;
  if (selection.isEmpty) return undefined;
  const text = editor.document.getText(selection);
  const file = editor.document.uri.fsPath;
  const language = editor.document.languageId;
  return `Please help with this selected code from ${file}.\n\n\`\`\`${language}\n${text}\n\`\`\``;
}

async function buildCurrentFilePrompt(): Promise<string | undefined> {
  const editor = vscode.window.activeTextEditor;
  if (!editor) return undefined;
  const config = vscode.workspace.getConfiguration('bmo');
  const maxChars = Number(config.get('chat.maxFileChars') ?? 12000);
  const file = editor.document.uri.fsPath;
  const language = editor.document.languageId;
  const raw = editor.document.getText();
  const text = raw.length > maxChars ? `${raw.slice(0, maxChars)}\n\n[truncated]` : raw;
  const relative = vscode.workspace.asRelativePath(file);
  return `Please help with this file: ${relative}\n\n\`\`\`${language}\n${text}\n\`\`\``;
}

async function rewriteSelection(): Promise<void> {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    void vscode.window.showInformationMessage('No active editor found.');
    return;
  }

  const selection = editor.selection;
  if (selection.isEmpty) {
    void vscode.window.showInformationMessage('Select some code first.');
    return;
  }

  const instruction = await vscode.window.showInputBox({
    prompt: 'How should BMO rewrite this selection?',
    placeHolder: 'Example: simplify this, keep behavior the same, and add clearer names'
  });
  if (!instruction?.trim()) return;

  const document = editor.document;
  const selectedText = document.getText(selection);
  const language = document.languageId;
  const relative = vscode.workspace.asRelativePath(document.uri);

  try {
    await vscode.window.withProgress(
      {
        location: vscode.ProgressLocation.Notification,
        title: 'BMO rewriting selection',
        cancellable: false
      },
      async () => {
        const prompt = [
          `Rewrite the following selected code from ${relative}.`,
          `Instruction: ${instruction.trim()}`,
          '',
          'Return only the rewritten code in a single fenced code block. No explanation.',
          '',
          `\`\`\`${language}`,
          selectedText,
          '\`\`\`'
        ].join('\n');

        const reply = await callOpenClaw([{ role: 'user', content: prompt }]);
        const replacement = extractReplacement(reply).trimEnd();
        if (!replacement) {
          throw new Error('Model returned no replacement text.');
        }

        await showSnippetDiff(selectedText, replacement, language);
        const choice = await vscode.window.showInformationMessage(
          'Apply BMO rewrite to the selected code?',
          { modal: true },
          'Apply',
          'Cancel'
        );

        if (choice !== 'Apply') return;

        await editor.edit((editBuilder) => {
          editBuilder.replace(selection, replacement);
        });
        void vscode.window.showInformationMessage('Selection rewritten.');
      }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    void vscode.window.showErrorMessage(`BMO rewrite failed: ${message}`);
  }
}

async function showSnippetDiff(original: string, replacement: string, language: string): Promise<void> {
  const left = await vscode.workspace.openTextDocument({ content: original, language });
  const right = await vscode.workspace.openTextDocument({ content: replacement, language });
  await vscode.commands.executeCommand(
    'vscode.diff',
    left.uri,
    right.uri,
    'BMO Rewrite Preview'
  );
}

function extractReplacement(reply: string): string {
  const fenced = reply.match(/```[a-zA-Z0-9_-]*\n([\s\S]*?)```/);
  if (fenced?.[1]) return fenced[1];
  return reply.trim();
}
