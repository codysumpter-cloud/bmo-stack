#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const skillsDir = path.join(root, "skills");
const registryPath = path.join(skillsDir, "index.json");

function fail(message) {
	console.error(`ERROR: ${message}`);
	process.exit(1);
}

function ensureFile(filePath, message) {
	if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) fail(message);
}

const registryRaw = fs.readFileSync(registryPath, "utf8");
const registry = JSON.parse(registryRaw);
const skills = registry.skills;

if (!skills || typeof skills !== "object" || Array.isArray(skills)) {
	fail("skills must be an object");
}

for (const [name, spec] of Object.entries(skills)) {
	if (!spec || typeof spec !== "object" || Array.isArray(spec)) {
		fail(`skill '${name}' must be an object`);
	}

	const triggers = spec.triggers;
	if (!Array.isArray(triggers) || triggers.length === 0) {
		fail(`skill '${name}' must have non-empty triggers list`);
	}
	if (triggers.some((trigger) => typeof trigger !== "string" || trigger.trim().length === 0)) {
		fail(`skill '${name}' has invalid trigger entries`);
	}
	if (new Set(triggers.map((trigger) => trigger.toLowerCase())).size !== triggers.length) {
		fail(`skill '${name}' has duplicate triggers (case-insensitive)`);
	}

	const actions = spec.actions;
	if (!Array.isArray(actions) || actions.length === 0) {
		fail(`skill '${name}' must have non-empty actions list`);
	}
	if (actions.some((action) => typeof action !== "string" || action.trim().length === 0)) {
		fail(`skill '${name}' has invalid actions`);
	}

	if (!actions.includes(spec.default_action)) {
		fail(`skill '${name}' default_action must be one of actions`);
	}

	const skillReadme = path.join(skillsDir, name, "README.md");
	ensureFile(skillReadme, `skill '${name}' must have ${path.relative(root, skillReadme).replaceAll("\\", "/")}`);
}

const skillDirectories = fs
	.readdirSync(skillsDir, { withFileTypes: true })
	.filter((entry) => entry.isDirectory())
	.map((entry) => entry.name)
	.sort();

const registeredSkills = Object.keys(skills).sort();

for (const directory of skillDirectories) {
	if (!skills[directory]) fail(`skills/${directory} exists but is missing from skills/index.json`);
}

for (const skillName of registeredSkills) {
	const skillDir = path.join(skillsDir, skillName);
	if (!fs.existsSync(skillDir) || !fs.statSync(skillDir).isDirectory()) {
		fail(`skill '${skillName}' is registered but skills/${skillName} is missing`);
	}
}

console.log("skills registry and skill docs are valid");
