#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DRAFT_ROOT = ROOT / "docs" / "planning" / "issue-drafts"


def parse_draft(path: Path) -> dict[str, object]:
    text = path.read_text(encoding="utf-8")
    title_match = re.search(r"^# Title\s+\n+(.+?)\n", text, flags=re.MULTILINE | re.DOTALL)
    labels_match = re.search(r"^# Labels\s+\n+(.+?)\n", text, flags=re.MULTILINE | re.DOTALL)
    if not title_match:
        raise ValueError(f"Missing # Title section in {path}")
    if not labels_match:
        raise ValueError(f"Missing # Labels section in {path}")

    title = title_match.group(1).strip()
    labels_raw = labels_match.group(1).strip()
    labels = [label.strip() for label in labels_raw.split(",") if label.strip()]
    body = text[labels_match.end():].strip()
    if not body:
        raise ValueError(f"Missing issue body after # Labels in {path}")

    return {"title": title, "labels": labels, "body": body, "path": str(path)}


def find_existing_issue(repo: str, title: str) -> str | None:
    cmd = [
        "gh", "issue", "list",
        "--repo", repo,
        "--state", "all",
        "--search", f'in:title \"{title}\"',
        "--json", "number,title,url",
        "--limit", "20",
    ]
    output = subprocess.check_output(cmd, text=True)
    issues = json.loads(output)
    for issue in issues:
        if issue.get("title") == title:
            return issue.get("url")
    return None


def create_issue(repo: str, draft: dict[str, object]) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", str(draft["title"]).lower()).strip("-")[:48]
    body_file = Path("/tmp") / f"bmo-issue-{slug or 'draft'}.md"
    body_file.write_text(str(draft["body"]) + "\n", encoding="utf-8")

    cmd = [
        "gh", "issue", "create",
        "--repo", repo,
        "--title", str(draft["title"]),
        "--body-file", str(body_file),
    ]
    for label in list(draft["labels"]):
        cmd.extend(["--label", label])
    return subprocess.check_output(cmd, text=True).strip()


def iter_drafts(root: Path) -> list[Path]:
    return sorted(path for path in root.rglob("*.md") if path.is_file())


def main() -> None:
    parser = argparse.ArgumentParser(description="Open GitHub issues from markdown draft files.")
    parser.add_argument("--repo", default="codysumpter-cloud/bmo-stack")
    parser.add_argument("--draft-root", default=str(DEFAULT_DRAFT_ROOT))
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    draft_root = Path(args.draft_root)
    if not draft_root.exists():
        raise SystemExit(f"Draft root not found: {draft_root}")

    drafts = iter_drafts(draft_root)
    if not drafts:
        raise SystemExit(f"No draft files found under: {draft_root}")

    created: list[dict[str, object]] = []
    skipped: list[dict[str, object]] = []

    for draft_path in drafts:
        draft = parse_draft(draft_path)
        existing_url = find_existing_issue(args.repo, str(draft["title"]))
        if existing_url:
            skipped.append({"title": draft["title"], "url": existing_url, "reason": "already exists"})
            continue

        if args.dry_run:
            created.append({"title": draft["title"], "url": None, "reason": "dry-run"})
            continue

        issue_url = create_issue(args.repo, draft)
        created.append({"title": draft["title"], "url": issue_url, "reason": "created"})

    print(json.dumps({"created": created, "skipped": skipped}, indent=2))


if __name__ == "__main__":
    main()
