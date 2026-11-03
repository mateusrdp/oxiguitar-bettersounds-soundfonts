#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Prepares a release in the working tree: VERSION takes the new version and
# the CHANGELOG's [Unreleased] section becomes the section of the release.
# Nothing is committed. Run by the Release workflow of oxiguitar-packages,
# and by CI with a made-up version.
#
# Usage: scripts/release/bump.sh VERSION [YYYY-MM-DD]
#
# Fails, changing nothing, when [Unreleased] is empty or when VERSION is not
# higher than the current one.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
exec python3 -I - "$@" <<'PY'
import datetime, pathlib, re, sys

args = sys.argv[1:]
if not 1 <= len(args) <= 2:
    sys.exit("usage: scripts/release/bump.sh VERSION [YYYY-MM-DD]")
new = args[0].removeprefix("v")
date = args[1] if len(args) == 2 else datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")
if not re.fullmatch(r"\d+\.\d+\.\d+", new):
    sys.exit(f"{new!r} is not a version like 0.1.1")
old = pathlib.Path("VERSION").read_text().strip()
key = lambda v: tuple(int(x) for x in v.split("."))
if key(new) <= key(old):
    sys.exit(f"{new} is not higher than the current version {old}")
text = pathlib.Path("CHANGELOG.md").read_text(encoding="utf-8")
m = re.search(r"^## \[Unreleased\]\n(.*?)(?=^## \[|\Z)", text, re.M | re.S)
if not m or not m.group(1).strip():
    sys.exit("CHANGELOG.md: nothing under [Unreleased]; write what changed first")
body = m.group(1).strip("\n")
out = text[:m.start()] + f"## [Unreleased]\n\n## [{new}] - {date}\n\n{body}\n\n" + text[m.end():]
pathlib.Path("CHANGELOG.md").write_text(out.rstrip("\n") + "\n", encoding="utf-8")
pathlib.Path("VERSION").write_text(new + "\n")
print(f"{old} -> {new} ({date}): CHANGELOG.md, VERSION")
PY
