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
sets, files, archives, extras, patches = {}, {}, {}, {}, {}
for l in pathlib.Path("sets.txt").read_text(encoding="utf-8").splitlines():
    if not l or l.startswith("#"):
        continue
    f = l.split("|")
    if f[0] == "set" and len(f) == 10:
        sets[f[1]] = f
        files[f[1]] = []
    elif f[0] == "archive" and len(f) == 5:
        archives[f[1]] = f
    elif f[0] == "file" and len(f) in (6, 7) and (len(f) == 6 or f[6] == "extra"):
        files.setdefault(f[1], []).append(f)
    elif f[0] == "extra" and len(f) == 4:
        extras[f[1]] = f
    elif f[0] == "patch" and len(f) == 5 and f[4] in ("0", "1"):
        patches.setdefault(f[1], []).append(f)
    else:
        errors.append(f"unreadable line: {l[:80]}")
if want != list(sets):
    errors.append(f"sets.in has {want}, sets.txt has {list(sets)}; run scripts/pin.sh")
for sid, s in sets.items():
    allfs = files[sid]
    fs = [f for f in allfs if len(f) == 6]       # what the recommended patch needs
    more = [f for f in allfs if len(f) == 7]     # only the other patches need these
    arc = archives.get(sid)
    # The download is the archive, for a set that is one; else the files.
    if int(s[7]) != len(fs) or int(s[8]) != (int(arc[3]) if arc else sum(int(f[3]) for f in fs)):
        errors.append(f"{sid}: the totals do not match the files")
    if arc and (not re.fullmatch(r"[0-9a-f]{64}", arc[2]) or not arc[4].startswith("https://")):
        errors.append(f"{sid}: bad archive line")
    # The other patches: counted apart, and each patch is a file that is there.
    ex = extras.get(sid)
    if bool(more) != bool(ex) or (ex and (int(ex[2]) != len(more) or int(ex[3]) != sum(int(f[3]) for f in more))):
        errors.append(f"{sid}: the extra totals do not match the files")
    ps = patches.get(sid, [])
    if bool(ps) != bool(ex):
        errors.append(f"{sid}: patches and extras disagree")
    if ps:
        have = {f[5] for f in allfs}
        if sum(p[4] == "1" for p in ps) != 1:
            errors.append(f"{sid}: expected exactly one recommended patch")
        for p in ps:
            if p[2] not in have or not p[2].lower().endswith(".sfz"):
                errors.append(f"{sid}: patch {p[2]} is not a listed .sfz")
        if len({p[2] for p in ps}) != len(ps) or len({p[3] for p in ps}) != len(ps):
            errors.append(f"{sid}: a patch path or name is repeated")
    # One instrument: exactly one .sfz in the shallowest folder that has any
    # (the files it #includes live in folders below it).
    sfz = [f[5] for f in fs if f[5].lower().endswith(".sfz")]
    depth = min((s.count("/") for s in sfz), default=None)
    top = [s for s in sfz if s.count("/") == depth]
    if len(top) != 1:
        errors.append(f"{sid}: expected one instrument .sfz, found {len(top)}")
    # An archive may carry its licence in its readme.
    if not any(re.match(r"(LICENSE|LICENCE|COPYING)" + ("|README|readme" if arc else ""), f[5], re.I) for f in fs):
        errors.append(f"{sid}: no licence file")
    if len({f[5] for f in allfs}) != len(allfs):
        errors.append(f"{sid}: a path is listed twice")
    for f in allfs:
        if not re.fullmatch(r"[0-9a-f]{64}", f[2]):
            errors.append(f"{sid}: bad checksum for {f[5]}")
        # The installer hands these to curl in a config file, between quotes.
        if re.search(r'["\\]', f[4] + f[5]):
            errors.append(f"{sid}: a quote or backslash in {f[5]}")
        if not (f[4].startswith("archive:") if arc else re.match(r"https://raw\.githubusercontent\.com/[^/]+/[^/]+/[0-9a-f]{40}/", f[4])):
            errors.append(f"{sid}: {f[5]} is not pinned to a commit")
        if f[5].startswith(("/", "..")) or "/../" in f[5] or "\\" in f[5]:
            errors.append(f"{sid}: {f[5]} leaves the set's folder")
for e in errors:
    print("check-sets:", e, file=sys.stderr)
if errors:
    sys.exit(1)
print(f"sets.txt is consistent: {len(sets)} sets, {sum(len(v) for v in files.values())} files")
PY
