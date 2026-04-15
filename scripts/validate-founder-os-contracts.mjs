#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function readJson(relativePath) {
  const absolutePath = path.join(root, relativePath);
  if (!fs.existsSync(absolutePath)) {
    fail(`missing file: ${relativePath}`);
  }
  return JSON.parse(fs.readFileSync(absolutePath, "utf8"));
}

function ensureFile(relativePath) {
  if (!fs.existsSync(path.join(root, relativePath))) {
    fail(`missing file: ${relativePath}`);
  }
}

const founderManifestPath = "config/agents/founder-os.manifest.json";
const schedulePath = "config/scheduler/founder-os-schedule.json";
const routerPath = "config/router/model-routing-policy.json";
const workflowsPath = "config/workflows/founder-os-workflows.json";
const dashboardPath = "config/operator/mission-control.manifest.json";
const contractDocPath = "docs/FOUNDER_OS_CONTRACT.md";

const founderManifest = readJson(founderManifestPath);
const scheduleManifest = readJson(schedulePath);
const routerPolicy = readJson(routerPath);
const workflowManifest = readJson(workflowsPath);
const dashboardManifest = readJson(dashboardPath);

ensureFile(contractDocPath);

if (!Array.isArray(founderManifest.sharedMemoryFiles) || founderManifest.sharedMemoryFiles.length < 5) {
  fail("founder manifest must define at least 5 shared memory files");
}

const roles = founderManifest.roles;
if (!Array.isArray(roles) || roles.length < 9) {
  fail("founder manifest must define at least 9 named roles");
}

const roleIds = new Set();
for (const role of roles) {
  if (!role.id || !role.memoryFile || !role.modelPolicy) {
    fail("each role must include id, memoryFile, and modelPolicy");
  }
  if (roleIds.has(role.id)) {
    fail(`duplicate role id: ${role.id}`);
  }
  roleIds.add(role.id);
  ensureFile(role.memoryFile);
}

for (const relativePath of founderManifest.sharedMemoryFiles) {
  ensureFile(relativePath);
}

const policyIds = new Set((routerPolicy.policies || []).map((policy) => policy.id));
for (const requiredPolicy of ["cheap-reasoner", "deep-research", "coding", "verification", "long-context-synthesis"]) {
  if (!policyIds.has(requiredPolicy)) {
    fail(`router policy missing required bucket: ${requiredPolicy}`);
  }
}

for (const role of roles) {
  if (!policyIds.has(role.modelPolicy)) {
    fail(`role ${role.id} references unknown model policy ${role.modelPolicy}`);
  }
}

const workflowIds = new Set((workflowManifest.workflowTemplates || []).map((workflow) => workflow.id));
for (const requiredWorkflow of ["research-draft-human-approve", "trend-detect-content-brief", "code-implement-review-approve-pr", "bug-monitor-reproduce-triage"]) {
  if (!workflowIds.has(requiredWorkflow)) {
    fail(`workflow manifest missing ${requiredWorkflow}`);
  }
}

const taskDefinitions = scheduleManifest.taskDefinitions || [];
if (taskDefinitions.length < 5) {
  fail("schedule manifest must define at least 5 task definitions");
}

const taskIds = new Set();
for (const task of taskDefinitions) {
  if (taskIds.has(task.id)) {
    fail(`duplicate task definition id: ${task.id}`);
  }
  taskIds.add(task.id);

  if (!roleIds.has(task.ownerRole)) {
    fail(`task ${task.id} references unknown owner role ${task.ownerRole}`);
  }
  if (!workflowIds.has(task.workflowId)) {
    fail(`task ${task.id} references unknown workflow ${task.workflowId}`);
  }
  if (typeof task.schedule !== "string" || task.schedule.trim().length === 0) {
    fail(`task ${task.id} must include a cron schedule`);
  }
}

for (const role of roles) {
  for (const scheduleRef of role.scheduleRefs || []) {
    if (!taskIds.has(scheduleRef)) {
      fail(`role ${role.id} references unknown schedule ${scheduleRef}`);
    }
  }
}

const panelIds = new Set((dashboardManifest.panels || []).map((panel) => panel.id));
for (const requiredPanel of ["active-agents", "current-task", "last-success-failure", "pending-review", "cost-usage", "memory-touched", "latest-artifacts", "blocked-runs"]) {
  if (!panelIds.has(requiredPanel)) {
    fail(`dashboard manifest missing panel ${requiredPanel}`);
  }
}

const contractDoc = fs.readFileSync(path.join(root, contractDocPath), "utf8");
for (const referencedPath of [founderManifestPath, schedulePath, routerPath, workflowsPath, dashboardPath]) {
  if (!contractDoc.includes(referencedPath)) {
    fail(`contract doc must mention ${referencedPath}`);
  }
}

console.log("Founder OS contracts are valid");
