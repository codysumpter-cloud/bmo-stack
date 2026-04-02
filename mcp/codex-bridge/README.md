# BMO Codex Bridge

`mcp/codex-bridge` is a repo-local MCP server for dispatching Codex CLI work from BMO workflows.

It creates an isolated git worktree for each run, writes a task brief into the run folder, invokes `codex exec`, and stores structured artifacts under `runtime/runs/`.

## Tools

- `dispatch_codex_task`
  - validates the target repo path
  - validates or generates a target branch name
  - creates a git worktree under `runtime/runs/<run_id>/worktree`
  - writes `brief.md`, `status.json`, `metadata.json`, and log files
  - runs `codex exec --json` with the requested approval mode
- `get_codex_run_status`
  - returns the current status plus stdout/stderr log tails
- `read_codex_run_result`
  - returns the final structured result and the original brief

## Layout

```text
mcp/codex-bridge/
├── .gitignore
├── README.md
├── package.json
├── runtime/
│   └── runs/
│       └── .gitkeep
├── server/
│   ├── index.js
│   ├── lib/
│   │   └── bridge.js
│   └── tools/
│       ├── dispatchCodexTask.js
│       ├── getCodexRunStatus.js
│       └── readCodexRunResult.js
└── templates/
    └── .gitkeep
```

## Prerequisites

1. Node.js 18+
2. Install the bridge dependencies:

   ```bash
   cd -- /absolute/path/to/bmo-stack/mcp/codex-bridge || exit 1
   npm install
   ```

3. Install Codex CLI:

   ```bash
   npm install --global @openai/codex
   ```

4. Authenticate Codex CLI:

   ```bash
   codex --login
   ```

## Claude Code registration

Add this to your Claude Code MCP config, replacing `<BMO_STACK_ROOT>` with the absolute path to your checkout:

```json
{
  "mcpServers": {
    "bmo-codex-bridge": {
      "command": "/opt/homebrew/bin/node",
      "args": ["<BMO_STACK_ROOT>/mcp/codex-bridge/server/index.js"],
      "env": {
        "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
      }
    }
  }
}
```

If your `node` binary lives elsewhere, point `command` at the correct absolute path.

## First test

Start with a small git repo and `approval_mode: "suggest"`.

Example dispatch payload:

```json
{
  "repo_path": "/absolute/path/to/repo",
  "task_brief": "Explain the repo structure and suggest one safe cleanup.",
  "approval_mode": "suggest"
}
```

Suggested validation sequence:

1. Confirm the MCP server registers in Claude Code.
2. Dispatch a task against a small repo.
3. Read the returned `run_id`.
4. Call `get_codex_run_status` while the task is running or immediately after it finishes.
5. Call `read_codex_run_result` to inspect the final result, branch name, worktree path, and next steps.

## Guardrails

The bridge rejects:

- relative `repo_path` values
- paths that are not git repositories
- invalid git branch names
- reusing an existing local branch name for a new dispatched run
- reading unknown run ids

## Runtime artifacts

Each run writes artifacts under:

```text
mcp/codex-bridge/runtime/runs/<run_id>/
```

Typical contents:

- `brief.md`
- `metadata.json`
- `status.json`
- `result.json`
- `stdout.log`
- `stderr.log`
- `worktree/`

## Limitations

- Codex CLI must already be installed and authenticated.
- Dispatch is synchronous right now. `dispatch_codex_task` blocks until `codex exec` exits.
- Worktrees are intentionally left in place for manual review and cleanup.
- The bridge does not manage concurrent queues; each dispatch is independent.
- In `suggest` mode, Codex may leave you with proposals or minimal file changes rather than directly applying edits.
