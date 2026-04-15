#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const routinesPath = path.join(root, "config", "routines", "bmo-core-routines.json");

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function loadRoutines() {
  if (!fs.existsSync(routinesPath)) fail(`missing routines file: ${routinesPath}`);
  const payload = JSON.parse(fs.readFileSync(routinesPath, "utf8"));
  if (payload.version !== 1) fail("routine pack version must be 1");
  if (!Array.isArray(payload.routines) || payload.routines.length === 0) {
    fail("routine pack must contain at least one routine");
  }

  const seen = new Set();
  for (const routine of payload.routines) {
    if (typeof routine.name !== "string" || routine.name.trim().length === 0) {
      fail("every routine must have a non-empty name");
    }
    if (seen.has(routine.name)) fail(`duplicate routine name: ${routine.name}`);
    seen.add(routine.name);
    if (typeof routine.command !== "string" || routine.command.trim().length === 0) {
      fail(`routine '${routine.name}' is missing command`);
    }
    if (typeof routine.purpose !== "string" || routine.purpose.trim().length === 0) {
      fail(`routine '${routine.name}' is missing purpose`);
    }
    if (!Array.isArray(routine.related_files) || routine.related_files.length === 0) {
      fail(`routine '${routine.name}' must include related_files`);
    }
    for (const relPath of routine.related_files) {
      if (!fs.existsSync(path.join(root, relPath))) {
        fail(`routine '${routine.name}' references missing file: ${relPath}`);
      }
    }
  }
  return payload;
}

const command = process.argv[2] || "validate";
const name = process.argv[3];
const payload = loadRoutines();

if (command === "validate") {
  console.log("bmo routines are valid");
} else if (command === "list") {
  for (const routine of payload.routines) {
    console.log(`${routine.name}\t${routine.command}\t${routine.owner_surface}`);
  }
} else if (command === "json") {
  console.log(JSON.stringify(payload, null, 2));
} else if (command === "show") {
  if (!name) fail("show requires a routine name");
  const routine = payload.routines.find((item) => item.name === name);
  if (!routine) fail(`unknown routine: ${name}`);
  console.log(JSON.stringify(routine, null, 2));
} else {
  fail(`unknown command '${command}'`);
}
