#!/usr/bin/env node
import { dispatchCodexTask } from "../tools/dispatchCodexTask.js";

function readArgs(argv) {
  const args = {};
  for (let index = 2; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--")) {
      continue;
    }
    const key = token.slice(2).replace(/-/g, "_");
    const next = argv[index + 1];
    if (!next || next.startsWith("--")) {
      args[key] = true;
      continue;
    }
    args[key] = next;
    index += 1;
  }
  return args;
}

const args = readArgs(process.argv);

try {
  const result = await dispatchCodexTask({
    repo_path: args.repo_path,
    task_brief: args.task_brief,
    target_branch: args.target_branch,
    approval_mode: args.approval_mode,
    model: args.model,
    run_id: args.run_id,
  });
  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
} catch (error) {
  process.stderr.write(`${error instanceof Error ? error.stack || error.message : String(error)}\n`);
  process.exitCode = 1;
}
