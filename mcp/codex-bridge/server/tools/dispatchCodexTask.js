import fs from "node:fs/promises";
import path from "node:path";

import {
  appendLog,
  approvalModeToFlag,
  assertBranchName,
  assertGitRepository,
  branchExists,
  collectStreamLines,
  ensureRuntimeLayout,
  getRunPaths,
  makeRunId,
  slugify,
  spawnCodex,
  writeJson
} from "../lib/bridge.js";

function extractText(value, depth = 0) {
  if (depth > 4 || value == null) {
    return null;
  }

  if (typeof value === "string") {
    const trimmed = value.trim();
    return trimmed || null;
  }

  if (Array.isArray(value)) {
    const parts = value.map((item) => extractText(item, depth + 1)).filter(Boolean);
    return parts.length ? parts.join("\n") : null;
  }

  if (typeof value === "object") {
    const preferredKeys = [
      "last-assistant-message",
      "last_assistant_message",
      "text",
      "message",
      "content",
      "output",
      "summary"
    ];

    for (const key of preferredKeys) {
      if (key in value) {
        const found = extractText(value[key], depth + 1);
        if (found) {
          return found;
        }
      }
    }

    for (const nested of Object.values(value)) {
      const found = extractText(nested, depth + 1);
      if (found) {
        return found;
      }
    }
  }

  return null;
}

function buildBrief({ repoPath, targetBranch, approvalMode, model, taskBrief }) {
  const lines = [
    "# Codex Task Brief",
    "",
    `- Repo path: ${repoPath}`,
    `- Target branch: ${targetBranch}`,
    `- Approval mode: ${approvalMode}`,
    `- Model: ${model || "default"}`,
    "",
    "## Requested work",
    "",
    taskBrief.trim(),
    ""
  ];

  return lines.join("\n");
}

function buildNextSteps({ status, worktreePath, targetBranch, approvalMode }) {
  if (status === "completed") {
    return [
      `Inspect the generated worktree at ${worktreePath}`,
      `Review branch ${targetBranch} before committing or opening a PR`,
      approvalMode === "suggest"
        ? "Expect proposals or suggested edits; file changes may be minimal in suggest mode"
        : "Run your normal verification commands before promoting the branch"
    ];
  }

  return [
    `Review stdout.log and stderr.log in ${path.dirname(worktreePath)}`,
    "Repair or discard the worktree manually after inspecting the failure",
    "Retry with a smaller prompt or a safer approval mode if needed"
  ];
}

export async function dispatchCodexTask({
  repo_path: repoPath,
  task_brief: taskBrief,
  target_branch: requestedBranch,
  approval_mode: approvalMode = "suggest",
  model = null
}) {
  if (!taskBrief || !String(taskBrief).trim()) {
    throw new Error("task_brief is required");
  }

  await ensureRuntimeLayout();
  await assertGitRepository(repoPath);

  const generatedBranch = `codex/${slugify(taskBrief, "task")}-${Date.now().toString().slice(-6)}`;
  const targetBranch = requestedBranch || generatedBranch;
  await assertBranchName(targetBranch);

  if (await branchExists(repoPath, targetBranch)) {
    throw new Error(`target_branch already exists locally: ${targetBranch}`);
  }

  const runId = makeRunId();
  const runPaths = getRunPaths(runId);
  await fs.mkdir(runPaths.runDir, { recursive: true });

  const startedAt = new Date().toISOString();
  const initialStatus = {
    run_id: runId,
    status: "preparing",
    repo_path: repoPath,
    worktree_path: runPaths.worktreePath,
    target_branch: targetBranch,
    approval_mode: approvalMode,
    model,
    started_at: startedAt,
    finished_at: null,
    exit_code: null,
    last_event_type: null,
    final_agent_message: null,
    usage: null,
    brief_path: runPaths.briefPath,
    stdout_log_path: runPaths.stdoutPath,
    stderr_log_path: runPaths.stderrPath,
    result_path: runPaths.resultPath
  };

  await writeJson(runPaths.statusPath, initialStatus);
  await writeJson(runPaths.metadataPath, {
    ...initialStatus,
    created_by: "bmo-stack codex bridge"
  });
  await fs.writeFile(runPaths.briefPath, buildBrief({ repoPath, targetBranch, approvalMode, model, taskBrief }), "utf8");

  try {
    const { execFile } = await import("node:child_process");
    const { promisify } = await import("node:util");
    const execFileAsync = promisify(execFile);
    await execFileAsync("git", ["-C", repoPath, "worktree", "add", "-b", targetBranch, runPaths.worktreePath, "HEAD"]);
  } catch (error) {
    const failedAt = new Date().toISOString();
    const failure = {
      ...initialStatus,
      status: "failed",
      finished_at: failedAt,
      error: `failed to create worktree: ${error.message}`,
      next_steps: buildNextSteps({ status: "failed", worktreePath: runPaths.worktreePath, targetBranch, approvalMode })
    };
    await writeJson(runPaths.statusPath, failure);
    await writeJson(runPaths.resultPath, failure);
    return failure;
  }

  const codexArgs = ["exec", "--json", approvalModeToFlag(approvalMode)];
  if (model) {
    codexArgs.push("-m", model);
  }
  codexArgs.push(taskBrief);

  const runningStatus = {
    ...initialStatus,
    status: "running"
  };
  await writeJson(runPaths.statusPath, runningStatus);

  const child = spawnCodex(codexArgs, {
    cwd: runPaths.worktreePath,
    env: {
      ...process.env,
      PATH: process.env.PATH || "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
    }
  });

  let lastEventType = null;
  let finalAgentMessage = null;
  let usage = null;

  const stdoutTask = collectStreamLines(child.stdout, async (line) => {
    await appendLog(runPaths.stdoutPath, line);
    try {
      const parsed = JSON.parse(line);
      if (parsed?.type) {
        lastEventType = parsed.type;
      }
      if (parsed?.usage) {
        usage = parsed.usage;
      }
      if (parsed?.type === "agent_message" || parsed?.type === "task_complete" || parsed?.type === "turn.completed") {
        const extracted = extractText(parsed);
        if (extracted) {
          finalAgentMessage = extracted;
        }
      }
    } catch {
      // Leave non-JSON lines in the raw stdout log only.
    }
  });

  const stderrTask = collectStreamLines(child.stderr, async (line) => {
    await appendLog(runPaths.stderrPath, line);
  });

  const exitCode = await new Promise((resolve, reject) => {
    child.on("error", reject);
    child.on("close", resolve);
  });

  await Promise.all([stdoutTask, stderrTask]);

  const finishedAt = new Date().toISOString();
  const status = exitCode === 0 ? "completed" : "failed";
  const result = {
    ...initialStatus,
    status,
    finished_at: finishedAt,
    exit_code: exitCode,
    last_event_type: lastEventType,
    final_agent_message: finalAgentMessage,
    usage,
    command: ["codex", ...codexArgs].join(" "),
    next_steps: buildNextSteps({ status, worktreePath: runPaths.worktreePath, targetBranch, approvalMode })
  };

  await writeJson(runPaths.statusPath, result);
  await writeJson(runPaths.resultPath, result);

  return result;
}
