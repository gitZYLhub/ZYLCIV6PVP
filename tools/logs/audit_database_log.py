#!/usr/bin/env python3
"""Audit a Civ VI Database.log with repository and freshness evidence guards."""

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
DEFAULT_CONTRACT = PROJECT_ROOT / "manifest" / "database-log-contract.json"
ARTIFACTS_ROOT = PROJECT_ROOT / "artifacts"
ERROR_LINE = re.compile(
    r"^\[[^]]+\]\s+\[([^]]+)\]\s+ERROR:\s*(.*)$", re.IGNORECASE
)
CONTEXT_FILE = re.compile(
    r"\bfrom file\s+(.+?\.(?:xml|sql|modinfo))\.?$", re.IGNORECASE
)


class ContractError(EvidenceError):
    """Raised when the checked-in Database.log contract is malformed."""


def validate_contract(contract: dict[str, Any]) -> None:
    issues: list[str] = []
    if contract.get("schemaVersion") != 1:
        issues.append("schemaVersion must be 1")
    for identity_field in ("packageName", "semanticVersion", "modId", "civ6BuildId"):
        if not isinstance(contract.get(identity_field), str) or not contract[identity_field]:
            issues.append(f"{identity_field} must be a non-empty string")
    radius = contract.get("contextRadius")
    if not isinstance(radius, int) or radius < 1 or radius > 20:
        issues.append("contextRadius must be an integer from 1 through 20")

    marker_ids: set[str] = set()
    markers = contract.get("requiredMarkers")
    if not isinstance(markers, list) or not markers:
        issues.append("requiredMarkers must be a non-empty array")
        markers = []
    for marker in markers:
        if not isinstance(marker, dict):
            issues.append("each required marker must be an object")
            continue
        marker_id = marker.get("id")
        if not isinstance(marker_id, str) or not marker_id or marker_id in marker_ids:
            issues.append(f"invalid required marker id: {marker_id}")
        else:
            marker_ids.add(marker_id)
        if not isinstance(marker.get("minimumOccurrences"), int) or marker["minimumOccurrences"] < 1:
            issues.append(f"required marker has an invalid minimum: {marker_id}")
        if not isinstance(marker.get("rationale"), str) or not marker["rationale"].strip():
            issues.append(f"required marker has no rationale: {marker_id}")
        try:
            re.compile(marker.get("regex", ""), re.IGNORECASE)
        except re.error as error:
            issues.append(f"required marker regex is invalid: {marker_id}: {error}")

    rule_ids: set[str] = set()
    rules = contract.get("allowedErrorRules")
    if not isinstance(rules, list):
        issues.append("allowedErrorRules must be an array")
        rules = []
    for rule in rules:
        if not isinstance(rule, dict):
            issues.append("each allowed error rule must be an object")
            continue
        rule_id = rule.get("id")
        if not isinstance(rule_id, str) or not rule_id or rule_id in rule_ids:
            issues.append(f"invalid allowed error rule id: {rule_id}")
        else:
            rule_ids.add(rule_id)
        if not isinstance(rule.get("scope"), str) or not rule["scope"]:
            issues.append(f"allowed error rule has no scope: {rule_id}")
        elif rule["scope"].lower() in {"gameplay", "configuration"}:
            issues.append(f"allowed error rule cannot cover {rule['scope']}: {rule_id}")
        if not isinstance(rule.get("rationale"), str) or not rule["rationale"].strip():
            issues.append(f"allowed error rule has no rationale: {rule_id}")
        context_regexes = rule.get("contextRegexes")
        if not isinstance(context_regexes, list) or not context_regexes:
            issues.append(f"allowed error rule has no context regexes: {rule_id}")
            context_regexes = []
        if rule.get("requireContextFile") is not True:
            issues.append(f"allowed error rule must require a context file: {rule_id}")
        for label, expression in [
            ("messageRegex", rule.get("messageRegex")),
            ("contextFileRegex", rule.get("contextFileRegex")),
        ]:
            if isinstance(expression, str) and not (
                expression.startswith("^") and expression.endswith("$")
            ):
                issues.append(f"allowed error rule {label} must be anchored: {rule_id}")
        for label, expression in [
            ("messageRegex", rule.get("messageRegex")),
            ("contextFileRegex", rule.get("contextFileRegex")),
            *[("contextRegex", value) for value in context_regexes],
        ]:
            if not isinstance(expression, str) or not expression:
                issues.append(f"allowed error rule has an empty {label}: {rule_id}")
                continue
            try:
                re.compile(expression, re.IGNORECASE)
            except re.error as error:
                issues.append(f"allowed error rule {label} is invalid: {rule_id}: {error}")

    coverage = contract.get("coverage")
    if not isinstance(coverage, dict) or coverage.get("requiredMarkers") != len(markers) or coverage.get(
        "allowedErrorRules"
    ) != len(rules):
        issues.append("coverage metadata does not match the contract arrays")
    if issues:
        raise ContractError("Invalid Database.log contract:\n- " + "\n- ".join(issues))


def sanitize_context_file(value: str) -> str:
    normalized = value.strip().replace("\\", "/")
    if re.match(r"^[A-Za-z]:/", normalized) or normalized.startswith("/"):
        return "<absolute>/" + normalized.rsplit("/", 1)[-1]
    return normalized


def analyze_log(text: str, contract: dict[str, Any]) -> dict[str, Any]:
    lines = text.splitlines()
    issues: list[str] = []
    marker_results: list[dict[str, Any]] = []
    for marker in contract["requiredMarkers"]:
        count = len(re.findall(marker["regex"], text, flags=re.IGNORECASE))
        passed = count >= marker["minimumOccurrences"]
        marker_results.append(
            {
                "id": marker["id"],
                "occurrences": count,
                "minimumOccurrences": marker["minimumOccurrences"],
                "passed": passed,
            }
        )
        if not passed:
            issues.append(f"Required Database.log marker is missing: {marker['id']}")

    radius = contract["contextRadius"]
    error_results: list[dict[str, Any]] = []
    allowed_rule_counts = {rule["id"]: 0 for rule in contract["allowedErrorRules"]}
    structured_error_lines: set[int] = set()
    for line_index, line in enumerate(lines):
        match = ERROR_LINE.match(line)
        if not match:
            continue
        structured_error_lines.add(line_index)
        scope, message = match.groups()
        first = max(0, line_index - radius)
        last = min(len(lines), line_index + radius + 1)
        window_lines = lines[first:last]
        window = "\n".join(window_lines)
        context_files = [
            sanitize_context_file(context_match.group(1))
            for context_line in window_lines
            for context_match in [CONTEXT_FILE.search(context_line)]
            if context_match
        ]
        matching_rules: list[str] = []
        for rule in contract["allowedErrorRules"]:
            if scope.lower() != rule["scope"].lower() or not re.fullmatch(
                rule["messageRegex"], message, flags=re.IGNORECASE
            ):
                continue
            if not all(
                re.search(expression, window, flags=re.IGNORECASE)
                for expression in rule["contextRegexes"]
            ):
                continue
            if rule.get("requireContextFile") and not context_files:
                continue
            if context_files and not all(
                re.fullmatch(rule["contextFileRegex"], path, flags=re.IGNORECASE)
                for path in context_files
            ):
                continue
            matching_rules.append(rule["id"])

        allowed = len(matching_rules) == 1
        rule_id = matching_rules[0] if allowed else None
        if allowed:
            allowed_rule_counts[rule_id] += 1
        else:
            issues.append(f"Unexpected Database.log error at line {line_index + 1}: [{scope}] {message}")
        error_results.append(
            {
                "line": line_index + 1,
                "scope": scope,
                "message": message,
                "allowed": allowed,
                "ruleId": rule_id,
                "contextFiles": sorted(set(context_files)),
            }
        )

    for line_index, line in enumerate(lines):
        if re.search(r"\bERROR\s*:", line, flags=re.IGNORECASE) and line_index not in structured_error_lines:
            issues.append(f"Unparsed Database.log error syntax at line {line_index + 1}.")

    unexpected_errors = [error for error in error_results if not error["allowed"]]
    semantic = {
        "schemaVersion": 1,
        "requiredMarkers": [
            {"id": marker["id"], "passed": marker["passed"]}
            for marker in marker_results
        ],
        "unexpectedErrors": [
            {
                "scope": error["scope"],
                "message": error["message"],
                "contextFiles": error["contextFiles"],
            }
            for error in unexpected_errors
        ],
    }
    return {
        "lineCount": len(lines),
        "requiredMarkers": marker_results,
        "errors": error_results,
        "allowedRuleCounts": allowed_rule_counts,
        "allowedErrorCount": len(error_results) - len(unexpected_errors),
        "unexpectedErrorCount": len(unexpected_errors),
        "semantic": semantic,
        "issues": issues,
    }


def capture(args: argparse.Namespace) -> int:
    contract_path = Path(args.contract).resolve()
    log_path = Path(args.log).resolve()
    if not contract_path.is_file():
        raise ContractError(f"Contract not found: {contract_path}")
    if not log_path.is_file():
        raise ContractError(f"Database.log not found: {log_path}")
    contract_relative_path = ensure_repository_input(contract_path, PROJECT_ROOT, "Contract")
    contract = load_json(contract_path)
    validate_contract(contract)
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
        evidence_issues.append("Database.log is older than HEAD; reload Civ VI with this commit before audit.")

    log_bytes = log_path.read_bytes()
    try:
        log_text = log_bytes.decode("utf-8-sig")
    except UnicodeDecodeError as error:
        raise ContractError(f"Database.log is not valid UTF-8: {error}") from error
    analysis = analyze_log(log_text, contract)
    after = log_path.stat()
    changed_during_capture = (before.st_size, before.st_mtime_ns) != (
        after.st_size,
        after.st_mtime_ns,
    )
    if changed_during_capture:
        evidence_issues.append("Database.log changed while it was being audited.")

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
            evidence_issues.append("Database.log audit differs from the requested baseline.")

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
            "requiredMarkerCount": len(analysis["requiredMarkers"]),
            "requiredMarkersPassed": sum(
                1 for marker in analysis["requiredMarkers"] if marker["passed"]
            ),
            "allowedErrorCount": analysis["allowedErrorCount"],
            "unexpectedErrorCount": analysis["unexpectedErrorCount"],
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
        "requiredMarkers": analysis["requiredMarkers"],
        "allowedRuleCounts": analysis["allowedRuleCounts"],
        "errors": analysis["errors"],
        "semanticSha256": semantic_sha256,
        "semantic": semantic,
        "issues": issues,
    }

    default_name = (
        f"{contract['packageName']}-{contract['semanticVersion']}-database-log-audit.json"
    )
    output_path = ensure_artifact_output(
        Path(args.output) if args.output else ARTIFACTS_ROOT / "reports" / default_name,
        ARTIFACTS_ROOT,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(canonical_json(report) + "\n", encoding="utf-8", newline="\n")
    print(f"Database.log audit report created: {output_path}")
    print(
        "Markers    : "
        f"{report['summary']['requiredMarkersPassed']}/"
        f"{report['summary']['requiredMarkerCount']} passed"
    )
    print(f"Allowed    : {analysis['allowedErrorCount']} external error lines")
    print(f"Unexpected : {analysis['unexpectedErrorCount']} error lines")
    print(f"Semantic   : {semantic_sha256}")
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
        "contextRadius": 3,
        "coverage": {"requiredMarkers": 1, "allowedErrorRules": 1},
        "requiredMarkers": [
            {
                "id": "gameplay-passed",
                "regex": r"\[Gameplay\]: Passed Validation\.",
                "minimumOccurrences": 1,
                "rationale": "Fixture marker.",
            }
        ],
        "allowedErrorRules": [
            {
                "id": "external-fixture",
                "scope": "Localization",
                "messageRegex": r"^duplicate$",
                "contextRegexes": [r"SAFE_TAG", r"CurrentClickouts/.+\.xml"],
                "contextFileRegex": r"^CurrentClickouts/.+\.xml$",
                "requireContextFile": True,
                "rationale": "Fixture rule.",
            }
        ],
    }
    validate_contract(contract)
    clean_text = "\n".join(
        [
            "[1.000] [Gameplay]: Passed Validation.",
            "[2.000] [Localization] ERROR: duplicate",
            "[2.000] SAFE_TAG",
            "[2.000] while updating table X from file CurrentClickouts/a/Text.xml.",
        ]
    )
    clean = analyze_log(clean_text, contract)
    if clean["issues"] or clean["allowedErrorCount"] != 1:
        raise AssertionError("allowed external error fixture failed")
    gameplay_error = analyze_log(
        clean_text + "\n[3.000] [Gameplay] ERROR: no such table: Missing", contract
    )
    if gameplay_error["unexpectedErrorCount"] != 1:
        raise AssertionError("gameplay error fixture was accepted")
    unknown_file = analyze_log(
        clean_text.replace("CurrentClickouts/a/Text.xml", "Mods/Bad/Text.xml"), contract
    )
    if unknown_file["unexpectedErrorCount"] != 1:
        raise AssertionError("unknown localization file fixture was accepted")
    unsafe = copy.deepcopy(contract)
    unsafe["allowedErrorRules"][0]["scope"] = "Gameplay"
    try:
        validate_contract(unsafe)
    except ContractError:
        pass
    else:
        raise AssertionError("Gameplay allow-rule fixture was accepted")
    invalid = copy.deepcopy(contract)
    invalid["allowedErrorRules"][0]["messageRegex"] = "["
    try:
        validate_contract(invalid)
    except ContractError:
        pass
    else:
        raise AssertionError("invalid regex fixture was accepted")
    print("Database.log audit self-test passed.")
    return 0


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", help="Path to Civ VI Database.log")
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
        print(f"Database.log audit failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
