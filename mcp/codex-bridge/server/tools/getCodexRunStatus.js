import { getRunPaths, pathExists, readJson, tailFile } from "../lib/bridge.js";

export async function getCodexRunStatus({ run_id: runId, log_lines: logLines = 40 }) {
  if (!runId) {
    throw new Error("run_id is required");
  }

  const runPaths = getRunPaths(runId);
  if (!(await pathExists(runPaths.statusPath))) {
    throw new Error(`run not found: ${runId}`);
  }

  const status = await readJson(runPaths.statusPath);
  return {
    ...status,
    stdout_tail: await tailFile(runPaths.stdoutPath, logLines),
    stderr_tail: await tailFile(runPaths.stderrPath, logLines)
  };
}
