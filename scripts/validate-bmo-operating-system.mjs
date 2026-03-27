#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const today = new Date().toISOString().slice(0, 10);

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function read(file) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) fail(`missing file: ${file}`);
  return fs.readFileSync(full, "utf8");
}

const requiredFiles = [
  "AGENTS.md",
  "memory.md",
  "soul.md",
  "routines.md",
  "RESPONSE_GUIDE.md",
  "HEARTBEAT.md",
  "context/identity/AGENTS.md",
  "context/identity/SOUL.md",
  "context/identity/USER.md",
  "context/identity/IDENTITY.md",
  "context/RUNBOOK.md",
  "context/skills/SKILLS.md",
  "context/skills/context-bootstrap.skill.md",
  "context/skills/donor-ingest.skill.md",
  "context/donors/DONORS.yaml",
  "context/donors/BMO_FEATURE_CARRYOVER.md",
  `memory/${today}.md`,
  "TASK_STATE.md",
  "WORK_IN_PROGRESS.md",
];

for (const file of requiredFiles) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) fail(`missing file: ${file}`);
}

const agents = read("AGENTS.md");
if (!agents.includes("`memory.md`") || !agents.includes("`soul.md`") || !agents.includes("`routines.md`")) {
  fail("AGENTS.md must point to memory.md, soul.md, and routines.md");
}

const runbook = read("context/RUNBOOK.md");
if (!runbook.includes("memory.md") || !runbook.includes("RESPONSE_GUIDE.md")) {
  fail("context/RUNBOOK.md must include the root startup files");
}

const carryover = read("context/donors/BMO_FEATURE_CARRYOVER.md");
if (!carryover.includes("PrismBot") || !carryover.includes("omni-bmo")) {
  fail("BMO feature carryover doc must mention both donor repos");
}

const taskState = read("TASK_STATE.md");
const wip = read("WORK_IN_PROGRESS.md");
for (const stale of ["/home/prismtek/.openclaw/workspace/bmo-stack", "beginner-onboarding"]) {
  if (taskState.includes(stale) || wip.includes(stale)) {
    fail(`stale checkpoint reference still present: ${stale}`);
  }
}

console.log("bmo operating system files are valid");
