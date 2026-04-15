#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function readJson(targetPath) {
  if (!fs.existsSync(targetPath)) fail(`missing file: ${targetPath}`);
  return JSON.parse(fs.readFileSync(targetPath, "utf8"));
}

const targetDir = process.argv[2];
if (!targetDir) {
  fail("usage: node scripts/repair-generated-app-plan.mjs <generated-app-directory>");
}

const appDir = path.resolve(process.cwd(), targetDir);
const scorecard = readJson(path.join(appDir, "generated-app-scorecard.json"));
const releaseGate = readJson(path.join(appDir, "generated-app-release-gate.json"));

const failingDimensions = (scorecard.dimensions || []).filter((item) => item.status === "fail").map((item) => item.key);
const actions = [];

if (failingDimensions.includes("functionality")) {
  actions.push("Audit primary workflows for dead actions, missing navigation, and incomplete task completion paths.");
}
if (failingDimensions.includes("uxCompleteness")) {
  actions.push("Add missing loading, empty, success, blocked, and failure states on primary routes.");
}
if (failingDimensions.includes("reliability")) {
  actions.push("Review retries, save failures, and missing recovery flows before claiming release readiness.");
}
if (failingDimensions.includes("validationEvidence")) {
  actions.push("Capture missing validation commands, screenshots, and artifact references in the proof bundle.");
}
if (failingDimensions.includes("operatorTrust")) {
  actions.push("Remove overclaims, label mock data clearly, and ensure the release gate records explicit approval.");
}

for (const blocker of scorecard.blockers || []) {
  actions.push(`Resolve blocker: ${blocker}`);
}

if ((releaseGate.notes || []).length > 0) {
  actions.push(...releaseGate.notes.map((note) => `Review release note: ${note}`));
}

console.log(JSON.stringify({
  appId: scorecard.appId,
  failingDimensions,
  recommendedActions: actions,
  nextState: actions.length > 0 ? "repair-required" : "review-ready"
}, null, 2));
