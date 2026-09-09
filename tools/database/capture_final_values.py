#!/usr/bin/env python3
"""Capture and verify deterministic final values from a Civ VI SQLite database."""

from __future__ import annotations

import argparse
import copy
import datetime as dt
import hashlib
import json
import math
import re
import sqlite3
import subprocess
import sys
from pathlib import Path
from typing import Any


TOOL_VERSION = 1
PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = PROJECT_ROOT / "manifest" / "database-final-value-contract.json"
ARTIFACTS_ROOT = PROJECT_ROOT / "artifacts"


class ContractError(ValueError):
    """Raised when the checked-in query contract is malformed."""


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


def normalize_value(value: Any) -> Any:
    if isinstance(value, bytes):
        return {"blobHex": value.hex()}
    if isinstance(value, float) and not math.isfinite(value):
        raise ValueError("SQLite result contains a non-finite floating-point value.")
    if value is None or isinstance(value, (str, int, float)):
        return value
    raise ValueError(f"Unsupported SQLite value type: {type(value).__name__}")


def validate_contract(contract: dict[str, Any]) -> None:
    issues: list[str] = []
    if contract.get("schemaVersion") != 1:
        issues.append("schemaVersion must be 1")
    if not isinstance(contract.get("defaultProfile"), str):
        issues.append("defaultProfile must be a string")
    profiles = contract.get("profiles")
    if not isinstance(profiles, list) or not profiles:
        issues.append("profiles must be a non-empty array")
        profiles = []

    profile_ids: set[str] = set()
    for profile in profiles:
        if not isinstance(profile, dict):
            issues.append("each profile must be an object")
            continue
        profile_id = profile.get("id")
        if not isinstance(profile_id, str) or not profile_id:
            issues.append("each profile needs a non-empty id")
            continue
        if profile_id in profile_ids:
            issues.append(f"duplicate profile id: {profile_id}")
        profile_ids.add(profile_id)
        probes = profile.get("probes")
        if not isinstance(probes, list) or not probes:
            issues.append(f"profile {profile_id} needs probes")
            continue
        probe_ids: set[str] = set()
        for probe in probes:
            if not isinstance(probe, dict):
                issues.append(f"profile {profile_id} has a non-object probe")
                continue
            probe_id = probe.get("id")
            query = probe.get("query")
            columns = probe.get("expectedColumns")
            expected_rows = probe.get("expectedRows")
            if not isinstance(probe_id, str) or not probe_id:
                issues.append(f"profile {profile_id} has a probe without an id")
                continue
            if probe_id in probe_ids:
                issues.append(f"profile {profile_id} repeats probe {probe_id}")
            probe_ids.add(probe_id)
            if not isinstance(probe.get("category"), str) or not probe["category"]:
                issues.append(f"probe {probe_id} has no category")
            if not isinstance(probe.get("rationale"), str) or not probe["rationale"].strip():
                issues.append(f"probe {probe_id} has no rationale")
            if not isinstance(query, str) or not query.lstrip().upper().startswith(("SELECT ", "WITH ")):
                issues.append(f"probe {probe_id} is not a read-only SELECT/CTE")
            elif ";" in query.strip().rstrip(";"):
                issues.append(f"probe {probe_id} contains multiple SQL statements")
            elif not re.search(r"\bORDER\s+BY\b", query, flags=re.IGNORECASE):
                issues.append(f"probe {probe_id} has no deterministic ORDER BY")
            if not isinstance(columns, list) or not columns or not all(
                isinstance(column, str) and column for column in columns
            ):
                issues.append(f"probe {probe_id} has invalid expectedColumns")
                columns = []
            elif len(columns) != len(set(columns)):
                issues.append(f"probe {probe_id} repeats an expected column")
            if not isinstance(expected_rows, list):
                issues.append(f"probe {probe_id} has invalid expectedRows")
                continue
            for row_index, row in enumerate(expected_rows):
                if not isinstance(row, dict) or set(row) != set(columns):
                    issues.append(
                        f"probe {probe_id} row {row_index} does not exactly match expectedColumns"
                    )

    default_profile = contract.get("defaultProfile")
    if isinstance(default_profile, str) and default_profile not in profile_ids:
        issues.append("defaultProfile does not identify a profile")
    if issues:
        raise ContractError("Invalid database final-value contract:\n- " + "\n- ".join(issues))


def execute_profile(
    connection: sqlite3.Connection, profile: dict[str, Any]
) -> tuple[list[dict[str, Any]], list[str]]:
    results: list[dict[str, Any]] = []
    issues: list[str] = []
    for probe in profile["probes"]:
        probe_id = probe["id"]
        try:
            cursor = connection.execute(probe["query"])
            columns = [description[0] for description in cursor.description or []]
            rows = [
                {
                    column: normalize_value(value)
                    for column, value in zip(columns, database_row)
                }
                for database_row in cursor.fetchall()
            ]
            expected_columns = probe["expectedColumns"]
            expected_rows = probe["expectedRows"]
            passed = columns == expected_columns and rows == expected_rows
            result: dict[str, Any] = {
                "id": probe_id,
                "category": probe["category"],
                "columns": columns,
                "rows": rows,
                "passed": passed,
            }
            if not passed:
                result["expectedColumns"] = expected_columns
                result["expectedRows"] = expected_rows
                issues.append(f"Final-value probe failed: {probe_id}")
            results.append(result)
        except (sqlite3.Error, ValueError) as error:
            results.append(
                {
                    "id": probe_id,
                    "category": probe["category"],
                    "columns": [],
                    "rows": [],
                    "passed": False,
                    "error": str(error),
                }
            )
            issues.append(f"Final-value probe could not run: {probe_id}: {error}")
    return results, issues


def run_git(arguments: list[str]) -> str:
    completed = subprocess.run(
        ["git", "-C", str(PROJECT_ROOT), *arguments],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return completed.stdout.strip()


def get_git_state() -> dict[str, Any]:
    commit = run_git(["rev-parse", "HEAD"])
    committed_at = run_git(["show", "-s", "--format=%cI", "HEAD"])
    dirty_paths = [line for line in run_git(["status", "--porcelain"]).splitlines() if line]
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


def ensure_artifact_output(path: Path) -> Path:
    resolved = path.resolve()
    try:
        resolved.relative_to(ARTIFACTS_ROOT.resolve())
    except ValueError as error:
        raise ContractError(f"Output must stay inside {ARTIFACTS_ROOT}") from error
    return resolved


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as stream:
        value = json.load(stream)
    if not isinstance(value, dict):
        raise ContractError(f"JSON root must be an object: {path}")
    return value


def find_profile(contract: dict[str, Any], profile_id: str) -> dict[str, Any]:
    for profile in contract["profiles"]:
        if profile["id"] == profile_id:
            return profile
    raise ContractError(f"Unknown database final-value profile: {profile_id}")


def capture(args: argparse.Namespace) -> int:
    contract_path = Path(args.contract).resolve()
    database_path = Path(args.database).resolve()
    if not contract_path.is_file():
        raise ContractError(f"Contract not found: {contract_path}")
    if not database_path.is_file():
        raise ContractError(f"SQLite database not found: {database_path}")
    try:
        contract_relative_path = contract_path.relative_to(PROJECT_ROOT).as_posix()
    except ValueError as error:
        raise ContractError("Contract must stay inside the project repository.") from error

    contract = load_json(contract_path)
    validate_contract(contract)
    profile_id = args.profile or contract["defaultProfile"]
    profile = find_profile(contract, profile_id)
    contract_sha256 = sha256_file(contract_path)
    git_state = get_git_state()
    before = database_path.stat()
    database_modified = dt.datetime.fromtimestamp(before.st_mtime, tz=dt.timezone.utc)
    committed_at = parse_git_datetime(git_state["committedAt"])
    database_older_than_commit = database_modified < committed_at

    issues: list[str] = []
    if git_state["dirty"] and not args.allow_dirty:
        issues.append("Repository is dirty; the database cannot be tied to a clean source commit.")
    if database_older_than_commit and not args.allow_stale:
        issues.append("Database is older than HEAD; reload Civ VI with this commit before capture.")

    wal_path = Path(str(database_path) + "-wal")
    wal_bytes = wal_path.stat().st_size if wal_path.exists() else 0
    if wal_bytes:
        issues.append("SQLite WAL is non-empty; close Civ VI and capture a checkpointed database.")

    database_uri = database_path.as_uri() + "?mode=ro"
    connection = sqlite3.connect(database_uri, uri=True)
    try:
        connection.execute("PRAGMA query_only = ON")
        quick_check_rows = [row[0] for row in connection.execute("PRAGMA quick_check")]
        quick_check = "; ".join(str(value) for value in quick_check_rows)
        if quick_check_rows != ["ok"]:
            issues.append(f"SQLite quick_check failed: {quick_check}")
        journal_mode = str(connection.execute("PRAGMA journal_mode").fetchone()[0])
        table_count = int(
            connection.execute(
                "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table'"
            ).fetchone()[0]
        )
        probe_results, probe_issues = execute_profile(connection, profile)
        issues.extend(probe_issues)
    finally:
        connection.close()

    database_sha256 = sha256_file(database_path)
    after = database_path.stat()
    database_changed_during_capture = (before.st_size, before.st_mtime_ns) != (
        after.st_size,
        after.st_mtime_ns,
    )
    if database_changed_during_capture:
        issues.append("SQLite database changed while it was being captured.")

    semantic = {
        "schemaVersion": 1,
        "contractSha256": contract_sha256,
        "profileId": profile_id,
        "probes": [
            {
                "id": result["id"],
                "columns": result["columns"],
                "rows": result["rows"],
            }
            for result in probe_results
        ],
    }
    semantic_sha256 = sha256_bytes(canonical_json(semantic).encode("utf-8"))

    baseline_match: bool | None = None
    baseline_sha256: str | None = None
    if args.baseline:
        baseline_path = Path(args.baseline).resolve()
        baseline = load_json(baseline_path)
        baseline_sha256 = baseline.get("semanticSha256")
        baseline_match = baseline_sha256 == semantic_sha256
        if not baseline_match:
            issues.append("Captured final values differ from the requested baseline.")

    passed_count = sum(1 for result in probe_results if result["passed"])
    report = {
        "schemaVersion": 1,
        "toolVersion": TOOL_VERSION,
        "generatedAtUtc": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
        "packageName": contract["packageName"],
        "semanticVersion": contract["semanticVersion"],
        "profileId": profile_id,
        "contract": {
            "path": contract_relative_path,
            "sha256": contract_sha256,
            "civ6BuildId": contract["civ6BuildId"],
        },
        "repository": git_state,
        "database": {
            "fileName": database_path.name,
            "sizeBytes": before.st_size,
            "modifiedAtUtc": database_modified.isoformat().replace("+00:00", "Z"),
            "sha256": database_sha256,
            "journalMode": journal_mode,
            "walBytes": wal_bytes,
            "quickCheck": quick_check,
            "tableCount": table_count,
            "olderThanCommit": database_older_than_commit,
        },
        "summary": {
            "probeCount": len(probe_results),
            "passed": passed_count,
            "failed": len(probe_results) - passed_count,
            "evidenceGuardsPassed": not git_state["dirty"]
            and not database_older_than_commit
            and wal_bytes == 0
            and quick_check_rows == ["ok"]
            and not database_changed_during_capture,
            "diagnosticOverrides": {
                "allowDirty": bool(args.allow_dirty),
                "allowStale": bool(args.allow_stale),
            },
            "baselineMatch": baseline_match,
            "baselineSemanticSha256": baseline_sha256,
        },
        "semanticSha256": semantic_sha256,
        "semantic": semantic,
        "probes": probe_results,
        "issues": issues,
    }

    default_name = (
        f"{contract['packageName']}-{contract['semanticVersion']}-{profile_id}-"
        "database-final-values.json"
    )
    output_path = ensure_artifact_output(
        Path(args.output) if args.output else ARTIFACTS_ROOT / "reports" / default_name
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(canonical_json(report) + "\n", encoding="utf-8", newline="\n")

    print(f"Database final-value report created: {output_path}")
    print(f"Profile    : {profile_id}")
    print(f"Probes     : {passed_count}/{len(probe_results)} passed")
    print(f"Semantic  : {semantic_sha256}")
    print(f"Database  : {database_sha256}")
    if issues:
        print("Issues:")
        for issue in issues:
            print(f"- {issue}")
        return 1
    return 0


def self_test() -> int:
    contract = {
        "schemaVersion": 1,
        "defaultProfile": "fixture",
        "profiles": [
            {
                "id": "fixture",
                "probes": [
                    {
                        "id": "fixture-row",
                        "category": "fixture",
                        "rationale": "Exercise deterministic row comparison.",
                        "query": "SELECT Id, Value FROM Fixture ORDER BY Id",
                        "expectedColumns": ["Id", "Value"],
                        "expectedRows": [{"Id": "A", "Value": 1}],
                    }
                ],
            }
        ],
    }
    validate_contract(contract)
    connection = sqlite3.connect(":memory:")
    try:
        connection.execute("CREATE TABLE Fixture(Id TEXT PRIMARY KEY, Value INTEGER)")
        connection.execute("INSERT INTO Fixture VALUES ('A', 1)")
        results, issues = execute_profile(connection, contract["profiles"][0])
        if issues or not results[0]["passed"]:
            raise AssertionError("positive fixture failed")
        drift = copy.deepcopy(contract["profiles"][0])
        drift["probes"][0]["expectedRows"][0]["Value"] = 2
        results, issues = execute_profile(connection, drift)
        if not issues or results[0]["passed"]:
            raise AssertionError("row drift fixture was accepted")
        invalid = copy.deepcopy(contract)
        invalid["profiles"][0]["probes"][0]["query"] = "DELETE FROM Fixture"
        try:
            validate_contract(invalid)
        except ContractError:
            pass
        else:
            raise AssertionError("write query fixture was accepted")
    finally:
        connection.close()
    print("Database final-value capture self-test passed.")
    return 0


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", help="Path to DebugGameplay.sqlite or another gameplay database")
    parser.add_argument("--contract", default=str(DEFAULT_CONTRACT), help="Final-value query contract")
    parser.add_argument("--profile", help="Contract profile; defaults to defaultProfile")
    parser.add_argument("--output", help="Report path inside the project artifacts directory")
    parser.add_argument("--baseline", help="Earlier final-value report whose semantic hash must match")
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Allow a diagnostic capture from a dirty repository",
    )
    parser.add_argument(
        "--allow-stale",
        action="store_true",
        help="Allow a diagnostic capture when the database predates HEAD",
    )
    parser.add_argument("--self-test", action="store_true", help="Run the in-memory engine self-test")
    args = parser.parse_args()
    if not args.self_test and not args.database:
        parser.error("--database is required unless --self-test is used")
    return args


def main() -> int:
    args = parse_arguments()
    try:
        if args.self_test:
            return self_test()
        return capture(args)
    except (ContractError, OSError, sqlite3.Error, subprocess.SubprocessError) as error:
        print(f"Database final-value capture failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
