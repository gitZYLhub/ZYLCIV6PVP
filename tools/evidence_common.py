"""Shared deterministic evidence helpers for repository-local audit tools."""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import subprocess
from pathlib import Path
from typing import Any


class EvidenceError(ValueError):
    """Raised when an evidence input or output boundary is invalid."""


def canonical_json(value: Any) -> str:
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
        allow_nan=False,
    )


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run_git(project_root: Path, arguments: list[str]) -> str:
    completed = subprocess.run(
        ["git", "-C", str(project_root), *arguments],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return completed.stdout.strip()


def get_git_state(project_root: Path) -> dict[str, Any]:
    commit = run_git(project_root, ["rev-parse", "HEAD"])
    committed_at = run_git(project_root, ["show", "-s", "--format=%cI", "HEAD"])
    dirty_paths = [
        line
        for line in run_git(project_root, ["status", "--porcelain"]).splitlines()
        if line
    ]
    return {
        "commit": commit,
        "committedAt": committed_at,
        "dirty": bool(dirty_paths),
        "dirtyPathCount": len(dirty_paths),
    }


def parse_git_datetime(value: str) -> dt.datetime:
    parsed = dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def ensure_repository_input(path: Path, project_root: Path, label: str) -> str:
    try:
        return path.resolve().relative_to(project_root.resolve()).as_posix()
    except ValueError as error:
        raise EvidenceError(f"{label} must stay inside the project repository.") from error


def ensure_artifact_output(path: Path, artifacts_root: Path) -> Path:
    resolved = path.resolve()
    try:
        resolved.relative_to(artifacts_root.resolve())
    except ValueError as error:
        raise EvidenceError(f"Output must stay inside {artifacts_root}") from error
    return resolved


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as stream:
        value = json.load(stream)
    if not isinstance(value, dict):
        raise EvidenceError(f"JSON root must be an object: {path}")
    return value
