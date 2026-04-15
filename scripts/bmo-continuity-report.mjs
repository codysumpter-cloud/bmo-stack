#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import childProcess from "node:child_process";

const root = path.resolve(import.meta.dirname, "..");

function fail(message) {
  console.error(`ERROR: ${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const args = {
    surface: "repo",
    output: "workflows/bmo-continuity.json",
    siteRuntimeUrl: process.env.BMO_SITE_RUNTIME_URL || "https://prismtek.dev/api/runtime-status",
    continuityUrl: process.env.PRISMTEK_CONTINUITY_URL || process.env.BMO_CONTINUITY_URL || "",
    continuityToken: process.env.PRISMTEK_CONTINUITY_TOKEN || process.env.BMO_CONTINUITY_TOKEN || "",
    publish: false
  };

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    const next = argv[index + 1];
    const nextIsValue = typeof next === "string" && !next.startsWith("--");
    if (token === "--surface" && nextIsValue) {
      args.surface = next;
      index += 1;
    } else if (token === "--output" && nextIsValue) {
      args.output = next;
      index += 1;
    } else if (token === "--site-runtime-url" && nextIsValue) {
      args.siteRuntimeUrl = next;
      index += 1;
    } else if (token.startsWith("--site-runtime-url=")) {
      args.siteRuntimeUrl = token.slice("--site-runtime-url=".length);
    } else if (token === "--continuity-url" && nextIsValue) {
      args.continuityUrl = next;
      index += 1;
    } else if (token.startsWith("--continuity-url=")) {
      args.continuityUrl = token.slice("--continuity-url=".length);
    } else if (token === "--continuity-token" && nextIsValue) {
      args.continuityToken = next;
      index += 1;
    } else if (token.startsWith("--continuity-token=")) {
      args.continuityToken = token.slice("--continuity-token=".length);
    } else if (token === "--publish") {
      args.publish = true;
    }
  }

  return args;
}

function runGit(args) {
  const result = childProcess.spawnSync("git", args, {
    cwd: root,
    encoding: "utf8"
  });
  return {
    ok: result.status === 0,
    stdout: (result.stdout || "").trim(),
    stderr: (result.stderr || "").trim()
  };
}

function readGitStatus() {
  const branch = runGit(["rev-parse", "--abbrev-ref", "HEAD"]);
  const commit = runGit(["rev-parse", "HEAD"]);
  const shortCommit = runGit(["rev-parse", "--short", "HEAD"]);
  const status = runGit(["status", "--short"]);
  const upstream = runGit(["rev-list", "--left-right", "--count", "@{upstream}...HEAD"]);
  const recent = runGit(["log", "--oneline", "-5"]);

  let ahead = 0;
  let behind = 0;
  if (upstream.ok && upstream.stdout) {
    const [behindRaw, aheadRaw] = upstream.stdout.split(/\s+/);
    behind = Number.parseInt(behindRaw || "0", 10) || 0;
    ahead = Number.parseInt(aheadRaw || "0", 10) || 0;
  }

  const changedFiles = status.ok && status.stdout ? status.stdout.split(/\r?\n/).filter(Boolean) : [];
  return {
    branch: branch.ok ? branch.stdout : "unknown",
    commit: commit.ok ? commit.stdout : "",
    shortCommit: shortCommit.ok ? shortCommit.stdout : "",
    changedFiles,
    dirty: changedFiles.length > 0,
    ahead,
    behind,
    recentCommits: recent.ok && recent.stdout ? recent.stdout.split(/\r?\n/).filter(Boolean) : []
  };
}

async function readSiteRuntime(siteRuntimeUrl) {
  if (!siteRuntimeUrl) {
    return null;
  }

  try {
    const response = await fetch(siteRuntimeUrl, {
      headers: { accept: "application/json" }
    });
    const payload = await response.json();
    return {
      ok: response.ok,
      status: response.status,
      payload
    };
  } catch (error) {
    return {
      ok: false,
      status: null,
      error: error instanceof Error ? error.message : "Unable to reach site runtime."
    };
  }
}

function labelForSurface(surface) {
  switch (surface) {
    case "macbook":
      return "MacBook";
    case "website":
      return "Website";
    case "openclaw":
      return "OpenClaw";
    case "codex":
      return "Codex";
    default:
      return "Repository";
  }
}

function buildSnapshot(args, gitStatus, siteRuntime) {
  const checkedAt = new Date().toISOString();
  const dirtySummary = gitStatus.dirty ? `${gitStatus.changedFiles.length} working tree change(s)` : "clean working tree";
  const syncSummary =
    gitStatus.ahead || gitStatus.behind ? `ahead ${gitStatus.ahead}, behind ${gitStatus.behind}` : "tracking remote cleanly";

  let status = "ok";
  if (gitStatus.dirty || gitStatus.behind > 0) {
    status = "warn";
  }

  if (args.surface === "website" && siteRuntime && !siteRuntime.ok) {
    status = "warn";
  }

  const summary = `${gitStatus.branch} ${dirtySummary} at ${gitStatus.shortCommit || "unknown"}`;
  const detailsParts = [
    `${syncSummary}.`,
    `Host ${os.hostname()} (${process.platform}).`
  ];

  if (siteRuntime?.payload?.publicChat) {
    detailsParts.push(
      `Site chat ${siteRuntime.payload.publicChat.healthy ? "live" : "offline"} on ${siteRuntime.payload.publicChat.model || "unknown model"}.`
    );
  } else if (siteRuntime?.error) {
    detailsParts.push(`Site runtime check failed: ${siteRuntime.error}.`);
  }

  return {
    surface: args.surface,
    label: labelForSurface(args.surface),
    status,
    summary,
    details: detailsParts.join(" "),
    branch: gitStatus.branch,
    commit: gitStatus.commit,
    sourceUrl: `https://github.com/codysumpter-cloud/bmo-stack/tree/${gitStatus.branch}`,
    payload: {
      checkedAt,
      host: os.hostname(),
      platform: process.platform,
      git: gitStatus,
      siteRuntime
    },
    updatedAt: checkedAt
  };
}

async function maybePublish(snapshot, args) {
  if (!args.publish) {
    return null;
  }

  if (!args.continuityUrl || !args.continuityToken) {
    fail("continuity publish requested but PRISMTEK_CONTINUITY_URL/token are not configured");
  }

  const response = await fetch(args.continuityUrl, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${args.continuityToken}`,
      accept: "application/json"
    },
    body: JSON.stringify(snapshot)
  });

  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    fail(`continuity publish failed with HTTP ${response.status}: ${JSON.stringify(payload)}`);
  }

  return {
    status: response.status,
    payload
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const gitStatus = readGitStatus();
  const siteRuntime = await readSiteRuntime(args.siteRuntimeUrl);
  const snapshot = buildSnapshot(args, gitStatus, siteRuntime);
  const published = await maybePublish(snapshot, args);
  const outputPath = path.isAbsolute(args.output) ? args.output : path.join(root, args.output);
  const report = {
    snapshot,
    published
  };

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`, "utf8");
  console.log(JSON.stringify(report, null, 2));
}

main().catch((error) => fail(error instanceof Error ? error.message : String(error)));
