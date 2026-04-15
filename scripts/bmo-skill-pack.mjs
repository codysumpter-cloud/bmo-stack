#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const packPath = path.join(root, "config", "skills", "bmo-baseline-pack.json");

function fail(message) {
	console.error(`ERROR: ${message}`);
	process.exit(1);
}

function ensureString(value, message) {
	if (typeof value !== "string" || value.trim().length === 0) fail(message);
}

function ensureArray(value, message) {
	if (!Array.isArray(value) || value.length === 0) fail(message);
}

const pack = JSON.parse(fs.readFileSync(packPath, "utf8"));

if (pack.version !== 1) fail("pack version must be 1");
ensureString(pack.pack_name, "pack_name must be a non-empty string");
ensureString(pack.description, "description must be a non-empty string");
ensureArray(pack.skill_search_order, "skill_search_order must be a non-empty array");
ensureArray(pack.local_routines, "local_routines must be a non-empty array");
ensureArray(pack.community_shortlist, "community_shortlist must be a non-empty array");

for (const item of pack.local_routines) {
	ensureString(item.name, "local routine name must be a non-empty string");
	ensureString(item.why, `local routine '${item.name}' must include why`);
}

for (const item of pack.community_shortlist) {
	ensureString(item.slug, "community skill slug must be a non-empty string");
	ensureString(item.display_name, `community skill '${item.slug}' must include display_name`);
	ensureString(item.category, `community skill '${item.slug}' must include category`);
	ensureString(item.why, `community skill '${item.slug}' must include why`);
	ensureString(item.install, `community skill '${item.slug}' must include install`);
	ensureArray(item.verify, `community skill '${item.slug}' must include verify commands`);
	ensureString(item.notes, `community skill '${item.slug}' must include notes`);
}

const command = process.argv[2] || "list";

if (command === "json") {
	console.log(JSON.stringify(pack, null, 2));
	process.exit(0);
}

if (command !== "list") {
	fail(`unknown command '${command}' (expected 'list' or 'json')`);
}

console.log(`${pack.pack_name}: ${pack.description}`);
console.log("");
console.log("Skill precedence:");
for (const item of pack.skill_search_order) {
	console.log(`- ${item}`);
}
console.log("");
console.log("Local BMO routines:");
for (const item of pack.local_routines) {
	console.log(`- ${item.name}: ${item.why}`);
}
console.log("");
console.log("Community shortlist:");
for (const item of pack.community_shortlist) {
	console.log(`- ${item.slug} (${item.category})`);
	console.log(`  install: ${item.install}`);
	console.log(`  why: ${item.why}`);
}
