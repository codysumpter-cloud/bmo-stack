#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const root = path.resolve(import.meta.dirname, "..");
const home = os.homedir();
const defaultWorkspace = path.resolve(process.env.OPENCLAW_WORKSPACE || root);
const globalSkills = path.join(home, ".openclaw", "skills");
const workspaceSkills = path.join(defaultWorkspace, "skills");
const repoSkills = path.join(root, "skills");

function run(cmd, args, options = {}) {
	try {
		const result = spawnSync(cmd, args, {
			encoding: "utf8",
			timeout: options.timeout ?? 15000
		});
		if (result.error) {
			if (result.error.code === "ENOENT") return { ok: false, error: "missing-binary" };
			if (result.error.code === "ETIMEDOUT") return { ok: false, error: "timeout", timeout_seconds: (options.timeout ?? 15000) / 1000 };
			return { ok: false, error: String(result.error.message || result.error) };
		}
		return {
			ok: result.status === 0,
			returncode: result.status ?? 1,
			stdout: (result.stdout || "").slice(-4000),
			stderr: (result.stderr || "").slice(-4000)
		};
	} catch (error) {
		return { ok: false, error: String(error?.message || error) };
	}
}

function directorySummary(targetPath) {
	const exists = fs.existsSync(targetPath);
	const isDir = exists && fs.statSync(targetPath).isDirectory();
	const children = isDir
		? fs
			.readdirSync(targetPath, { withFileTypes: true })
			.filter((entry) => entry.isDirectory())
			.map((entry) => entry.name)
			.sort()
		: [];

	return {
		path: targetPath,
		exists,
		is_dir: isDir,
		skill_count: children.length,
		sample: children.slice(0, 10)
	};
}

function configSummary() {
	const configPath = path.join(home, ".openclaw", "openclaw.json");
	const exists = fs.existsSync(configPath);
	return {
		path: configPath,
		exists,
		is_dir: exists ? fs.statSync(configPath).isDirectory() : false
	};
}

function which(binary) {
	const lookup = process.platform === "win32" ? ["where", binary] : ["which", binary];
	const result = run(lookup[0], lookup.slice(1), { timeout: 10000 });
	if (!result.ok || !result.stdout.trim()) return null;
	return result.stdout.trim().split(/\r?\n/)[0] || null;
}

const report = {
	paths: {
		repo_root: directorySummary(root),
		repo_skills: directorySummary(repoSkills),
		workspace: directorySummary(defaultWorkspace),
		workspace_skills: directorySummary(workspaceSkills),
		global_skills: directorySummary(globalSkills),
		config: configSummary()
	},
	skill_search_order: [workspaceSkills, globalSkills, "bundled skills"],
	manual_install_targets: {
		preferred_default: globalSkills,
		workspace_override: workspaceSkills
	},
	binaries: {
		openclaw: which("openclaw"),
		clawhub: which("clawhub"),
		jq: which("jq")
	},
	checks: {},
	recommendations: [
		"Prefer targeted installs over bulk updates during incidents.",
		"Try one targeted 'clawhub install <skill-slug>' first; if it stalls for roughly 30 seconds, stop it and switch to the manual fallback.",
		"If registry install hangs, review the skill source and fall back to 'bash scripts/install-skill-fallback.sh /path/to/skill --global'.",
		"Use '--workspace' only when you intentionally want a repo-scoped override that should win over global or bundled skills.",
		"Restart the agent session after adding or changing skills so the refreshed skill snapshot is picked up."
	]
};

if (report.binaries.openclaw) {
	report.checks.openclaw_skills_list = run("openclaw", ["skills", "list"]);
	report.checks.openclaw_skills_eligible = run("openclaw", ["skills", "list", "--eligible"]);
	report.checks.openclaw_skills_check = run("openclaw", ["skills", "check"]);
}

if (report.binaries.clawhub) {
	report.checks.clawhub_help = run("clawhub", ["--help"], { timeout: 10000 });
}

console.log(JSON.stringify(report, null, 2));
