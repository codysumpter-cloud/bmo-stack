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
  fail("usage: node scripts/release-gate-generated-app.mjs <generated-app-directory>");
}

const appDir = path.resolve(process.cwd(), targetDir);
const scorecard = readJson(path.join(appDir, "generated-app-scorecard.json"));
const proofBundle = readJson(path.join(appDir, "generated-app-proof-bundle.json"));
const releaseGate = readJson(path.join(appDir, "generated-app-release-gate.json"));

const blocking = [];
if (scorecard.status === "fail") blocking.push("scorecard-failed");
if (!Array.isArray(proofBundle.testCommands) || proofBundle.testCommands.length === 0) blocking.push("missing-proof-commands");
if (!releaseGate.approvedBy || releaseGate.decision === "fail") blocking.push("release-gate-failed");
if (Array.isArray(scorecard.blockers) && scorecard.blockers.length > 0) blocking.push("scorecard-blockers-present");

const decision = blocking.length > 0 ? "fail" : releaseGate.decision === "warning" ? "warning" : "pass";

console.log(JSON.stringify({
  appId: scorecard.appId,
  decision,
  blocking,
  approvedBy: releaseGate.approvedBy,
  notes: releaseGate.notes || []
}, null, 2));
