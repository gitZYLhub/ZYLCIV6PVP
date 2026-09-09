#!/usr/bin/env python3
"""Audit Civ VI Lua.log for fatal script errors with repository evidence guards."""

from __future__ import annotations

import argparse
import copy
import datetime as dt
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

TOOLS_ROOT = Path(__file__).resolve().parents[1]
if str(TOOLS_ROOT) not in sys.path:
    sys.path.insert(0, str(TOOLS_ROOT))

from evidence_common import (  # noqa: E402
    EvidenceError,
    canonical_json,
    ensure_artifact_output,
    ensure_repository_input,
    get_git_state,
    load_json,
    parse_git_datetime,
    sha256_bytes,
)


TOOL_VERSION = 1
PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = PROJECT_ROOT / "manifest" / "lua-log-contract.json"
ARTIFACTS_ROOT = PROJECT_ROOT / "artifacts"
LUA_LOCATION = re.compile(r"^\s*(?P<path>.*?\.lua):(?P<line>\d+):", re.IGNORECASE)
LOAD_FILE = re.compile(r"\bfile=(?P<path>.+?\.lua)\s*$", re.IGNORECASE)


class ContractError(EvidenceError):
    """Raised when the checked-in Lua.log contract is malformed."""


def validate_contract(contract: dict[str, Any]) -> None:
    issues: list[str] = []
    if contract.get("schemaVersion") != 1:
        issues.append("schemaVersion must be 1")
    for identity_field in ("packageName", "semanticVersion", "modId", "civ6BuildId"):
        if not isinstance(contract.get(identity_field), str) or not contract[identity_field]:
            issues.append(f"{identity_field} must be a non-empty string")
    if contract.get("expectedFileName") != "Lua.log":
        issues.append("expectedFileName must be Lua.log")
    minimum_lines = contract.get("minimumLineCount")
    if not isinstance(minimum_lines, int) or minimum_lines < 1:
        issues.append("minimumLineCount must be a positive integer")
    radius = contract.get("contextRadius")
    if not isinstance(radius, int) or radius < 1 or radius > 20:
        issues.append("contextRadius must be an integer from 1 through 20")

    pattern_ids: set[str] = set()
    patterns = contract.get("fatalPatterns")
    if not isinstance(patterns, list) or not patterns:
        issues.append("fatalPatterns must be a non-empty array")
        patterns = []
    for pattern in patterns:
        if not isinstance(pattern, dict):
            issues.append("each fatal pattern must be an object")
            continue
        pattern_id = pattern.get("id")
        if not isinstance(pattern_id, str) or not pattern_id or pattern_id in pattern_ids:
            issues.append(f"invalid fatal pattern id: {pattern_id}")
        else:
            pattern_ids.add(pattern_id)
        expression = pattern.get("regex")
        if not isinstance(expression, str) or not (
            expression.startswith("^") and expression.endswith("$")
        ):
            issues.append(f"fatal pattern must be anchored: {pattern_id}")
        else:
            try:
                re.compile(expression, re.IGNORECASE | re.MULTILINE)
            except re.error as error:
                issues.append(f"fatal pattern regex is invalid: {pattern_id}: {error}")
        if not isinstance(pattern.get("rationale"), str) or not pattern["rationale"].strip():
            issues.append(f"fatal pattern has no rationale: {pattern_id}")

    coverage = contract.get("coverage")
    if not isinstance(coverage, dict) or coverage.get("fatalPatterns") != len(patterns):
        issues.append("coverage metadata does not match fatalPatterns")
    if issues:
        raise ContractError("Invalid Lua.log contract:\n- " + "\n- ".join(issues))


def sanitize_lua_path(value: str) -> str:
    normalized = value.strip().strip('"').replace("\\", "/")
    lowered = normalized.lower()
    mods_marker = "/mods/"
    marker_index = lowered.rfind(mods_marker)
    if marker_index >= 0:
        remainder = normalized[marker_index + len(mods_marker) :]
        pieces = remainder.split("/", 1)
        if len(pieces) == 2 and pieces[1]:
            return pieces[1]
    if re.match(r"^[A-Za-z]:/", normalized) or normalized.startswith("/"):
        return "<absolute>/" + normalized.rsplit("/", 1)[-1]
    return normalized


def sanitize_fatal_line(value: str) -> str:
    load_match = LOAD_FILE.search(value)
    if load_match:
        return value[: load_match.start("path")] + sanitize_lua_path(load_match.group("path"))
    return re.sub(
        r"[A-Za-z]:[\\/][^\r\n]*",
        lambda match: "<absolute>/" + match.group(0).replace("\\", "/").rsplit("/", 1)[-1],
        value,
    )


def context_locations(lines: list[str], first: int, last: int) -> list[dict[str, Any]]:
    locations: set[tuple[str, int]] = set()
    for line in lines[first:last]:
        match = LUA_LOCATION.match(line)
        if match:
            locations.add((sanitize_lua_path(match.group("path")), int(match.group("line"))))
        load_match = LOAD_FILE.search(line)
        if load_match:
            locations.add((sanitize_lua_path(load_match.group("path")), 0))
    return [
        {"path": path, "line": line_number if line_number > 0 else None}
        for path, line_number in sorted(locations)
    ]


def analyze_log(text: str, contract: dict[str, Any]) -> dict[str, Any]:
    lines = text.splitlines()
    fatal_results: list[dict[str, Any]] = []
    radius = contract["contextRadius"]
    for pattern in contract["fatalPatterns"]:
        expression = re.compile(pattern["regex"], re.IGNORECASE | re.MULTILINE)
        for match in expression.finditer(text):
            line_number = text.count("\n", 0, match.start()) + 1
            first = max(0, line_number - 1 - radius)
            last = min(len(lines), line_number + radius)
            line_text = sanitize_fatal_line(match.group(0).strip())
            result = {
                "line": line_number,
                "patternId": pattern["id"],
                "text": line_text,
                "locations": context_locations(lines, first, last),
            }
            fatal_results.append(result)

    fatal_results.sort(key=lambda item: (item["line"], item["patternId"]))
    issues = [
        (
            f"Fatal Lua.log pattern at line {result['line']}: "
            f"{result['patternId']}: {result['text']}"
        )
        for result in fatal_results
    ]
    if len(lines) < contract["minimumLineCount"]:
        issues.append(
            f"Lua.log has {len(lines)} lines; expected at least {contract['minimumLineCount']}."
        )
    semantic = {
        "schemaVersion": 1,
        "minimumLineCountPassed": len(lines) >= contract["minimumLineCount"],
        "fatalErrors": [
            {
                "patternId": result["patternId"],
                "text": result["text"],
                "locations": result["locations"],
            }
            for result in fatal_results
        ],
    }
    return {
        "lineCount": len(lines),
        "fatalErrors": fatal_results,
        "fatalCount": len(fatal_results),
        "patternCounts": {
            pattern["id"]: sum(
                1 for result in fatal_results if result["patternId"] == pattern["id"]
            )
            for pattern in contract["fatalPatterns"]
        },
        "semantic": semantic,
        "issues": issues,
    }


def capture(args: argparse.Namespace) -> int:
    contract_path = Path(args.contract).resolve()
    log_path = Path(args.log).resolve()
    if not contract_path.is_file():
        raise ContractError(f"Contract not found: {contract_path}")
    if not log_path.is_file():
        raise ContractError(f"Lua.log not found: {log_path}")
    contract_relative_path = ensure_repository_input(contract_path, PROJECT_ROOT, "Contract")
    contract = load_json(contract_path)
    validate_contract(contract)
    if log_path.name.lower() != contract["expectedFileName"].lower():
        raise ContractError(
            f"Expected {contract['expectedFileName']}, got {log_path.name}."
        )
    contract_bytes = contract_path.read_bytes()
    contract_sha256 = sha256_bytes(contract_bytes)

    git_state = get_git_state(PROJECT_ROOT)
    before = log_path.stat()
    log_modified = dt.datetime.fromtimestamp(before.st_mtime, tz=dt.timezone.utc)
    committed_at = parse_git_datetime(git_state["committedAt"])
    log_older_than_commit = log_modified < committed_at
    evidence_issues: list[str] = []
    if git_state["dirty"] and not args.allow_dirty:
        evidence_issues.append("Repository is dirty; the log cannot be tied to a clean source commit.")
    if log_older_than_commit and not args.allow_stale:
        evidence_issues.append("Lua.log is older than HEAD; reload Civ VI with this commit before audit.")

    log_bytes = log_path.read_bytes()
    try:
        log_text = log_bytes.decode("utf-8-sig")
    except UnicodeDecodeError as error:
        raise ContractError(f"Lua.log is not valid UTF-8: {error}") from error
    analysis = analyze_log(log_text, contract)
    after = log_path.stat()
    changed_during_capture = (before.st_size, before.st_mtime_ns) != (
        after.st_size,
        after.st_mtime_ns,
    )
    if changed_during_capture:
        evidence_issues.append("Lua.log changed while it was being audited.")

    semantic = dict(analysis["semantic"])
    semantic["contractSha256"] = contract_sha256
    semantic_sha256 = sha256_bytes(canonical_json(semantic).encode("utf-8"))
    baseline_match: bool | None = None
    baseline_semantic_sha256: str | None = None
    if args.baseline:
        baseline = load_json(Path(args.baseline).resolve())
        baseline_semantic_sha256 = baseline.get("semanticSha256")
        baseline_match = baseline_semantic_sha256 == semantic_sha256
        if not baseline_match:
            evidence_issues.append("Lua.log audit differs from the requested baseline.")

    issues = [*analysis["issues"], *evidence_issues]
    report = {
        "schemaVersion": 1,
        "toolVersion": TOOL_VERSION,
        "generatedAtUtc": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
        "packageName": contract["packageName"],
        "semanticVersion": contract["semanticVersion"],
        "contract": {
            "path": contract_relative_path,
            "sha256": contract_sha256,
            "civ6BuildId": contract["civ6BuildId"],
        },
        "repository": git_state,
        "log": {
            "fileName": log_path.name,
            "sizeBytes": len(log_bytes),
            "modifiedAtUtc": log_modified.isoformat().replace("+00:00", "Z"),
            "sha256": sha256_bytes(log_bytes),
            "olderThanCommit": log_older_than_commit,
            "changedDuringCapture": changed_during_capture,
            "lineCount": analysis["lineCount"],
        },
        "summary": {
            "fatalCount": analysis["fatalCount"],
            "minimumLineCountPassed": analysis["semantic"]["minimumLineCountPassed"],
            "evidenceGuardsPassed": not git_state["dirty"]
            and not log_older_than_commit
            and not changed_during_capture,
            "diagnosticOverrides": {
                "allowDirty": bool(args.allow_dirty),
                "allowStale": bool(args.allow_stale),
            },
            "baselineMatch": baseline_match,
            "baselineSemanticSha256": baseline_semantic_sha256,
        },
        "patternCounts": analysis["patternCounts"],
        "fatalErrors": analysis["fatalErrors"],
        "semanticSha256": semantic_sha256,
        "semantic": semantic,
        "issues": issues,
    }

    default_name = f"{contract['packageName']}-{contract['semanticVersion']}-lua-log-audit.json"
    output_path = ensure_artifact_output(
        Path(args.output) if args.output else ARTIFACTS_ROOT / "reports" / default_name,
        ARTIFACTS_ROOT,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(canonical_json(report) + "\n", encoding="utf-8", newline="\n")
    print(f"Lua.log audit report created: {output_path}")
    print(f"Lines    : {analysis['lineCount']}")
    print(f"Fatal    : {analysis['fatalCount']}")
    print(f"Semantic : {semantic_sha256}")
    if issues:
        print("Issues:")
        for issue in issues:
            print(f"- {issue}")
        return 1
    return 0


def self_test() -> int:
    contract = {
        "schemaVersion": 1,
        "packageName": "Fixture",
        "semanticVersion": "0.0.0",
        "modId": "fixture",
        "civ6BuildId": "fixture",
        "expectedFileName": "Lua.log",
        "minimumLineCount": 1,
        "contextRadius": 3,
        "coverage": {"fatalPatterns": 3},
        "fatalPatterns": [
            {"id": "runtime", "regex": r"^Runtime Error:\s*.+$", "rationale": "Fixture."},
            {"id": "load", "regex": r"^Error loading file\b.*$", "rationale": "Fixture."},
            {"id": "trace", "regex": r"^stack traceback:\s*$", "rationale": "Fixture."},
        ],
    }
    validate_contract(contract)
    clean = analyze_log(
        "Map Script: Attempt to place using fallback\nMods: Failed to create mods browser search context!",
        contract,
    )
    if clean["issues"] or clean["fatalCount"] != 0:
        raise AssertionError("non-fatal Lua.log fixture failed")
    broken_text = "\n".join(
        [
            "Runtime Error: bad argument #1",
            "stack traceback:",
            "C:\\Users\\Fixture\\Documents\\My Games\\Mods\\Package\\scripts\\broken.lua:53: in function 'Run'",
            "Error loading file where=, file=C:\\Users\\Fixture\\Documents\\My Games\\Mods\\Package\\scripts\\broken.lua",
        ]
    )
    broken = analyze_log(broken_text, contract)
    if broken["fatalCount"] != 3 or len(broken["issues"]) != 3:
        raise AssertionError("fatal Lua.log fixture was accepted")
    location_paths = {
        location["path"]
        for result in broken["fatalErrors"]
        for location in result["locations"]
    }
    if (
        "scripts/broken.lua" not in location_paths
        or any("Users" in path or re.match(r"^[A-Za-z]:/", path) for path in location_paths)
        or any("C:" in result["text"] for result in broken["fatalErrors"])
    ):
        raise AssertionError("Lua.log path sanitization fixture failed")
    invalid = copy.deepcopy(contract)
    invalid["fatalPatterns"][0]["regex"] = "["
    try:
        validate_contract(invalid)
    except ContractError:
        pass
    else:
        raise AssertionError("invalid fatal regex fixture was accepted")
    print("Lua.log audit self-test passed.")
    return 0


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", help="Path to Civ VI Lua.log")
    parser.add_argument("--contract", default=str(DEFAULT_CONTRACT))
    parser.add_argument("--baseline", help="Earlier audit report whose semantic hash must match")
    parser.add_argument("--output", help="Report path inside the project artifacts directory")
    parser.add_argument("--allow-dirty", action="store_true", help="Allow a diagnostic dirty-tree audit")
    parser.add_argument("--allow-stale", action="store_true", help="Allow a diagnostic stale-log audit")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if not args.self_test and not args.log:
        parser.error("--log is required unless --self-test is used")
    return args


def main() -> int:
    args = parse_arguments()
    try:
        if args.self_test:
            return self_test()
        return capture(args)
    except (EvidenceError, OSError, re.error, subprocess.SubprocessError) as error:
        print(f"Lua.log audit failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
