#!/usr/bin/env python3
"""Fast source-tree checks that do not require Flutter or Dart."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"

REQUIRED = [
    "lib/main.dart",
    "lib/app/bootstrap.dart",
    "lib/core/domain/game_contracts/game_contract.dart",
    "lib/core/domain/game_contracts/replay.dart",
    "lib/data/database/app_database.dart",
    "lib/multiplayer/host/host_session_server.dart",
    "lib/multiplayer/client/lan_session_client.dart",
    "lib/games/chrono_lock/domain/chrono_lock.dart",
    "test/games/chrono_lock_test.dart",
    ".github/workflows/ci.yml",
]

IMPORT_RE = re.compile(r"^\s*(?:import|export|part)\s+['\"]([^'\"]+)['\"]", re.MULTILINE)


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)


def main() -> int:
    failures: list[str] = []

    for relative in REQUIRED:
        if not (ROOT / relative).is_file():
            fail(f"missing required file: {relative}", failures)

    dart_files = sorted(ROOT.rglob("*.dart"))
    if not dart_files:
        fail("no Dart files found", failures)

    for path in dart_files:
        text = path.read_text(encoding="utf-8")
        relative_path = path.relative_to(ROOT)
        for target in IMPORT_RE.findall(text):
            if target.startswith(("dart:", "package:")):
                continue
            candidate = (path.parent / target).resolve()
            is_generated_part = target.endswith((".g.dart", ".freezed.dart"))
            if not candidate.is_file() and not is_generated_part:
                fail(f"broken relative reference in {relative_path}: {target}", failures)

        is_game_domain = path.is_relative_to(LIB / "games") and "domain" in path.parts
        if is_game_domain and re.search(r"(?<![A-Za-z0-9_])Random\(", text):
            fail(f"unseeded Random constructor in game code: {relative_path}", failures)
        if is_game_domain and "DateTime.now" in text:
            fail(f"wall clock used in game code: {relative_path}", failures)
        if re.search(r"\b(?:TODO|FIXME)\b", text):
            fail(f"unfinished marker in {relative_path}", failures)

    manifest = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    for asset in re.findall(r"^\s+-\s+(assets/[^\s]+)\s*$", manifest, re.MULTILINE):
        if not (ROOT / asset).is_file():
            fail(f"missing declared asset: {asset}", failures)

    if failures:
        print("Source validation failed:")
        for item in failures:
            print(f"- {item}")
        return 1

    print(f"Source validation passed: {len(dart_files)} Dart files checked.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
