#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Reads sets.in and writes sets.txt: for every set, the commit its files are
# taken from and, for every file, its address, size and SHA-256. The
# installers check each download against that and nothing else is trusted.
# Files whose address is already in sets.txt are not downloaded again (the
# address holds the commit, so the file cannot have changed).
#
# Only the files the instrument's .sfz plays are kept, plus the licence and
# readme. A set whose .sfz plays a file that is not in the repository, or
# #includes another file, stops the run.
#
# Usage: scripts/pin.sh            (needs git, python3 and the network)
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
exec python3 -I - <<'PY'
import concurrent.futures as cf, hashlib, pathlib, posixpath, re, subprocess, sys, tarfile, tempfile
import urllib.parse, urllib.request

old = {}
if pathlib.Path("sets.txt").exists():
    for line in pathlib.Path("sets.txt").read_text(encoding="utf-8").splitlines():
        f = line.split("|")
        if f[0] == "file":
            old[f[4]] = (f[2], f[3])  # url -> (sha256, size)

specs = []
for n, line in enumerate(pathlib.Path("sets.in").read_text(encoding="utf-8").splitlines(), 1):
    if not line.strip() or line.startswith("#"):
        continue
    f = line.split("|")
    if len(f) != 10:
        sys.exit(f"sets.in:{n}: expected 10 fields, found {len(f)}")
    specs.append(f)
ids = [s[0] for s in specs]
if len(set(ids)) != len(ids):
    sys.exit("sets.in: an id is used twice")


def sha(url):
    if url in old:
        return old[url]
    h, size = hashlib.sha256(), 0
    last = None
    for _ in range(4):
        try:
            h, size = hashlib.sha256(), 0
            with urllib.request.urlopen(url, timeout=120) as r:
                while chunk := r.read(1 << 20):
                    h.update(chunk)
                    size += len(chunk)
            return h.hexdigest(), str(size)
        except Exception as e:  # retried
            last = e
    sys.exit(f"{url}: {last}")


def referenced(read, tree, entry):
    """The files an .sfz plays and #includes, as repository paths. `read(path)`
    gives a file's text. Sample paths and includes are tried relative to the
    instrument's own folder (where players resolve them) and, failing that,
    to the including file's."""
    base = posixpath.dirname(entry)
    found, todo = set(), [entry]
    seen = set()
    while todo:
        path = todo.pop()
        if path in seen:
            continue
        seen.add(path)
        text = re.sub(r"//[^\n]*", "", read(path))
        if re.search(r"^\s*#define", text, re.M):
            sys.exit(f"{path}: #define is not supported")
        here = posixpath.dirname(path)

        def resolve(name, default=""):
            for d in (base, here):
                cand = posixpath.normpath(posixpath.join(d, default, name))
                if cand in tree:
                    return cand
            sys.exit(f"{path}: {name!r} is not in the repository")

        for m in re.finditer(r'^\s*#include\s+"([^"]+)"', text, re.M):
            inc = resolve(m.group(1).replace("\\", "/"))
            found.add(inc)
            todo.append(inc)
        default = ""
        # sample= and default_path= run to the end of the line or the next opcode.
        for m in re.finditer(r"(default_path|sample)=(.*?)(?=\s+[a-z_0-9]+=|\s*<|\s*$)", text, re.M):
            value = m.group(2).strip().replace("\\", "/")
            if m.group(1) == "default_path":
                default = value
            elif not value.startswith("*"):  # *saw and the like are generators
                found.add(resolve(value, default))
    return found


def emit(sid, name, role, licence, credit, source, notice, entries, download, archive):
    lines.append("|".join(["set", sid, name, role, licence, credit, source, str(len(entries)), str(download), notice]))
    if archive:
        lines.append("|".join(["archive", sid, *archive]))
    for path, h, size, raw in sorted(entries):
        lines.append("|".join(["file", sid, h, size, raw, path]))


def archive_set(sid, name, role, licence, credit, url, entry, dest, notice):
    """A set that is one .tar.xz: the archive is hashed whole, and so is every
    file kept from it, so the installer can pick them out after unpacking."""
    digest, size = sha(url)
    with tempfile.TemporaryDirectory() as tmp:
        arc = pathlib.Path(tmp) / "a.tar.xz"
        urllib.request.urlretrieve(url, arc)
        if hashlib.sha256(arc.read_bytes()).hexdigest() != digest and url not in old:
            sys.exit(f"{sid}: the archive changed while it was read")
        with tarfile.open(arc) as tf:
            members = {posixpath.normpath(m.name): m for m in tf.getmembers() if m.isfile()}
            bad = [n for n in members if n.startswith(("/", "..")) or ".." in n.split("/")]
            if bad:
                sys.exit(f"{sid}: unsafe path in the archive: {bad[0]}")
            cands = [n for n in members if n == entry or n.endswith("/" + entry)]
            if len(cands) != 1:
                sfzs = sorted(n for n in members if n.lower().endswith(".sfz"))
                sys.exit(f"{sid}: {entry} found {len(cands)} times in the archive; its .sfz files: {sfzs}")
            real = cands[0]
            top = real[: -len(entry)]  # the archive's own top folder, if any
            tree = {n[len(top):] for n in members if n.startswith(top)}
            read = lambda p: tf.extractfile(members[top + p]).read().decode("utf-8", "replace")
            keep = referenced(read, tree, entry)
            keep |= {t for t in tree if "/" not in t and re.match(r"(LICENSE|LICENCE|COPYING|README)", t, re.I)}
            keep.discard(entry)
            entries = []
            for p in sorted(keep) + [entry]:
                data = tf.extractfile(members[top + p]).read()
                path = posixpath.join(posixpath.dirname(entry), dest + ".sfz") if p == entry else p
                entries.append((path, hashlib.sha256(data).hexdigest(), str(len(data)), "archive:" + top + p))
    emit(sid, name, role, licence, credit, url, notice, entries, int(size), (digest, size, url))
    print(f"{sid}: {len(entries)} files from an archive of {int(size) / 1e6:.1f} MB", file=sys.stderr)


lines = ["# Generated by scripts/pin.sh from sets.in. Do not edit by hand.",
         "# set|id|name|role|licence|credit|source|files|bytes|notice",
         "# archive|id|sha256|size|url   (sets that are one .tar.xz)",
         "# file|id|sha256|size|url (or archive:path in the archive)|path in the set's folder"]
for sid, name, role, licence, credit, repo, ref, entry, dest, notice in specs:
    if role not in ("clean-guitars", "overdriven-guitars", "distorted-guitars",
                    "nylon-guitars", "steel-guitars", "basses", "drums"):
        sys.exit(f"{sid}: unknown role {role}")
    for v in (name, credit, notice, dest):
        if '"' in v or "\\" in v:
            sys.exit(f"{sid}: quotes and backslashes are not allowed in {v!r}")
    if repo.startswith("https://"):
        archive_set(sid, name, role, licence, credit, repo, entry, dest, notice)
        continue
    url = f"https://github.com/{repo}"
    if re.fullmatch(r"[0-9a-f]{40}", ref):
        commit = ref
    else:
        out = subprocess.run(["git", "ls-remote", url, ref], check=True, capture_output=True, text=True).stdout
        commit = out.split()[0] if out.strip() else sys.exit(f"{sid}: {ref} not found in {repo}")
    with tempfile.TemporaryDirectory() as tmp:
        git = lambda *a: subprocess.run(["git", "-C", tmp, *a], check=True, capture_output=True)
        git("init", "-q")
        git("fetch", "-q", "--depth", "1", "--filter=blob:none", url, commit)
        tree = [t for t in git("ls-tree", "-r", "-z", "--name-only", commit).stdout.decode().split("\0") if t]
        if entry not in tree:
            sys.exit(f"{sid}: {entry} is not in {repo}")
        keep = referenced(lambda p: git("show", f"{commit}:{p}").stdout.decode("utf-8", "replace"), set(tree), entry)
    keep |= {t for t in tree if "/" not in t and re.match(r"(LICENSE|LICENCE|COPYING|README)", t, re.I)}
    keep.discard(entry)
    jobs = {p: f"https://raw.githubusercontent.com/{repo}/{commit}/" + urllib.parse.quote(p) for p in sorted(keep) + [entry]}
    with cf.ThreadPoolExecutor(8) as pool:
        sums = dict(zip(jobs, pool.map(sha, jobs.values())))
    entries = []
    for p, raw in jobs.items():
        # The entry keeps its folder and takes its new name; the rest stays where it was.
        path = posixpath.join(posixpath.dirname(entry), dest + ".sfz") if p == entry else p
        entries.append((path, sums[p][0], sums[p][1], raw))
    emit(sid, name, role, licence, credit, url, notice, entries, sum(int(e[2]) for e in entries), None)
    print(f"{sid}: {len(entries)} files, {repo}@{commit[:10]}", file=sys.stderr)

pathlib.Path("sets.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
