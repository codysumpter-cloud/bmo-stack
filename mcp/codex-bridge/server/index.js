import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

import { dispatchCodexTask } from "./tools/dispatchCodexTask.js";
import { getCodexRunStatus } from "./tools/getCodexRunStatus.js";
import { readCodexRunResult } from "./tools/readCodexRunResult.js";

function asToolResult(payload) {
  return {
    content: [
      {
        type: "text",
        text: JSON.stringify(payload, null, 2)
      }
    ]
  };
}

const server = new McpServer({
  name: "bmo-codex-bridge",
  version: "0.1.0"
});

server.tool(
  "dispatch_codex_task",
  "Create a git worktree, write a task brief, and run Codex CLI against that isolated worktree.",
  {
    repo_path: z.string().describe("Absolute path to the target git repository."),
    task_brief: z.string().describe("The task prompt to send to Codex."),
    target_branch: z.string().optional().describe("Optional branch name. If omitted, the bridge generates one."),
    approval_mode: z.enum(["suggest", "auto_edit", "full_auto"]).optional().describe("Codex approval mode. Defaults to suggest."),
    model: z.string().optional().describe("Optional Codex model override, for example codex-mini-latest or gpt-5-codex.")
  },
  async (args) => asToolResult(await dispatchCodexTask(args))
);

server.tool(
  "get_codex_run_status",
  "Read the current status for a prior Codex bridge run, including a tail of stdout/stderr logs.",
  {
    run_id: z.string().describe("Run identifier returned by dispatch_codex_task."),
    log_lines: z.number().int().min(1).max(200).optional().describe("Number of stdout/stderr lines to return. Defaults to 40.")
  },
  async (args) => asToolResult(await getCodexRunStatus(args))
);

server.tool(
  "read_codex_run_result",
  "Read the final structured result for a completed or failed Codex bridge run.",
  {
    run_id: z.string().describe("Run identifier returned by dispatch_codex_task.")
  },
  async (args) => asToolResult(await readCodexRunResult(args))
);

const transport = new StdioServerTransport();
await server.connect(transport);
