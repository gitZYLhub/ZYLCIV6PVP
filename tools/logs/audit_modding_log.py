#!/usr/bin/env python3
"""Audit Civ VI Modding.log with component ownership and evidence guards."""

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
DEFAULT_CONTRACT = PROJECT_ROOT / "manifest" / "modding-log-contract.json"
ARTIFACTS_ROOT = PROJECT_ROOT / "artifacts"
TIMESTAMP_PREFIX = re.compile(r"^\[[^]]+\]\s*")
MOD_HEADER = re.compile(r"^([0-9a-f-]{36})\s+\((.*)\)$", re.IGNORECASE)
TARGET_COMPONENT = re.compile(r"^\*\s+(.+?)\s+\(([^)]+)\)$")
APPLY_COMPONENT = re.compile(r"^Applying Component - (.+?)\s+\(([^)]+)\)$")
LOAD_LINE = re.compile(r"^(.+?) - Loading (.+)$")
WARNING_LINE = re.compile(r"^(?:Warning|Error):", re.IGNORECASE)
UNABLE_PATH = re.compile(r"^Warning: Unable to load (.+)$", re.IGNORECASE)
COMPONENT_CONTEXT_RESET = (
    "Target Mods (in no particular order):",
    "Target in-game actions (in order of application):",
    "Target front-end actions (in order of application):",
    "Game configuration needs to change to match target config.",
    "Performing pre-configure processing.",
    "Rebuilding configuration database.",
    "ConfigureContent - Importing implicit files, pre settings",
    "Applying settings.",
    "Modding Framework - Apply Settings",
    "Stage: Configure Content",
)


class ContractError(EvidenceError):
    """Raised when the checked-in Modding.log contract is malformed."""


def compile_anchored(
    issues: list[str], expression: Any, label: str, require_anchor: bool = True
) -> None:
    if not isinstance(expression, str) or not expression:
        issues.append(f"{label} must be a non-empty regex")
        return
    if require_anchor and not (expression.startswith("^") and expression.endswith("$")):
        issues.append(f"{label} must be anchored")
    try:
        re.compile(expression, re.IGNORECASE)
    except re.error as error:
        issues.append(f"{label} is invalid: {error}")


def validate_contract(contract: dict[str, Any]) -> None:
    issues: list[str] = []
    if contract.get("schemaVersion") != 1:
        issues.append("schemaVersion must be 1")
    for identity_field in ("packageName", "semanticVersion", "modId", "civ6BuildId"):
        if not isinstance(contract.get(identity_field), str) or not contract[identity_field]:
            issues.append(f"{identity_field} must be a non-empty string")
    if contract.get("expectedFileName") != "Modding.log":
        issues.append("expectedFileName must be Modding.log")
    for field in (
        "minimumLineCount",
        "minimumProjectTargetComponents",
        "minimumProjectAppliedComponents",
    ):
        if not isinstance(contract.get(field), int) or contract[field] < 1:
            issues.append(f"{field} must be a positive integer")

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
        if not isinstance(marker.get("minimumOccurrences"), int) or marker[
            "minimumOccurrences"
        ] < 1:
            issues.append(f"required marker has an invalid minimum: {marker_id}")
        if not isinstance(marker.get("rationale"), str) or not marker["rationale"].strip():
            issues.append(f"required marker has no rationale: {marker_id}")
        compile_anchored(issues, marker.get("regex"), f"required marker regex: {marker_id}")

    external_rule_ids: set[str] = set()
    external_rules = contract.get("externalWarningRules")
    if not isinstance(external_rules, list):
        issues.append("externalWarningRules must be an array")
        external_rules = []
    for rule in external_rules:
        if not isinstance(rule, dict):
            issues.append("each external warning rule must be an object")
            continue
        rule_id = rule.get("id")
        if not isinstance(rule_id, str) or not rule_id or rule_id in external_rule_ids:
            issues.append(f"invalid external warning rule id: {rule_id}")
        else:
            external_rule_ids.add(rule_id)
        kind = rule.get("kind")
        if kind not in {"single", "paired-path"}:
            issues.append(f"external warning rule has an invalid kind: {rule_id}")
        if not isinstance(rule.get("rationale"), str) or not rule["rationale"].strip():
            issues.append(f"external warning rule has no rationale: {rule_id}")
        compile_anchored(issues, rule.get("messageRegex"), f"messageRegex: {rule_id}")
        if kind == "paired-path":
            compile_anchored(
                issues, rule.get("companionRegex"), f"companionRegex: {rule_id}"
            )
            compile_anchored(issues, rule.get("pathRegex"), f"pathRegex: {rule_id}")
            if "DLC" not in str(rule.get("pathRegex", "")):
                issues.append(f"paired external rule must be restricted to DLC paths: {rule_id}")

    component_rule_ids: set[str] = set()
    component_rules = contract.get("allowedComponentWarningRules")
    if not isinstance(component_rules, list):
        issues.append("allowedComponentWarningRules must be an array")
        component_rules = []
    for rule in component_rules:
        if not isinstance(rule, dict):
            issues.append("each component warning rule must be an object")
            continue
        rule_id = rule.get("id")
        if not isinstance(rule_id, str) or not rule_id or rule_id in component_rule_ids:
            issues.append(f"invalid component warning rule id: {rule_id}")
        else:
            component_rule_ids.add(rule_id)
        for field in ("ownerModId", "componentId", "operation", "rationale"):
            if not isinstance(rule.get(field), str) or not rule[field].strip():
                issues.append(f"component warning rule has no {field}: {rule_id}")
        if str(rule.get("ownerModId", "")).lower() == str(contract.get("modId", "")).lower():
            issues.append(f"component warning rule cannot allow the project owner: {rule_id}")
        compile_anchored(issues, rule.get("loadPathRegex"), f"loadPathRegex: {rule_id}")
        compile_anchored(issues, rule.get("messageRegex"), f"messageRegex: {rule_id}")

    coverage = contract.get("coverage")
    if (
        not isinstance(coverage, dict)
        or coverage.get("requiredMarkers") != len(markers)
        or coverage.get("externalWarningRules") != len(external_rules)
        or coverage.get("allowedComponentWarningRules") != len(component_rules)
    ):
        issues.append("coverage metadata does not match the contract arrays")
    if issues:
        raise ContractError("Invalid Modding.log contract:\n- " + "\n- ".join(issues))


def strip_timestamp(line: str) -> str:
    return TIMESTAMP_PREFIX.sub("", line, count=1)


def sanitize_path(value: str) -> str:
    normalized = value.strip().strip('"').replace("\\", "/")
    lowered = normalized.lower()
    marker = "/mods/"
    marker_index = lowered.rfind(marker)
    if marker_index >= 0:
        remainder = normalized[marker_index + len(marker) :]
        pieces = remainder.split("/", 1)
        if len(pieces) == 2 and pieces[1]:
            return pieces[1]
    if re.match(r"^[A-Za-z]:/", normalized) or normalized.startswith("/"):
        return "<absolute>/" + normalized.rsplit("/", 1)[-1]
    return normalized


def sanitize_message(value: str) -> str:
    return re.sub(
        r"[A-Za-z]:[\\/][^\r\n]*",
        lambda match: "<absolute>/" + match.group(0).replace("\\", "/").rsplit("/", 1)[-1],
        value,
    )


def parse_component_owners(
    contents: list[str], contract: dict[str, Any]
) -> dict[str, Any]:
    owners: dict[str, dict[str, str]] = {}
    conflicts: list[dict[str, str]] = []
    current_owner_id: str | None = None
    current_owner_label: str | None = None
    observed_project_labels: set[str] = set()
    project_identity_occurrences = 0
    expected_label = f"{contract['packageName']} {contract['semanticVersion']}"
    project_id = contract["modId"].lower()

    for content in contents:
        stripped = content.strip()
        header = MOD_HEADER.fullmatch(stripped)
        if header:
            current_owner_id = header.group(1).lower()
            current_owner_label = header.group(2)
            if current_owner_id == project_id:
                observed_project_labels.add(current_owner_label)
                if current_owner_label == expected_label:
                    project_identity_occurrences += 1
            continue
        target = TARGET_COMPONENT.fullmatch(stripped)
        if not target or current_owner_id is None or current_owner_label is None:
            continue
        component_id, action_type = target.groups()
        descriptor = {
            "ownerModId": current_owner_id,
            "ownerLabel": current_owner_label,
            "actionType": action_type,
        }
        existing = owners.get(component_id)
        if existing is not None and existing != descriptor:
            conflicts.append(
                {
                    "componentId": component_id,
                    "firstOwnerModId": existing["ownerModId"],
                    "secondOwnerModId": current_owner_id,
                }
            )
        else:
            owners[component_id] = descriptor

    project_targets = sorted(
        component_id
        for component_id, descriptor in owners.items()
        if descriptor["ownerModId"] == project_id
    )
    return {
        "owners": owners,
        "conflicts": sorted(
            conflicts,
            key=lambda item: (
                item["componentId"],
                item["firstOwnerModId"],
                item["secondOwnerModId"],
            ),
        ),
        "projectTargets": project_targets,
        "projectIdentityOccurrences": project_identity_occurrences,
        "observedProjectLabels": sorted(observed_project_labels),
        "expectedProjectLabel": expected_label,
    }


def analyze_log(text: str, contract: dict[str, Any]) -> dict[str, Any]:
    lines = text.splitlines()
    contents = [strip_timestamp(line) for line in lines]
    normalized_text = "\n".join(content.strip() for content in contents)
    ownership = parse_component_owners(contents, contract)
    issues: list[str] = []

    marker_results: list[dict[str, Any]] = []
    for marker in contract["requiredMarkers"]:
        count = len(
            re.findall(marker["regex"], normalized_text, flags=re.IGNORECASE | re.MULTILINE)
        )
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
            issues.append(f"Required Modding.log marker is missing: {marker['id']}")

    if ownership["projectIdentityOccurrences"] < 1:
        labels = ", ".join(ownership["observedProjectLabels"]) or "none"
        issues.append(
            "Expected project identity was not found in Modding.log: "
            f"{contract['modId']} ({ownership['expectedProjectLabel']}); observed labels: {labels}."
        )
    if len(ownership["projectTargets"]) < contract["minimumProjectTargetComponents"]:
        issues.append("Modding.log does not list enough target components for this project.")
    for conflict in ownership["conflicts"]:
        issues.append(
            "Component owner mapping is ambiguous: "
            f"{conflict['componentId']} ({conflict['firstOwnerModId']} / "
            f"{conflict['secondOwnerModId']})."
        )

    project_id = contract["modId"].lower()
    current_component: str | None = None
    current_component_type: str | None = None
    current_owner_id: str | None = None
    current_owner_label: str | None = None
    last_load_operation: str | None = None
    last_load_path: str | None = None
    unmapped_applied_components: set[str] = set()
    applied_project_components: set[str] = set()
    warning_results: list[dict[str, Any]] = []
    external_rule_counts = {rule["id"]: 0 for rule in contract["externalWarningRules"]}
    component_rule_counts = {
        rule["id"]: 0 for rule in contract["allowedComponentWarningRules"]
    }

    index = 0
    while index < len(contents):
        content = contents[index].strip()
        if any(content.startswith(marker) for marker in COMPONENT_CONTEXT_RESET):
            current_component = None
            current_component_type = None
            current_owner_id = None
            current_owner_label = None
            last_load_operation = None
            last_load_path = None
            index += 1
            continue

        applying = APPLY_COMPONENT.fullmatch(content)
        if applying:
            current_component, current_component_type = applying.groups()
            descriptor = ownership["owners"].get(current_component)
            current_owner_id = descriptor["ownerModId"] if descriptor else None
            current_owner_label = descriptor["ownerLabel"] if descriptor else None
            if descriptor is None:
                unmapped_applied_components.add(current_component)
            last_load_operation = None
            last_load_path = None
            if current_owner_id == project_id:
                applied_project_components.add(current_component)
            index += 1
            continue

        loading = LOAD_LINE.fullmatch(content)
        if loading:
            last_load_operation = loading.group(1)
            last_load_path = sanitize_path(loading.group(2))
            index += 1
            continue

        if not WARNING_LINE.match(content):
            index += 1
            continue

        matching_rules: list[tuple[str, str, int, str | None]] = []
        for rule in contract["externalWarningRules"]:
            if not re.fullmatch(rule["messageRegex"], content, flags=re.IGNORECASE):
                continue
            if rule["kind"] == "single":
                matching_rules.append(("external", rule["id"], 1, None))
                continue
            if current_owner_id == project_id or index + 1 >= len(contents):
                continue
            companion = contents[index + 1].strip()
            path_match = UNABLE_PATH.fullmatch(content)
            if (
                path_match
                and re.fullmatch(rule["companionRegex"], companion, flags=re.IGNORECASE)
                and re.fullmatch(rule["pathRegex"], path_match.group(1), flags=re.IGNORECASE)
            ):
                matching_rules.append(
                    ("external", rule["id"], 2, sanitize_path(path_match.group(1)))
                )

        for rule in contract["allowedComponentWarningRules"]:
            if (
                current_owner_id == rule["ownerModId"].lower()
                and current_component == rule["componentId"]
                and last_load_operation == rule["operation"]
                and last_load_path is not None
                and re.fullmatch(rule["loadPathRegex"], last_load_path, flags=re.IGNORECASE)
                and re.fullmatch(rule["messageRegex"], content, flags=re.IGNORECASE)
            ):
                matching_rules.append(("component", rule["id"], 1, None))

        allowed = len(matching_rules) == 1
        rule_kind: str | None = None
        rule_id: str | None = None
        consumed_lines = 1
        warning_path: str | None = None
        if allowed:
            rule_kind, rule_id, consumed_lines, warning_path = matching_rules[0]
            if rule_kind == "external":
                external_rule_counts[rule_id] += 1
            else:
                component_rule_counts[rule_id] += 1
        else:
            owner_text = current_owner_id or "unknown"
            component_text = current_component or "none"
            ambiguity = " (ambiguous allow rules)" if len(matching_rules) > 1 else ""
            issues.append(
                f"Unexpected Modding.log warning at line {index + 1}: "
                f"owner={owner_text}, component={component_text}: {sanitize_message(content)}"
                f"{ambiguity}"
            )

        warning_results.append(
            {
                "line": index + 1,
                "lineCount": consumed_lines,
                "message": sanitize_message(content),
                "allowed": allowed,
                "ruleKind": rule_kind,
                "ruleId": rule_id,
                "warningPath": warning_path,
                "ownerModId": current_owner_id,
                "ownerLabel": current_owner_label,
                "componentId": current_component,
                "componentType": current_component_type,
                "loadOperation": last_load_operation,
                "loadPath": last_load_path,
            }
        )
        index += consumed_lines

    missing_project_applied_components = sorted(
        set(ownership["projectTargets"]) - applied_project_components
    )
    minimum_project_applied_passed = (
        len(applied_project_components) >= contract["minimumProjectAppliedComponents"]
    )
    project_applied_passed = (
        minimum_project_applied_passed and not missing_project_applied_components
    )
    if not minimum_project_applied_passed:
        issues.append("Modding.log does not show enough applied components for this project.")
    if missing_project_applied_components:
        issues.append(
            "Modding.log does not apply every targeted project component: "
            + ", ".join(missing_project_applied_components)
        )
    if unmapped_applied_components:
        issues.append(
            "Modding.log applies components without a Target owner mapping: "
            + ", ".join(sorted(unmapped_applied_components))
        )
    minimum_lines_passed = len(lines) >= contract["minimumLineCount"]
    if not minimum_lines_passed:
        issues.append(
            f"Modding.log has {len(lines)} lines; expected at least {contract['minimumLineCount']}."
        )

    unexpected_warnings = [warning for warning in warning_results if not warning["allowed"]]
    project_warnings = [
        warning for warning in unexpected_warnings if warning["ownerModId"] == project_id
    ]
    allowed_warnings = [warning for warning in warning_results if warning["allowed"]]
    semantic = {
        "schemaVersion": 1,
        "minimumLineCountPassed": minimum_lines_passed,
        "projectIdentityPassed": ownership["projectIdentityOccurrences"] >= 1,
        "projectTargetComponentsPassed": len(ownership["projectTargets"])
        >= contract["minimumProjectTargetComponents"],
        "projectAppliedComponentsPassed": project_applied_passed,
        "requiredMarkers": [
            {"id": marker["id"], "passed": marker["passed"]}
            for marker in marker_results
        ],
        "componentOwnerConflicts": ownership["conflicts"],
        "unmappedAppliedComponents": sorted(unmapped_applied_components),
        "missingProjectAppliedComponents": missing_project_applied_components,
        "unexpectedWarnings": [
            {
                "message": warning["message"],
                "ownerModId": warning["ownerModId"],
                "componentId": warning["componentId"],
                "loadOperation": warning["loadOperation"],
                "loadPath": warning["loadPath"],
            }
            for warning in unexpected_warnings
        ],
    }
    return {
        "lineCount": len(lines),
        "minimumLineCountPassed": minimum_lines_passed,
        "requiredMarkers": marker_results,
        "componentOwnerCount": len(ownership["owners"]),
        "componentOwnerConflicts": ownership["conflicts"],
        "projectIdentityOccurrences": ownership["projectIdentityOccurrences"],
        "expectedProjectLabel": ownership["expectedProjectLabel"],
        "observedProjectLabels": ownership["observedProjectLabels"],
        "projectTargetComponents": ownership["projectTargets"],
        "projectAppliedComponents": sorted(applied_project_components),
        "unmappedAppliedComponents": sorted(unmapped_applied_components),
        "missingProjectAppliedComponents": missing_project_applied_components,
        "warnings": warning_results,
        "externalRuleCounts": external_rule_counts,
        "componentRuleCounts": component_rule_counts,
        "allowedWarningCount": len(allowed_warnings),
        "allowedWarningLineCount": sum(warning["lineCount"] for warning in allowed_warnings),
        "unexpectedWarningCount": len(unexpected_warnings),
        "projectWarningCount": len(project_warnings),
        "semantic": semantic,
        "issues": issues,
    }


def capture(args: argparse.Namespace) -> int:
    contract_path = Path(args.contract).resolve()
    log_path = Path(args.log).resolve()
    if not contract_path.is_file():
        raise ContractError(f"Contract not found: {contract_path}")
    if not log_path.is_file():
        raise ContractError(f"Modding.log not found: {log_path}")
    contract_relative_path = ensure_repository_input(contract_path, PROJECT_ROOT, "Contract")
    contract = load_json(contract_path)
    validate_contract(contract)
    if log_path.name.lower() != contract["expectedFileName"].lower():
        raise ContractError(f"Expected {contract['expectedFileName']}, got {log_path.name}.")
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
        evidence_issues.append("Modding.log is older than HEAD; reload Civ VI with this commit before audit.")

    log_bytes = log_path.read_bytes()
    try:
        log_text = log_bytes.decode("utf-8-sig")
    except UnicodeDecodeError as error:
        raise ContractError(f"Modding.log is not valid UTF-8: {error}") from error
    analysis = analyze_log(log_text, contract)
    after = log_path.stat()
    changed_during_capture = (before.st_size, before.st_mtime_ns) != (
        after.st_size,
        after.st_mtime_ns,
    )
    if changed_during_capture:
        evidence_issues.append("Modding.log changed while it was being audited.")

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
            evidence_issues.append("Modding.log audit differs from the requested baseline.")

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
            "projectIdentityOccurrences": analysis["projectIdentityOccurrences"],
            "projectTargetComponentCount": len(analysis["projectTargetComponents"]),
            "projectAppliedComponentCount": len(analysis["projectAppliedComponents"]),
            "componentOwnerCount": analysis["componentOwnerCount"],
            "componentOwnerConflictCount": len(analysis["componentOwnerConflicts"]),
            "unmappedAppliedComponentCount": len(analysis["unmappedAppliedComponents"]),
            "missingProjectAppliedComponentCount": len(
                analysis["missingProjectAppliedComponents"]
            ),
            "allowedWarningCount": analysis["allowedWarningCount"],
            "allowedWarningLineCount": analysis["allowedWarningLineCount"],
            "unexpectedWarningCount": analysis["unexpectedWarningCount"],
            "projectWarningCount": analysis["projectWarningCount"],
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
        "project": {
            "expectedLabel": analysis["expectedProjectLabel"],
            "observedLabels": analysis["observedProjectLabels"],
            "targetComponents": analysis["projectTargetComponents"],
            "appliedComponents": analysis["projectAppliedComponents"],
            "missingAppliedComponents": analysis["missingProjectAppliedComponents"],
        },
        "requiredMarkers": analysis["requiredMarkers"],
        "externalRuleCounts": analysis["externalRuleCounts"],
        "componentRuleCounts": analysis["componentRuleCounts"],
        "warnings": analysis["warnings"],
        "semanticSha256": semantic_sha256,
        "semantic": semantic,
        "issues": issues,
    }

    default_name = f"{contract['packageName']}-{contract['semanticVersion']}-modding-log-audit.json"
    output_path = ensure_artifact_output(
        Path(args.output) if args.output else ARTIFACTS_ROOT / "reports" / default_name,
        ARTIFACTS_ROOT,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(canonical_json(report) + "\n", encoding="utf-8", newline="\n")
    print(f"Modding.log audit report created: {output_path}")
    print(
        "Markers  : "
        f"{report['summary']['requiredMarkersPassed']}/"
        f"{report['summary']['requiredMarkerCount']} passed"
    )
    print(
        "Project  : "
        f"identity={report['summary']['projectIdentityOccurrences']}, "
        f"target={report['summary']['projectTargetComponentCount']}, "
        f"applied={report['summary']['projectAppliedComponentCount']}"
    )
    print(
        "Warnings : "
        f"{analysis['allowedWarningCount']} allowed records / "
        f"{analysis['unexpectedWarningCount']} unexpected"
    )
    print(f"Semantic : {semantic_sha256}")
    if issues:
        print("Issues:")
        for issue in issues:
            print(f"- {issue}")
        return 1
    return 0


def self_test() -> int:
    project_id = "11111111-1111-1111-1111-111111111111"
    external_id = "22222222-2222-2222-2222-222222222222"
    contract = {
        "schemaVersion": 1,
        "packageName": "Fixture",
        "semanticVersion": "0.0.0",
        "modId": project_id,
        "civ6BuildId": "fixture",
        "expectedFileName": "Modding.log",
        "minimumLineCount": 1,
        "minimumProjectTargetComponents": 1,
        "minimumProjectAppliedComponents": 1,
        "coverage": {
            "requiredMarkers": 1,
            "externalWarningRules": 2,
            "allowedComponentWarningRules": 1,
        },
        "requiredMarkers": [
            {
                "id": "finished",
                "regex": r"^Finished$",
                "minimumOccurrences": 1,
                "rationale": "Fixture marker.",
            }
        ],
        "externalWarningRules": [
            {
                "id": "notice",
                "kind": "single",
                "messageRegex": r"^Warning: global notice$",
                "rationale": "Fixture notice.",
            },
            {
                "id": "dlc-missing",
                "kind": "paired-path",
                "messageRegex": r"^Warning: Unable to load \.\./\.\./\.\./DLC/[^/]+/.+\.xml$",
                "companionRegex": r"^Warning: LocalizedText - Failed loading XML\.$",
                "pathRegex": r"^\.\./\.\./\.\./DLC/[^/]+/.+\.xml$",
                "rationale": "Fixture DLC warning.",
            },
        ],
        "allowedComponentWarningRules": [
            {
                "id": "external-component",
                "ownerModId": external_id,
                "componentId": "ExternalBroken",
                "operation": "UpdateDatabase",
                "loadPathRegex": r"^Data/Broken\.xml$",
                "messageRegex": r"^Warning: UpdateDatabase - Error Loading XML\.$",
                "rationale": "Fixture component warning.",
            }
        ],
    }
    validate_contract(contract)
    clean_text = "\n".join(
        [
            f"[1.000] {project_id} (Fixture 0.0.0)",
            "[1.000]  * FixtureAction (UpdateDatabase)",
            f"[1.000] {external_id} (External)",
            "[1.000]  * ExternalBroken (UpdateDatabase)",
            "[1.000] Finished",
            "[1.000] Applying Component - ExternalBroken (UpdateDatabase)",
            "[1.000] UpdateDatabase - Loading Data/Broken.xml",
            "[1.000] Warning: UpdateDatabase - Error Loading XML.",
            "[1.000] Warning: global notice",
            "[1.000] Warning: Unable to load ../../../DLC/Pack/Text/Missing.xml",
            "[1.000] Warning: LocalizedText - Failed loading XML.",
            "[1.000] Applying Component - FixtureAction (UpdateDatabase)",
            "[1.000] Game configuration needs to change to match target config.",
            "[1.000] Warning: Unable to load ../../../DLC/Pack/Text/Second.xml",
            "[1.000] Warning: LocalizedText - Failed loading XML.",
        ]
    )
    clean = analyze_log(clean_text, contract)
    if (
        clean["issues"]
        or clean["allowedWarningCount"] != 4
        or clean["projectWarningCount"] != 0
    ):
        raise AssertionError("allowed Modding.log fixture failed")
    project_warning = analyze_log(
        clean_text
        + "\n[2.000] Applying Component - FixtureAction (UpdateDatabase)"
        + "\n[2.000] UpdateDatabase - Loading Data/Project.xml"
        + "\n[2.000] Warning: UpdateDatabase - Error Loading XML.",
        contract,
    )
    if project_warning["unexpectedWarningCount"] != 1 or project_warning[
        "projectWarningCount"
    ] != 1:
        raise AssertionError("project component warning fixture was accepted")
    unmapped = analyze_log(
        clean_text + "\n[2.000] Applying Component - Orphan (UpdateDatabase)",
        contract,
    )
    if unmapped["unmappedAppliedComponents"] != ["Orphan"] or not unmapped["issues"]:
        raise AssertionError("unmapped applied component fixture was accepted")
    missing = analyze_log(
        clean_text.replace(
            "[1.000]  * FixtureAction (UpdateDatabase)",
            "[1.000]  * FixtureAction (UpdateDatabase)"
            "\n[1.000]  * FixtureMissing (UpdateDatabase)",
        ),
        contract,
    )
    if missing["missingProjectAppliedComponents"] != ["FixtureMissing"] or not missing[
        "issues"
    ]:
        raise AssertionError("missing targeted project component fixture was accepted")
    wrong_identity = analyze_log(clean_text.replace("Fixture 0.0.0", "Fixture 9.9.9"), contract)
    if wrong_identity["projectIdentityOccurrences"] != 0 or not wrong_identity["issues"]:
        raise AssertionError("wrong project identity fixture was accepted")
    unsafe = copy.deepcopy(contract)
    unsafe["allowedComponentWarningRules"][0]["ownerModId"] = project_id
    try:
        validate_contract(unsafe)
    except ContractError:
        pass
    else:
        raise AssertionError("project warning allow-rule fixture was accepted")
    invalid = copy.deepcopy(contract)
    invalid["externalWarningRules"][0]["messageRegex"] = "["
    try:
        validate_contract(invalid)
    except ContractError:
        pass
    else:
        raise AssertionError("invalid warning regex fixture was accepted")
    if sanitize_path(r"C:\Users\Fixture\Mods\Package\Data\Project.xml") != "Data/Project.xml":
        raise AssertionError("Modding.log path sanitization fixture failed")
    print("Modding.log audit self-test passed.")
    return 0


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", help="Path to Civ VI Modding.log")
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
        print(f"Modding.log audit failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
