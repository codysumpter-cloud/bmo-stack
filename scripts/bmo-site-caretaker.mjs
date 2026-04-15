#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import childProcess from "node:child_process";

const defaultSiteDir = path.join(os.homedir(), "prismtek-site");
const defaultReplicaDir = path.join(os.homedir(), "prismtek-site-replica");
const defaultOutput = path.join("workflows", "bmo-site-caretaker.json");
const defaultDiscoveryRoot = os.homedir();
const maxDiscoveryDepth = 4;
const chatSurfaceTokens = ["chat", "assistant", "api", "worker", "function"];

function parseArgs(argv) {
  const args = {
    siteDir: process.env.BMO_SITE_DIR || defaultSiteDir,
    replicaDir: process.env.BMO_SITE_REPLICA_DIR || defaultReplicaDir,
    discoveryRoot: process.env.BMO_SITE_DISCOVERY_ROOT || defaultDiscoveryRoot,
    output: defaultOutput,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--site-dir") args.siteDir = argv[++index];
    else if (arg === "--replica-dir") args.replicaDir = argv[++index];
    else if (arg === "--discovery-root") args.discoveryRoot = argv[++index];
    else if (arg === "--output") args.output = argv[++index];
    else throw new Error(`unknown argument: ${arg}`);
  }
  return args;
}

function withinDepth(base, candidate, maxDepth) {
  const rel = path.relative(base, candidate);
  if (rel.startsWith("..") || path.isAbsolute(rel)) return false;
  return rel.split(path.sep).filter(Boolean).length <= maxDepth;
}

function discoverRepo(root, name) {
  if (!fs.existsSync(root)) return [];
  const matches = [];
  function walk(current) {
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const fullPath = path.join(current, entry.name);
      if (!withinDepth(root, fullPath, maxDiscoveryDepth)) continue;
      if (entry.name === name) matches.push(fullPath);
      walk(fullPath);
    }
  }
  walk(root);
  return [...new Set(matches)].sort().slice(0, 20);
}

function gitTreeFiles(root) {
  const gitDir = path.join(root, ".git");
  if (!fs.existsSync(gitDir)) return null;
  const result = childProcess.spawnSync("git", ["-C", root, "ls-tree", "-r", "--name-only", "HEAD"], {
    encoding: "utf8",
    timeout: 15000,
  });
  if (result.error || result.status !== 0) return null;
  return result.stdout.split(/\r?\n/).map((line) => line.trim()).filter(Boolean);
}

function scanSite(root) {
  if (!fs.existsSync(root)) {
    return { path: root, exists: false, html_files: [], asset_count: 0, chat_surface_candidates: [] };
  }
  const treeFiles = gitTreeFiles(root);
  const files = treeFiles || [];
  const htmlFiles = [];
  const chatCandidates = [];
  let assetCount = 0;

  if (treeFiles) {
    for (const rel of treeFiles) {
      const suffix = path.extname(rel).toLowerCase();
      if ([".html", ".htm"].includes(suffix)) htmlFiles.push(rel);
      if ([".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".css", ".js"].includes(suffix)) assetCount += 1;
      const lowered = rel.toLowerCase();
      if ([".html", ".htm", ".js", ".ts", ".tsx", ".jsx", ".json", ".md"].includes(suffix) &&
          chatSurfaceTokens.some((token) => lowered.includes(token))) {
        chatCandidates.push(rel);
      }
    }
  } else {
    function walk(current) {
      const entries = fs.readdirSync(current, { withFileTypes: true });
      for (const entry of entries) {
        const fullPath = path.join(current, entry.name);
        if (entry.isDirectory()) {
          walk(fullPath);
          continue;
        }
        const rel = path.relative(root, fullPath).split(path.sep).join("/");
        const suffix = path.extname(fullPath).toLowerCase();
        if ([".html", ".htm"].includes(suffix)) htmlFiles.push(rel);
        if ([".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".css", ".js"].includes(suffix)) assetCount += 1;
        const lowered = rel.toLowerCase();
        if ([".html", ".htm", ".js", ".ts", ".tsx", ".jsx", ".json", ".md"].includes(suffix) &&
            chatSurfaceTokens.some((token) => lowered.includes(token))) {
          chatCandidates.push(rel);
        }
      }
    }

    walk(root);
  }
  return {
    path: root,
    exists: true,
    html_files: htmlFiles.sort(),
    asset_count: assetCount,
    chat_surface_candidates: [...new Set(chatCandidates)].sort(),
    inventory_source: treeFiles ? "git-tree" : "filesystem",
  };
}

function scanReplica(root) {
  if (!fs.existsSync(root)) {
    return { path: root, exists: false, routes: [], components: [], chat_surface_candidates: [] };
  }

  const routes = [];
  const components = [];
  const chatCandidates = [];
  const treeFiles = gitTreeFiles(root);

  if (treeFiles) {
    for (const rel of treeFiles) {
      const suffix = path.extname(rel).toLowerCase();
      if (![".tsx", ".ts", ".jsx", ".js"].includes(suffix)) continue;
      const lowered = rel.toLowerCase();
      if (["route", "page", "app.tsx", "main.tsx"].some((token) => lowered.includes(token))) routes.push(rel);
      if (lowered.includes("component") || lowered.includes("/components/")) components.push(rel);
      if (chatSurfaceTokens.some((token) => lowered.includes(token))) chatCandidates.push(rel);
    }
  } else {
    function walk(current) {
      const entries = fs.readdirSync(current, { withFileTypes: true });
      for (const entry of entries) {
        const fullPath = path.join(current, entry.name);
        if (entry.isDirectory()) {
          walk(fullPath);
          continue;
        }
        const suffix = path.extname(fullPath).toLowerCase();
        if (![".tsx", ".ts", ".jsx", ".js"].includes(suffix)) continue;
        const rel = path.relative(root, fullPath).split(path.sep).join("/");
        const lowered = rel.toLowerCase();
        if (["route", "page", "app.tsx", "main.tsx"].some((token) => lowered.includes(token))) routes.push(rel);
        if (lowered.includes("component") || lowered.includes("/components/")) components.push(rel);
        if (chatSurfaceTokens.some((token) => lowered.includes(token))) chatCandidates.push(rel);
      }
    }

    walk(root);
  }

  return {
    path: root,
    exists: true,
    routes: [...new Set(routes)].sort(),
    components: [...new Set(components)].sort(),
    chat_surface_candidates: [...new Set(chatCandidates)].sort(),
    inventory_source: treeFiles ? "git-tree" : "filesystem",
  };
}

function buildPlan(site) {
  return site.html_files.map((htmlFile) => {
    let slug = htmlFile.replace(/\.html?$/, "");
    if (slug.endsWith("/index")) slug = slug.slice(0, -6);
    const route = slug === "" || slug === "index" ? "/" : `/${slug.replace(/^\/+|\/+$/g, "")}/`;
    return {
      route,
      source: htmlFile,
      status: "pending-migration",
      target: "prismtek-site-replica",
    };
  });
}

const args = parseArgs(process.argv.slice(2));
const site = scanSite(args.siteDir);
const replica = scanReplica(args.replicaDir);
const payload = {
  site,
  replica,
  discovery: {
    root: args.discoveryRoot,
    site_candidates: site.exists ? [] : discoverRepo(args.discoveryRoot, "prismtek-site"),
    replica_candidates: replica.exists ? [] : discoverRepo(args.discoveryRoot, "prismtek-site-replica"),
  },
  migration_plan: buildPlan(site),
  chat_agent_handoff: {
    website_owner_repo: "prismtek-site",
    runtime_contract_repo: "bmo-stack",
    site_candidates: site.chat_surface_candidates || [],
    replica_candidates: replica.chat_surface_candidates || [],
  },
};

if (!site.exists && payload.discovery.site_candidates.length) {
  payload.site.hint = "Use --site-dir with one of discovery.site_candidates.";
}
if (!replica.exists && payload.discovery.replica_candidates.length) {
  payload.replica.hint = "Use --replica-dir with one of discovery.replica_candidates.";
}

fs.mkdirSync(path.dirname(args.output), { recursive: true });
fs.writeFileSync(args.output, `${JSON.stringify(payload, null, 2)}\n`, "utf8");
console.log(JSON.stringify(payload, null, 2));
