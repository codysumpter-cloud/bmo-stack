#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const benchmarkPath = path.join(root, "config", "quality", "flowcommander-parity-benchmark.json");

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
  fail("usage: node scripts/score-generated-app.mjs <generated-app-directory>");
}

const benchmark = readJson(benchmarkPath);
const appDir = path.resolve(process.cwd(), targetDir);
const scorecardPath = path.join(appDir, "generated-app-scorecard.json");
const proofBundlePath = path.join(appDir, "generated-app-proof-bundle.json");
const releaseGatePath = path.join(appDir, "generated-app-release-gate.json");

const scorecard = readJson(scorecardPath);
const proofBundle = readJson(proofBundlePath);
const releaseGate = readJson(releaseGatePath);

const missingBlockingDimensions = benchmark.blockingDimensions.filter((key) => {
  const dimension = (scorecard.dimensions || []).find((item) => item.key === key);
  return !dimension || dimension.status === "fail";
});

const payload = {
  appId: scorecard.appId,
  benchmarkId: benchmark.benchmarkId,
  totalScore: scorecard.totalScore,
  releaseThreshold: benchmark.releaseThreshold,
  scorePass: scorecard.totalScore >= benchmark.releaseThreshold,
  proofBundlePresent: Boolean(proofBundle.appId && proofBundle.scorecardRef),
  releaseGateDecision: releaseGate.decision,
  missingBlockingDimensions,
  blockers: scorecard.blockers || []
};

console.log(JSON.stringify(payload, null, 2));
