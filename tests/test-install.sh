#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Runs install.sh against two made-up sets served from local files: the
# listing, the install, the metadata, running it twice, a download that does
# not match its checksum, and the uninstall. Needs no network.
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { echo "FAILED: $*" >&2; exit 1; }

src="$work/src"; mkdir -p "$src/samples"
# curl on Windows is a native program that needs C:/... in a file:// address.
url_root="$src"
if command -v cygpath >/dev/null 2>&1; then url_root="/$(cygpath -m "$src")"; fi
printf 'sfz one' > "$src/one.sfz"
printf 'sample a' > "$src/samples/a.flac"
printf 'licence text' > "$src/LICENSE"
printf 'sfz two' > "$src/two.sfz"
sum() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }
size() { wc -c < "$1" | tr -d ' '; }
{
    echo "set|first|FreePats|electric-guitars|CC0 1.0|Somebody \"Q\" (First)|https://example.org/first|3|0|"
    echo "file|first|$(sum "$src/one.sfz")|$(size "$src/one.sfz")|file://$url_root/one.sfz|First Guitar.sfz"
    echo "file|first|$(sum "$src/samples/a.flac")|$(size "$src/samples/a.flac")|file://$url_root/samples/a.flac|samples/a.flac"
    echo "file|first|$(sum "$src/LICENSE")|$(size "$src/LICENSE")|file://$url_root/LICENSE|LICENSE"
    echo "set|second|FreePats|drums|CC BY 4.0|Somebody Else|https://example.org/second|1|7|Drums by Example.org"
    echo "file|second|$(sum "$src/two.sfz")|$(size "$src/two.sfz")|file://$url_root/two.sfz|Second Kit.sfz"
} > "$work/sets.txt"
export OXIGUITAR_SETS_FILE="$work/sets.txt"
out="$work/out"

"$root/install.sh" --list | grep -q '^first ' || fail "--list does not show the first set"

# Without a yes, nothing is downloaded.
echo n | "$root/install.sh" --sets first --dir "$out" > "$work/log" || fail "declining failed"
[ ! -e "$out/first" ] || fail "downloaded without a yes"

"$root/install.sh" --yes --dir "$out" > "$work/log" || fail "install failed"
[ "$(cat "$out/first/First Guitar.sfz")" = "sfz one" ] || fail "entry missing"
[ "$(cat "$out/first/samples/a.flac")" = "sample a" ] || fail "sample missing"
grep -q '"role": "electric-guitars"' "$out/first/oxiguitar-set.json" || fail "role missing"
grep -q 'Somebody \\"Q\\" (First)' "$out/first/oxiguitar-set.json" || fail "credit not escaped"
grep -q 'Drums by Example.org' "$out/CREDITS.txt" || fail "notice missing from CREDITS.txt"
grep -q 'first' "$out/CREDITS.txt" || fail "set missing from CREDITS.txt"
grep -q 'Drums by Example.org' "$work/log" || fail "notice not shown before the download"

# Again: nothing changes, nothing fails.
"$root/install.sh" --yes --sets first --dir "$out" > /dev/null || fail "second run failed"

# A file that does not match is refused and not left behind.
printf 'tampered' > "$src/two.sfz"
rm -rf "$out/second"
if "$root/install.sh" --yes --sets second --dir "$out" > "$work/log" 2>&1; then fail "a bad checksum was accepted"; fi
[ ! -e "$out/second/Second Kit.sfz" ] || fail "the bad file was kept"
grep -q 'checksum' "$work/log" || fail "no explanation for the bad checksum"

# Uninstall removes the named set only.
"$root/install.sh" --yes --uninstall --sets first --dir "$out" > /dev/null || fail "uninstall failed"
[ ! -e "$out/first" ] || fail "uninstall left the set"

# An unknown set is an error.
if "$root/install.sh" --yes --sets nope --dir "$out" > /dev/null 2>&1; then fail "unknown set accepted"; fi
echo "install.sh: all checks passed"
