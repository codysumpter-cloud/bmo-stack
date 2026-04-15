import { execFile, spawn } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const BRIDGE_ROOT = path.resolve(__dirname, "..", "..");
export const RUNTIME_ROOT = path.join(BRIDGE_ROOT, "runtime");
export const RUNS_ROOT = path.join(RUNTIME_ROOT, "runs");

export function makeRunId() {
  return `${new Date().toISOString().replace(/[-:.TZ]/g, "")}-${crypto.randomBytes(3).toString("hex")}`;
}

export function slugify(value, fallback = "task") {
  const cleaned = String(value || "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);
  return cleaned || fallback;
}

export async function ensureRuntimeLayout() {
  await fs.mkdir(RUNS_ROOT, { recursive: true });
}

export async function pathExists(targetPath) {
  try {
    await fs.access(targetPath);
    return true;
  } catch {
    return false;
  }
}

export function assertAbsolutePath(targetPath, label = "path") {
  if (!path.isAbsolute(targetPath)) {
    throw new Error(`${label} must be an absolute path`);
  }
}

export async function assertGitRepository(repoPath) {
  assertAbsolutePath(repoPath, "repo_path");
  const exists = await pathExists(repoPath);
  if (!exists) {
    throw new Error(`repo_path does not exist: ${repoPath}`);
  }

  try {
    const { stdout } = await execFileAsync("git", ["-C", repoPath, "rev-parse", "--is-inside-work-tree"]);
    if (stdout.trim() !== "true") {
      throw new Error();
    }
  } catch {
    throw new Error(`repo_path is not a git repository: ${repoPath}`);
  }
}

export async function assertBranchName(branchName) {
  if (!branchName || branchName.length > 120) {
    throw new Error("target_branch must be between 1 and 120 characters");
  }

  if (!/^[A-Za-z0-9._/-]+$/.test(branchName)) {
    throw new Error("target_branch may only contain letters, numbers, ., _, /, and -");
  }

  if (branchName.startsWith("/") || branchName.endsWith("/") || branchName.includes("..") || branchName.includes("//") || branchName.includes("@{") || branchName.includes("\\")) {
    throw new Error("target_branch is not a valid git branch name");
  }

  try {
    await execFileAsync("git", ["check-ref-format", "--branch", branchName]);
  } catch {
    throw new Error("target_branch is not a valid git branch name");
  }
}

export async function branchExists(repoPath, branchName) {
  try {
    await execFileAsync("git", ["-C", repoPath, "show-ref", "--verify", "--quiet", `refs/heads/${branchName}`]);
    return true;
  } catch {
    return false;
  }
}

export async function writeJson(filePath, data) {
  await fs.writeFile(filePath, `${JSON.stringify(data, null, 2)}\n`, "utf8");
}

export async function readJson(filePath) {
  const raw = await fs.readFile(filePath, "utf8");
  return JSON.parse(raw);
}

export async function tailFile(filePath, lineCount = 40) {
  if (!(await pathExists(filePath))) {
    return "";
  }

  const raw = await fs.readFile(filePath, "utf8");
  const lines = raw.split(/\r?\n/).filter(Boolean);
  return lines.slice(-Math.max(1, lineCount)).join("\n");
}

export function getRunPaths(runId) {
  const runDir = path.join(RUNS_ROOT, runId);
  return {
    runDir,
    worktreePath: path.join(runDir, "worktree"),
    briefPath: path.join(runDir, "brief.md"),
    statusPath: path.join(runDir, "status.json"),
    resultPath: path.join(runDir, "result.json"),
    stdoutPath: path.join(runDir, "stdout.log"),
    stderrPath: path.join(runDir, "stderr.log"),
    metadataPath: path.join(runDir, "metadata.json")
  };
}

export function approvalModeToFlag(mode) {
  switch (mode) {
    case "suggest":
      return "--suggest";
    case "auto_edit":
      return "--auto-edit";
    case "full_auto":
      return "--full-auto";
    default:
      throw new Error(`unsupported approval_mode: ${mode}`);
  }
}

export async function appendLog(filePath, line) {
  await fs.appendFile(filePath, `${line}\n`, "utf8");
}

export async function collectStreamLines(stream, onLine) {
  let buffer = "";
  for await (const chunk of stream) {
    buffer += chunk.toString();
    const parts = buffer.split(/\r?\n/);
    buffer = parts.pop() || "";
    for (const part of parts) {
      await onLine(part);
    }
  }
  if (buffer) {
    await onLine(buffer);
  }
}

export function spawnCodex(args, options) {
  return spawn("codex", args, {
    ...options,
    stdio: ["ignore", "pipe", "pipe"]
  });
}
