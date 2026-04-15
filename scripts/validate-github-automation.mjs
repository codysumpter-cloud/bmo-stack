#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const contractPath = path.join(root, "config", "github", "automation-contract.json");

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function requireString(text, needle, context) {
  if (!text.includes(needle)) fail(`missing '${needle}' in ${context}`);
}

if (!fs.existsSync(contractPath)) fail(`missing automation contract: ${contractPath}`);

const contract = JSON.parse(fs.readFileSync(contractPath, "utf8"));
if (contract.version !== 1) fail("automation contract version must be 1");

for (const relPath of contract.legacy_workflows_absent || []) {
  if (fs.existsSync(path.join(root, relPath))) fail(`legacy workflow should be absent: ${relPath}`);
}

if (!Array.isArray(contract.workers) || contract.workers.length === 0) {
  fail("automation contract must define at least one worker");
}

for (const worker of contract.workers) {
  const workflowPath = path.join(root, worker.workflow_file);
  if (!fs.existsSync(workflowPath)) fail(`missing workflow file: ${worker.workflow_file}`);
  const text = fs.readFileSync(workflowPath, "utf8");
  requireString(text, `name: ${worker.workflow_name}`, worker.workflow_file);
  for (const needle of worker.required_strings || []) {
    requireString(text, needle, worker.workflow_file);
  }
}

const issueToPrText = fs.readFileSync(path.join(root, ".github", "workflows", "issue-to-pr-v2.yml"), "utf8");
const workspaceSyncText = fs.readFileSync(path.join(root, ".github", "workflows", "workspace-sync-on-merge.yml"), "utf8");
requireString(issueToPrText, "autonomy:execute", ".github/workflows/issue-to-pr-v2.yml");
requireString(issueToPrText, "runs-on: ubuntu-latest", ".github/workflows/issue-to-pr-v2.yml");
requireString(workspaceSyncText, "fromJSON(vars.BMO_WORKSPACE_SYNC_RUNS_ON", ".github/workflows/workspace-sync-on-merge.yml");

for (const relPath of contract.docs || []) {
  if (!fs.existsSync(path.join(root, relPath))) fail(`missing automation doc: ${relPath}`);
}

const autonomyDoc = fs.readFileSync(path.join(root, "docs", "GITHUB_AUTONOMY.md"), "utf8");
const workerDoc = fs.readFileSync(path.join(root, "docs", "GITHUB_WORKERS.md"), "utf8");
const adminDoc = fs.readFileSync(path.join(root, "docs", "CODESPACE_GITHUB_WORKER.md"), "utf8");
requireString(autonomyDoc, "BMO_WORKSPACE_SYNC_RUNS_ON", "docs/GITHUB_AUTONOMY.md");
requireString(workerDoc, "config/github/automation-contract.json", "docs/GITHUB_WORKERS.md");
requireString(adminDoc, "BMO_WORKSPACE_SYNC_RUNS_ON", "docs/CODESPACE_GITHUB_WORKER.md");

console.log("github automation contract is valid");
