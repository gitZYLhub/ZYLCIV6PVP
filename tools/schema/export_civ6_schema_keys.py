#!/usr/bin/env python3
"""Export deterministic Civ VI table key metadata from an installed game."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
import xml.etree.ElementTree as ET
from pathlib import Path


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def quote_identifier(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def extract_tables(connection: sqlite3.Connection) -> dict[str, dict[str, object]]:
    names = [
        row[0]
        for row in connection.execute(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name COLLATE NOCASE"
        )
    ]
    result: dict[str, dict[str, object]] = {}
    for name in names:
        columns_info = list(connection.execute(f"PRAGMA table_info({quote_identifier(name)})"))
        columns = [row[1] for row in columns_info]
        primary_key = [row[1] for row in sorted(columns_info, key=lambda row: row[5]) if row[5] > 0]
        unique_keys: list[list[str]] = []
        for index_row in connection.execute(f"PRAGMA index_list({quote_identifier(name)})"):
            if not index_row[2]:
                continue
            index_name = index_row[1]
            key = [
                row[2]
                for row in connection.execute(
                    f"PRAGMA index_info({quote_identifier(index_name)})"
                )
                if row[2] is not None
            ]
            if key and key != primary_key and key not in unique_keys:
                unique_keys.append(key)
        unique_keys.sort(key=lambda key: tuple(part.casefold() for part in key))
        result[name] = {
            "columns": columns,
            "primaryKey": primary_key,
            "uniqueKeys": unique_keys,
        }
    return result


def load_sql_profile(paths: list[Path]) -> dict[str, dict[str, object]]:
    connection = sqlite3.connect(":memory:")
    try:
        for path in paths:
            connection.executescript(path.read_text(encoding="utf-8-sig"))
        return extract_tables(connection)
    finally:
        connection.close()


def merge_xml_tables(
    tables: dict[str, dict[str, object]], paths: list[Path]
) -> None:
    for path in paths:
        root = ET.parse(path).getroot()
        for table_node in root.findall("Table"):
            name = table_node.attrib["name"]
            columns = [node.attrib["name"] for node in table_node.findall("Column")]
            primary_key = [
                node.attrib["name"]
                for node in table_node.findall("Column")
                if node.attrib.get("primarykey", "false").casefold() == "true"
            ]
            unique_keys = [
                [node.attrib["name"]]
                for node in table_node.findall("Column")
                if node.attrib.get("unique", "false").casefold() == "true"
                and node.attrib["name"] not in primary_key
            ]
            tables[name] = {
                "columns": columns,
                "primaryKey": primary_key,
                "uniqueKeys": unique_keys,
            }


def read_build_id(civ6_root: Path) -> str | None:
    manifest = civ6_root.parent.parent / "appmanifest_289070.acf"
    if not manifest.is_file():
        return None
    match = re.search(r'"buildid"\s+"(?P<value>\d+)"', manifest.read_text(encoding="utf-8-sig"))
    return match.group("value") if match else None


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--civ6-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    civ6_root = args.civ6_root.resolve()
    gameplay_schema = civ6_root / "Base/Assets/Gameplay/Data/Schema/01_GameplaySchema.sql"
    xp1_schema = civ6_root / "DLC/Expansion1/Data/Expansion1_Schema.sql"
    xp2_schema = civ6_root / "DLC/Expansion2/Data/Expansion2_Schema.sql"
    configuration_schemas = [
        civ6_root / "Base/Assets/Configuration/Data/Schema/SetupParameters.sql",
        civ6_root / "Base/Assets/Configuration/Data/Schema/AdditionalTables.sql",
        civ6_root / "Base/Assets/Configuration/Data/Schema/InputConfiguration.sql",
        civ6_root / "Base/Assets/Configuration/Data/Schema/HallofFame.sql",
    ]
    gameplay_xml_schemas = [
        civ6_root / "Base/Assets/Gameplay/Data/Schema/Leader_Tables.xml",
        civ6_root / "Base/Assets/Gameplay/Data/Schema/Diplomacy_Tables.xml",
        civ6_root / "Base/Assets/Gameplay/Data/Schema/Color_Tables.xml",
    ]
    source_paths = [
        gameplay_schema,
        xp1_schema,
        xp2_schema,
        *configuration_schemas,
        *gameplay_xml_schemas,
    ]
    missing = [str(path) for path in source_paths if not path.is_file()]
    if missing:
        raise SystemExit("Missing Civ VI schema files:\n- " + "\n- ".join(missing))

    profiles = {
        "configuration": load_sql_profile(configuration_schemas),
        "gameplay-base": load_sql_profile([gameplay_schema]),
        "gameplay-xp1": load_sql_profile([gameplay_schema, xp1_schema]),
        "gameplay-xp2": load_sql_profile([gameplay_schema, xp2_schema]),
    }
    for profile_name in ("gameplay-base", "gameplay-xp1", "gameplay-xp2"):
        merge_xml_tables(profiles[profile_name], gameplay_xml_schemas)
        profiles[profile_name] = dict(
            sorted(profiles[profile_name].items(), key=lambda item: item[0].casefold())
        )

    report = {
        "schemaVersion": 1,
        "civ6AppId": "289070",
        "civ6BuildId": read_build_id(civ6_root),
        "generator": "tools/schema/export_civ6_schema_keys.py",
        "sourceFiles": [
            {
                "path": path.relative_to(civ6_root).as_posix(),
                "sha256": sha256(path),
            }
            for path in source_paths
        ],
        "profileTableCounts": {
            name: len(tables) for name, tables in profiles.items()
        },
        "profiles": profiles,
    }
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(report, ensure_ascii=False, indent=2, sort_keys=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    print(f"Civ VI schema key snapshot created: {output}")
    print(f"Build ID: {report['civ6BuildId']}")
    for name, count in report["profileTableCounts"].items():
        print(f"{name}: {count} tables")


if __name__ == "__main__":
    main()
