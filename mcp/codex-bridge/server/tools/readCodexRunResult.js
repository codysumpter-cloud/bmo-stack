import fs from "node:fs/promises";

import { getRunPaths, pathExists, readJson } from "../lib/bridge.js";

export async function readCodexRunResult({ run_id: runId }) {
  if (!runId) {
    throw new Error("run_id is required");
  }

  const runPaths = getRunPaths(runId);
  if (!(await pathExists(runPaths.resultPath))) {
    throw new Error(`result not found for run: ${runId}`);
  }

  const result = await readJson(runPaths.resultPath);
  let brief = "";
  if (await pathExists(runPaths.briefPath)) {
    brief = await fs.readFile(runPaths.briefPath, "utf8");
  }

  return {
    ...result,
    brief
  };
}
