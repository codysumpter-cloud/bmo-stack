#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const manifestPath = path.join(root, "config", "council", "spawn-manifest.json");
const rosterPath = path.join(root, "context", "council", "roster.yaml");

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function readJson(targetPath) {
  if (!fs.existsSync(targetPath)) fail(`missing file: ${targetPath}`);
  return JSON.parse(fs.readFileSync(targetPath, "utf8"));
}

function loadRosterMembers() {
  const lines = fs.readFileSync(rosterPath, "utf8").split(/\r?\n/);
  const members = [];
  let capture = false;
  for (const line of lines) {
    const stripped = line.trim();
    if (stripped === "members:") {
      capture = true;
      continue;
    }
    if (capture && stripped && !line.startsWith("  ")) break;
    if (capture && stripped.startsWith("- name:")) {
      members.push(stripped.split(":", 2)[1].trim());
    }
  }
  if (!members.length) fail("no members parsed from context/council/roster.yaml");
  return members;
}

function validateManifest() {
  const manifest = readJson(manifestPath);
  if (manifest.version !== 1) fail("council manifest version must be 1");

  const seats = manifest.council_seats;
  const workers = manifest.workers;
  if (!Array.isArray(seats) || seats.length !== 12) {
    fail("council manifest must define exactly 12 council seats");
  }
  if (!Array.isArray(workers) || workers.length < 2) {
    fail("council manifest must define at least 2 named workers");
  }

  const rosterMembers = loadRosterMembers();
  const manifestMembers = seats.map((item) => item.name);
  if (JSON.stringify(rosterMembers) !== JSON.stringify(manifestMembers)) {
    fail(`roster members and council manifest are out of sync: roster=${JSON.stringify(rosterMembers)} manifest=${JSON.stringify(manifestMembers)}`);
  }

  const seen = new Set();
  for (const item of [...seats, ...workers]) {
    if (typeof item.name !== "string" || item.name.trim().length === 0) {
      fail("every council manifest entry must have a non-empty name");
    }
    if (seen.has(item.name)) fail(`duplicate council manifest entry: ${item.name}`);
    seen.add(item.name);

    if (item.spawnable !== true) fail(`${item.name} must be marked spawnable=true`);

    if (typeof item.source_file !== "string" || item.source_file.trim().length === 0) {
      fail(`${item.name} is missing source_file`);
    }
    if (!fs.existsSync(path.join(root, item.source_file))) {
      fail(`${item.name} source file missing: ${item.source_file}`);
    }

    if (item.kind === "github-worker") {
      if (typeof item.workflow_file !== "string" || item.workflow_file.trim().length === 0) {
        fail(`${item.name} is missing workflow_file`);
      }
      if (!fs.existsSync(path.join(root, item.workflow_file))) {
        fail(`${item.name} workflow missing: ${item.workflow_file}`);
      }
    }
  }

  return manifest;
}

function buildSpawnPacket(manifest, name) {
  const item = [...manifest.council_seats, ...manifest.workers].find((entry) => entry.name.toLowerCase() === name.toLowerCase());
  if (!item) fail(`unknown council member or worker: ${name}`);
  const sourcePath = path.join(root, item.source_file);
  return {
    ...item,
    source_markdown: fs.readFileSync(sourcePath, "utf8"),
  };
}

const command = process.argv[2] || "validate";
const name = process.argv[3];
const manifest = validateManifest();

if (command === "validate") {
  console.log("council manifest is valid");
} else if (command === "list") {
  for (const item of manifest.council_seats) {
    console.log(`seat\t${item.name}\t${item.surface}\t${item.default_trigger}`);
  }
  for (const item of manifest.workers) {
    console.log(`worker\t${item.name}\t${item.surface}\t${item.workflow_file || ""}`);
  }
} else if (command === "json") {
  console.log(JSON.stringify(manifest, null, 2));
} else if (command === "spawn-packet") {
  if (!name) fail("spawn-packet requires a council member or worker name");
  console.log(JSON.stringify(buildSpawnPacket(manifest, name), null, 2));
} else {
  fail(`unknown command '${command}'`);
}
