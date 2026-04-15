#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
from pathlib import Path

DEFAULT_REPO_URL = str(Path.home() / "code" / "bmo-stack")
DEFAULT_WORKSPACE = Path.home() / ".openclaw" / "workspace" / "bmo-stack"
DEFAULT_CONTEXT_HOST = Path.home() / "bmo-context"
DEFAULT_CONTINUITY_OUTPUT = Path("workflows") / "bmo-continuity.json"
DEFAULT_SYNC_OUTPUT = Path("workflows") / "bmo-workspace-sync.json"
DEFAULT_SITE_REPO_URL = str(Path.home() / "prismtek-site")
DEFAULT_SITE_WORKSPACE = Path.home() / ".openclaw" / "workspace" / "prismtek-site"
DEFAULT_CONTEXT_EXCLUDES = [
    "TASK_STATE.md",
    "WORK_IN_PROGRESS.md",
    "memory.md",
    "MEMORY.md",
    "memory/",
]
PLACEHOLDER_CONTINUITY_TOKENS = {
    "",
    "PASTE_THE_REAL_CONTINUITY_TOKEN_VALUE_HERE",
    "replace-me-with-the-real-token",
}


def run(cmd: list[str], cwd: Path | None = None) -> dict[str, object]:
    completed = subprocess.run(cmd, cwd=str(cwd) if cwd else None, capture_output=True, text=True, check=False)
    return {
        "cmd": cmd,
        "cwd": str(cwd) if cwd else None,
        "returncode": completed.returncode,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
    }


def current_branch(path: Path) -> str:
    result = run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=path)
    if result["returncode"] == 0:
        return str(result["stdout"]).strip()
    return ""


def read_default_branch(path: Path) -> str:
    head = run(["git", "symbolic-ref", "refs/remotes/origin/HEAD"], cwd=path)
    if head["returncode"] == 0:
        value = str(head["stdout"]).strip()
        prefix = "refs/remotes/origin/"
        if value.startswith(prefix):
            return value[len(prefix):]
    for candidate in ("master", "main"):
        if run(["git", "show-ref", "--verify", f"refs/remotes/origin/{candidate}"], cwd=path)["returncode"] == 0:
            return candidate
    return current_branch(path)


def local_branch_exists(path: Path, branch: str) -> bool:
    return run(["git", "show-ref", "--verify", f"refs/heads/{branch}"], cwd=path)["returncode"] == 0


def has_upstream(path: Path) -> bool:
    return run(["git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"], cwd=path)["returncode"] == 0


def normalize_repo_url(repo_url: str) -> str:
    candidate = Path(repo_url).expanduser()
    if candidate.exists():
        return str(candidate.resolve())
    return repo_url


def is_local_git_repo(repo_url: str) -> bool:
    candidate = Path(repo_url).expanduser()
    return candidate.exists() and (candidate / ".git").exists()


def has_tracked_changes(path: Path) -> bool:
    result = run(["git", "status", "--porcelain", "--untracked-files=no"], cwd=path)
    if result["returncode"] != 0:
        return True
    return bool(str(result["stdout"]).strip())


def make_note_step(cmd: list[str], cwd: Path, stdout: str) -> dict[str, object]:
    return {
        "cmd": cmd,
        "cwd": str(cwd),
        "returncode": 0,
        "stdout": stdout,
        "stderr": "",
    }


def ensure_origin(path: Path, repo_url: str) -> list[dict[str, object]]:
    steps: list[dict[str, object]] = []
    if not repo_url:
        return steps
    repo_url = normalize_repo_url(repo_url)
    remote = run(["git", "remote", "get-url", "origin"], cwd=path)
    remote_url = str(remote["stdout"]).strip() if remote["returncode"] == 0 else ""
    if remote_url != repo_url:
        steps.append(run(["git", "remote", "set-url", "origin", repo_url], cwd=path))
    return steps


def ensure_default_branch(path: Path, default_branch: str) -> list[dict[str, object]]:
    steps: list[dict[str, object]] = []
    if not default_branch:
        return steps
    branch = current_branch(path)
    if branch != default_branch:
        if local_branch_exists(path, default_branch):
            steps.append(run(["git", "checkout", default_branch], cwd=path))
        else:
            steps.append(run(["git", "checkout", "-b", default_branch, f"origin/{default_branch}"], cwd=path))
    if current_branch(path) == default_branch and not has_upstream(path):
        steps.append(run(["git", "branch", "--set-upstream-to", f"origin/{default_branch}", default_branch], cwd=path))
    return steps


def ensure_repo(path: Path, repo_url: str, preferred_branch: str | None = None) -> list[dict[str, object]]:
    steps: list[dict[str, object]] = []
    repo_url = normalize_repo_url(repo_url)
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        steps.append(run(["git", "clone", repo_url, str(path)]))
    if not path.exists():
        return steps
    steps.extend(ensure_origin(path, repo_url))
    steps.append(run(["git", "fetch", "--all", "--prune"], cwd=path))
    default_branch = preferred_branch or read_default_branch(path)
    steps.extend(ensure_default_branch(path, default_branch))
    if default_branch:
        steps.append(run(["git", "pull", "--ff-only", "origin", default_branch], cwd=path))
    else:
        steps.append(run(["git", "pull", "--ff-only"], cwd=path))
    return steps


def maybe_refresh_source_repo(repo_url: str, preferred_branch: str | None = None) -> list[dict[str, object]]:
    steps: list[dict[str, object]] = []
    normalized_repo_url = normalize_repo_url(repo_url)
    if not is_local_git_repo(normalized_repo_url):
        return steps

    path = Path(normalized_repo_url)
    default_branch = preferred_branch or read_default_branch(path)
    branch = current_branch(path)

    if has_tracked_changes(path):
        steps.append(
            make_note_step(
                ["git", "pull", "--ff-only", "origin", default_branch or branch or "HEAD"],
                path,
                "Skipping source refresh because the local repo has tracked changes.\n",
            )
        )
        return steps

    if default_branch and branch and branch != default_branch:
        steps.append(
            make_note_step(
                ["git", "checkout", default_branch],
                path,
                f"Skipping source refresh because the local repo is on {branch}, not {default_branch}.\n",
            )
        )
        return steps

    steps.append(run(["git", "fetch", "--all", "--prune"], cwd=path))
    if default_branch:
        steps.append(run(["git", "pull", "--ff-only", "origin", default_branch], cwd=path))
    else:
        steps.append(run(["git", "pull", "--ff-only"], cwd=path))
    return steps


def tag_steps(target: str, steps: list[dict[str, object]]) -> list[dict[str, object]]:
    for step in steps:
        step["target"] = target
    return steps


def sync_context(repo_root: Path, host_context: Path, delete: bool, excludes: list[str]) -> list[dict[str, object]]:
    steps: list[dict[str, object]] = []
    repo_context = repo_root / "context"
    if host_context.exists() and repo_context.exists() and shutil.which("rsync"):
        cmd = ["rsync", "-av"]
        if delete:
            cmd.append("--delete")
        for item in excludes:
            cmd.extend(["--exclude", item])
        cmd.extend([f"{repo_context}/", f"{host_context}/"])
        steps.append(run(cmd))
    return steps


def continuity_publish_enabled(publish: bool) -> bool:
    if not publish:
        return False
    token = (os.environ.get("PRISMTEK_CONTINUITY_TOKEN") or os.environ.get("BMO_CONTINUITY_TOKEN") or "").strip()
    return token not in PLACEHOLDER_CONTINUITY_TOKENS


def maybe_refresh_continuity(repo_root: Path, surface: str, output_path: Path, publish: bool) -> list[dict[str, object]]:
    steps: list[dict[str, object]] = []
    node = shutil.which("node")
    script_path = repo_root / "scripts" / "bmo-continuity-report.mjs"
    if not node or not script_path.exists():
        return steps

    effective_publish = continuity_publish_enabled(publish)
    if publish and not effective_publish:
        steps.append(
            make_note_step(
                [node, str(script_path), "--surface", surface, "--output", str(output_path)],
                repo_root,
                "Skipping continuity publish because the configured token is missing or still the placeholder.\n",
            )
        )

    cmd = [node, str(script_path), "--surface", surface, "--output", str(output_path)]
    if effective_publish:
        cmd.append("--publish")
    steps.append(run(cmd, cwd=repo_root))
    return steps


def mirror_continuity_snapshot(repo_root: Path, output_path: Path) -> list[dict[str, object]]:
    steps: list[dict[str, object]] = []
    if not output_path.exists():
        return steps

    target = repo_root / "context" / "continuity" / "live-status.json"
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(output_path, target)
    except OSError as exc:
        steps.append(
            {
                "cmd": ["copy", str(output_path), str(target)],
                "cwd": str(repo_root),
                "returncode": 1,
                "stdout": "",
                "stderr": f"Failed to mirror continuity snapshot: {exc}\n",
            }
        )
        return steps

    steps.append(make_note_step(["copy", str(output_path), str(target)], repo_root, f"Mirrored continuity snapshot to {target}\n"))
    return steps


def resolve_workspace_path(workspace_dir: Path, value: str) -> Path:
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = workspace_dir / path
    return path


def main() -> None:
    parser = argparse.ArgumentParser(description="Keep the local OpenClaw workspace aligned with bmo-stack.")
    parser.add_argument("--repo-url", default=os.environ.get("BMO_STACK_REPO_URL", DEFAULT_REPO_URL))
    parser.add_argument("--workspace-dir", default=os.environ.get("BMO_OPENCLAW_WORKSPACE_DIR", str(DEFAULT_WORKSPACE)))
    parser.add_argument("--host-context", default=os.environ.get("BMO_HOST_CONTEXT_DIR", str(DEFAULT_CONTEXT_HOST)))
    parser.add_argument("--delete-context", action="store_true", help="Delete files from host context that are absent in repo context.")
    parser.add_argument("--exclude", action="append", default=[], help="Additional rsync exclude patterns for context sync.")
    parser.add_argument("--output", default=os.environ.get("BMO_WORKSPACE_SYNC_OUTPUT", str(DEFAULT_SYNC_OUTPUT)))
    parser.add_argument("--continuity-surface", default=os.environ.get("BMO_CONTINUITY_SURFACE", "macbook"))
    parser.add_argument("--continuity-output", default=os.environ.get("BMO_CONTINUITY_OUTPUT", str(DEFAULT_CONTINUITY_OUTPUT)))
    parser.add_argument("--publish-continuity", action="store_true", default=os.environ.get("BMO_CONTINUITY_PUBLISH", "").lower() == "true")
    parser.add_argument("--site-repo-url", default=os.environ.get("PRISMTEK_SITE_REPO_URL", DEFAULT_SITE_REPO_URL))
    parser.add_argument("--site-workspace-dir", default=os.environ.get("PRISMTEK_SITE_WORKSPACE_DIR", str(DEFAULT_SITE_WORKSPACE)))
    parser.add_argument("--skip-site-workspace-sync", action="store_true")
    args = parser.parse_args()

    workspace_dir = Path(args.workspace_dir).expanduser()
    host_context = Path(args.host_context).expanduser()
    continuity_output = resolve_workspace_path(workspace_dir, args.continuity_output)
    output = resolve_workspace_path(workspace_dir, args.output)
    site_workspace_dir = Path(args.site_workspace_dir).expanduser()
    excludes = DEFAULT_CONTEXT_EXCLUDES + list(args.exclude)

    payload = {
        "repo_url": normalize_repo_url(args.repo_url),
        "workspace_dir": str(workspace_dir),
        "host_context": str(host_context),
        "delete_context": args.delete_context,
        "excludes": excludes,
        "continuity_surface": args.continuity_surface,
        "continuity_output": str(continuity_output),
        "publish_continuity": args.publish_continuity,
        "output": str(output),
        "site_repo_url": normalize_repo_url(args.site_repo_url),
        "site_workspace_dir": str(site_workspace_dir),
        "skip_site_workspace_sync": args.skip_site_workspace_sync,
        "steps": [],
    }
    payload["steps"].extend(tag_steps("bmo-stack-source", maybe_refresh_source_repo(args.repo_url, preferred_branch="master")))
    payload["steps"].extend(tag_steps("bmo-stack", ensure_repo(workspace_dir, args.repo_url, preferred_branch="master")))
    if not args.skip_site_workspace_sync and args.site_repo_url:
        payload["steps"].extend(tag_steps("prismtek-site-source", maybe_refresh_source_repo(args.site_repo_url, preferred_branch="main")))
        payload["steps"].extend(tag_steps("prismtek-site", ensure_repo(site_workspace_dir, args.site_repo_url, preferred_branch="main")))
    payload["steps"].extend(tag_steps("continuity", maybe_refresh_continuity(workspace_dir, args.continuity_surface, continuity_output, args.publish_continuity)))
    payload["steps"].extend(tag_steps("continuity", mirror_continuity_snapshot(workspace_dir, continuity_output)))
    payload["steps"].extend(tag_steps("context", sync_context(workspace_dir, host_context, args.delete_context, excludes)))

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, indent=2))


if __name__ == "__main__":
    main()
