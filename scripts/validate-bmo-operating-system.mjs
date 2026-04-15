#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function read(file) {
  const full = path.join(root, file);
  if (!fs.existsSync(full)) fail(`missing file: ${file}`);
  return fs.readFileSync(full, "utf8");
}

function section(text, heading, label) {
  const start = text.indexOf(heading);
  if (start === -1) fail(`${label} is missing section: ${heading}`);
  const remaining = text.slice(start + heading.length);
  const nextHeading = remaining.search(/\n## /);
  return nextHeading === -1 ? remaining : remaining.slice(0, nextHeading);
}

function ensureContainsInOrder(text, tokens, label) {
  let cursor = -1;
  for (const token of tokens) {
    const next = text.indexOf(token, cursor + 1);
    if (next === -1) fail(`${label} is missing or misordered token: ${token}`);
    cursor = next;
  }
}

const requiredFiles = [
  "AGENTS.md",
  "memory.md",
  "soul.md",
  "routines.md",
  "RESPONSE_GUIDE.md",
  "HEARTBEAT.md",
  "scripts/bmo-continuity-report.mjs",
  "scripts/configure-openclaw-agents.sh",
  "scripts/sync-openclaw-workspaces.sh",
  "context/BOOTSTRAP.md",
  "context/continuity/README.md",
  "context/identity/AGENTS.md",
  "context/identity/SOUL.md",
  "context/identity/USER.md",
  "context/identity/IDENTITY.md",
  "context/SESSION_STATE.md",
  "context/RUNBOOK.md",
  "context/skills/SKILLS.md",
  "context/skills/context-bootstrap.skill.md",
  "context/skills/donor-ingest.skill.md",
  "context/donors/DONORS.yaml",
  "context/donors/BMO_FEATURE_CARRYOVER.md",
  "docs/BMO_ROUTINES.md",
  "config/routines/bmo-core-routines.json",
  "TASK_STATE.md",
  "WORK_IN_PROGRESS.md",
];

for (const file of requiredFiles) {
  read(file);
}

const dailyMemoryNotes = fs
  .readdirSync(path.join(root, "memory"), { withFileTypes: true })
  .filter((entry) => entry.isFile() && /^\d{4}-\d{2}-\d{2}\.md$/.test(entry.name))
  .map((entry) => entry.name)
  .sort();

for (const noteName of dailyMemoryNotes) {
  const relativePath = `memory/${noteName}`;
  const expectedHeading = `# ${noteName.replace(/\.md$/, "")}`;
  const note = read(relativePath);
  if (!note.includes(expectedHeading)) {
    fail(`${relativePath} must include heading: ${expectedHeading}`);
  }
}

const startupSequence = [
  "`memory.md`",
  "`soul.md`",
  "`routines.md`",
  "`RESPONSE_GUIDE.md`",
  "`context/identity/AGENTS.md`",
  "`context/identity/SOUL.md`",
  "`context/identity/USER.md`",
  "`context/identity/IDENTITY.md`",
  "`context/SESSION_STATE.md`",
  "`context/SYSTEMMAP.md`",
  "`context/RUNBOOK.md`",
  "`context/BACKLOG.md`",
  "`context/skills/SKILLS.md`",
  "`skills/README.md`",
  "`memory/YYYY-MM-DD.md`",
  "`TASK_STATE.md`",
  "`WORK_IN_PROGRESS.md`",
];

const agents = read("AGENTS.md");
ensureContainsInOrder(
  section(agents, "## Authoritative Startup Sequence", "AGENTS.md"),
  startupSequence,
  "AGENTS.md startup sequence",
);

const identityAgents = read("context/identity/AGENTS.md");
ensureContainsInOrder(
  section(identityAgents, "## Authoritative Startup Sequence", "context/identity/AGENTS.md"),
  ["`AGENTS.md`", ...startupSequence],
  "context/identity/AGENTS.md startup sequence",
);

const runbook = read("context/RUNBOOK.md");
ensureContainsInOrder(
  section(runbook, "## Restart recovery protocol", "context/RUNBOOK.md"),
  ["`AGENTS.md`", ...startupSequence],
  "context/RUNBOOK.md startup sequence",
);
if (!runbook.includes("`skills/index.json`")) {
  fail("context/RUNBOOK.md must mention skills/index.json for machine-readable skill lookup");
}

const bootstrap = read("context/BOOTSTRAP.md");
for (const token of [
  "`AGENTS.md`",
  "`context/RUNBOOK.md`",
  "`context/skills/SKILLS.md`",
  "`skills/README.md`",
  "`TASK_STATE.md`",
  "`WORK_IN_PROGRESS.md`",
  "`python3 scripts/bmo-workspace-sync.py",
]) {
  if (!bootstrap.includes(token)) fail(`context/BOOTSTRAP.md must mention ${token}`);
}

const sessionState = read("context/SESSION_STATE.md");
for (const token of [
  "`AGENTS.md`",
  "`context/RUNBOOK.md`",
  "`context/continuity/live-status.json`",
  "`TASK_STATE.md`",
  "`WORK_IN_PROGRESS.md`",
]) {
  if (!sessionState.includes(token)) fail(`context/SESSION_STATE.md must mention ${token}`);
}

const routines = read("routines.md");
ensureContainsInOrder(
  section(routines, "## Preferred routine order", "routines.md"),
  [
    "`make doctor-plus`",
    "`make worker-status`",
    "`make runtime-doctor`",
    "`make workspace-sync`",
    "`make site-caretaker`",
    "`make worker-ready`",
  ],
  "routines.md routine order",
);

const routineDocs = read("docs/BMO_ROUTINES.md");
ensureContainsInOrder(
  section(routineDocs, "## Core routines", "docs/BMO_ROUTINES.md"),
  [
    "`doctor-plus`",
    "`worker-status`",
    "`runtime-doctor`",
    "`workspace-sync`",
    "`site-caretaker`",
    "`worker-ready`",
  ],
  "docs/BMO_ROUTINES.md routine order",
);

const routinePack = JSON.parse(read("config/routines/bmo-core-routines.json"));
const expectedRoutineNames = [
  "doctor-plus",
  "worker-status",
  "runtime-doctor",
  "workspace-sync",
  "site-caretaker",
  "worker-ready",
];
const actualRoutineNames = routinePack.routines.map((routine) => routine.name);
if (JSON.stringify(actualRoutineNames) !== JSON.stringify(expectedRoutineNames)) {
  fail(
    `config/routines/bmo-core-routines.json routine order is ${actualRoutineNames.join(", ")}, expected ${expectedRoutineNames.join(", ")}`,
  );
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

for (const file of ["scripts/configure-openclaw-agents.sh", "scripts/sync-openclaw-workspaces.sh"]) {
  const script = read(file);
  if (!script.includes("memory.md") || !script.includes("WORKER_WORKSPACE")) {
    fail(`${file} must handle worker memory.md propagation explicitly`);
  }
}

const workspaceSync = read("scripts/bmo-workspace-sync.py");
for (const token of ["BMO_WORKSPACE_SYNC_OUTPUT", "resolve_workspace_path", "workspace_dir / path"]) {
  if (!workspaceSync.includes(token)) {
    fail(`scripts/bmo-workspace-sync.py must resolve launchd output paths relative to the workspace: missing ${token}`);
  }
}

const launchdInstall = read("scripts/bmo-launchd-install.py");
if (!launchdInstall.includes("BMO_WORKSPACE_SYNC_OUTPUT")) {
  fail("scripts/bmo-launchd-install.py must export BMO_WORKSPACE_SYNC_OUTPUT for launchd installs");
}

const macbookDoc = read("docs/BMO_ON_MY_MACBOOK.md");
if (!macbookDoc.includes("Do not paste the placeholder string")) {
  fail("docs/BMO_ON_MY_MACBOOK.md must warn against pasting the placeholder continuity token");
}

console.log("bmo operating system files are valid");
