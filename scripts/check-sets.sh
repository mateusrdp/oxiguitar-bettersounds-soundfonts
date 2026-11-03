#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Checks that sets.txt agrees with itself and with sets.in: every set in
# sets.in is there, each set's file count and size add up, every address is
# pinned to a commit, every checksum is well formed, and each set has
# exactly one .sfz, a licence and nothing outside its own folder.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
exec python3 -I - <<'PY'
import pathlib, re, sys

errors = []
want = [l.split("|")[0] for l in pathlib.Path("sets.in").read_text(encoding="utf-8").splitlines()
        if l.strip() and not l.startswith("#")]
sets, files = {}, {}
for l in pathlib.Path("sets.txt").read_text(encoding="utf-8").splitlines():
    if not l or l.startswith("#"):
        continue
    f = l.split("|")
    if f[0] == "set" and len(f) == 10:
        sets[f[1]] = f
        files[f[1]] = []
    elif f[0] == "file" and len(f) == 6:
        files.setdefault(f[1], []).append(f)
    else:
        errors.append(f"unreadable line: {l[:80]}")
if want != list(sets):
    errors.append(f"sets.in has {want}, sets.txt has {list(sets)}; run scripts/pin.sh")
for sid, s in sets.items():
    fs = files[sid]
    if int(s[7]) != len(fs) or int(s[8]) != sum(int(f[3]) for f in fs):
        errors.append(f"{sid}: the totals do not match the files")
    sfz = [f[5] for f in fs if f[5].lower().endswith(".sfz")]
    if len(sfz) != 1:
        errors.append(f"{sid}: expected one .sfz, found {len(sfz)}")
    if not any(re.match(r"(LICENSE|LICENCE|COPYING)", f[5], re.I) for f in fs):
        errors.append(f"{sid}: no licence file")
    if len({f[5] for f in fs}) != len(fs):
        errors.append(f"{sid}: a path is listed twice")
    for f in fs:
        if not re.fullmatch(r"[0-9a-f]{64}", f[2]):
            errors.append(f"{sid}: bad checksum for {f[5]}")
        if not re.match(r"https://raw\.githubusercontent\.com/[^/]+/[^/]+/[0-9a-f]{40}/", f[4]):
            errors.append(f"{sid}: {f[5]} is not pinned to a commit")
        if f[5].startswith(("/", "..")) or "/../" in f[5] or "\\" in f[5]:
            errors.append(f"{sid}: {f[5]} leaves the set's folder")
for e in errors:
    print("check-sets:", e, file=sys.stderr)
if errors:
    sys.exit(1)
print(f"sets.txt is consistent: {len(sets)} sets, {sum(len(v) for v in files.values())} files")
PY
