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
url_root="$src"; arc_url="$work"
if command -v cygpath >/dev/null 2>&1; then url_root="/$(cygpath -m "$src")"; arc_url="/$(cygpath -m "$work")"; fi
printf 'sfz one' > "$src/one.sfz"
printf 'sample a' > "$src/samples/a.flac"
printf 'licence text' > "$src/LICENSE"
printf 'sfz two' > "$src/two.sfz"
printf 'sfz alt' > "$src/alt.sfz"
sum() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'; else shasum -a 256 "$1" | awk '{print $1}'; fi; }
size() { wc -c < "$1" | tr -d ' '; }
arc="$work/arc/third-1.0"; mkdir -p "$arc/samples"
printf 'sfz three' > "$arc/Three.sfz"; printf 'sample b' > "$arc/samples/b.wav"; printf 'read me, CC0' > "$arc/readme.txt"
printf 'not wanted' > "$arc/Other.sfz"
tar -C "$work/arc" -cJf "$work/third.tar.xz" third-1.0
{
    echo "set|first|FreePats|clean-guitars|CC0 1.0|Somebody \"Q\" (First)|https://example.org/first|3|0|"
    echo "file|first|$(sum "$src/one.sfz")|$(size "$src/one.sfz")|file://$url_root/one.sfz|First Guitar.sfz"
    echo "file|first|$(sum "$src/samples/a.flac")|$(size "$src/samples/a.flac")|file://$url_root/samples/a.flac|samples/a.flac"
    echo "file|first|$(sum "$src/LICENSE")|$(size "$src/LICENSE")|file://$url_root/LICENSE|LICENSE"
    echo "extra|first|1|$(size "$src/alt.sfz")"
    echo "file|first|$(sum "$src/alt.sfz")|$(size "$src/alt.sfz")|file://$url_root/alt.sfz|Alt.sfz|extra"
    echo "patch|first|First Guitar.sfz|clean|1"
    echo "patch|first|Alt.sfz|clean small|0"
    echo "set|second|FreePats|drums|CC BY 4.0|Somebody Else|https://example.org/second|1|7|Drums by Example.org"
    echo "file|second|$(sum "$src/two.sfz")|$(size "$src/two.sfz")|file://$url_root/two.sfz|Second Kit.sfz"
    echo "set|third|FreePats|steel-guitars|GPL|Somebody Three|https://example.org/third|3|$(size "$work/third.tar.xz")|"
    echo "archive|third|$(sum "$work/third.tar.xz")|$(size "$work/third.tar.xz")|file://$arc_url/third.tar.xz"
    echo "file|third|$(sum "$arc/Three.sfz")|$(size "$arc/Three.sfz")|archive:third-1.0/Three.sfz|Third.sfz"
    echo "file|third|$(sum "$arc/samples/b.wav")|$(size "$arc/samples/b.wav")|archive:third-1.0/samples/b.wav|samples/b.wav"
    echo "file|third|$(sum "$arc/readme.txt")|$(size "$arc/readme.txt")|archive:third-1.0/readme.txt|readme.txt"
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
grep -q '"role": "clean-guitars"' "$out/first/oxiguitar-set.json" || fail "role missing"
grep -q 'Somebody \\"Q\\" (First)' "$out/first/oxiguitar-set.json" || fail "credit not escaped"
grep -q 'Drums by Example.org' "$out/CREDITS.txt" || fail "notice missing from CREDITS.txt"
grep -q 'first' "$out/CREDITS.txt" || fail "set missing from CREDITS.txt"
grep -q 'Drums by Example.org' "$work/log" || fail "notice not shown before the download"

[ "$(cat "$out/third/Third.sfz")" = "sfz three" ] || fail "archive entry missing"
[ "$(cat "$out/third/samples/b.wav")" = "sample b" ] || fail "archive sample missing"
[ ! -e "$out/third/Other.sfz" ] || fail "a file that is not listed was kept"
for left in "$out"/.oxiguitar-*; do [ ! -e "$left" ] || fail "left behind: $left"; done

# Again: nothing changes, nothing fails.
"$root/install.sh" --yes --sets first --dir "$out" > /dev/null || fail "second run failed"

# What an older version of a set left in its folder goes; a folder this
# installer did not make is not touched.
mkdir -p "$out/first/old kit" "$out/mine"
printf 'old' > "$out/first/Old Kit.sfz"; printf 'old' > "$out/first/old kit/x.flac"; printf 'mine' > "$out/mine/keep.sfz"
"$root/install.sh" --yes --sets first --dir "$out" > "$work/log" || fail "run over an older version failed"
[ ! -e "$out/first/Old Kit.sfz" ] || fail "a file of an older version was kept"
[ ! -e "$out/first/old kit" ] || fail "a folder of an older version was kept"
[ -e "$out/first/First Guitar.sfz" ] && [ -e "$out/first/samples/a.flac" ] || fail "a file of the set was removed"
[ "$(cat "$out/mine/keep.sfz")" = mine ] || fail "a file outside the sets was touched"
grep -q 'removed Old Kit.sfz' "$work/log" || fail "the removal was not said"

# The recommended instrument only, by default: the others are fetched on request.
[ ! -e "$out/first/Alt.sfz" ] || fail "an extra patch was installed without being asked for"
if grep -q '"patches"' "$out/first/oxiguitar-set.json"; then fail "patches named though none are installed"; fi
"$root/install.sh" --yes --patches all --sets first --dir "$out" > "$work/log" || fail "--patches all failed"
[ "$(cat "$out/first/Alt.sfz")" = "sfz alt" ] || fail "the extra patch is missing"
grep -q '"recommended": "First Guitar.sfz"' "$out/first/oxiguitar-set.json" || fail "recommended instrument not named"
grep -q '"Alt.sfz": "clean small"' "$out/first/oxiguitar-set.json" || fail "patch not named"
grep -q 'other patches' "$work/log" || fail "the patches were not shown before the download"
# Asked, per set that has others: a installs them all, anything else only the recommended.
rm -rf "$out/first"
printf 'a\ny\n' | "$root/install.sh" --sets first --dir "$out" > "$work/log" || fail "asked, a: failed"
[ -e "$out/first/Alt.sfz" ] || fail "answering a did not install the extra patch"
rm -rf "$out/first"
printf '\ny\n' | "$root/install.sh" --sets first --dir "$out" > "$work/log" || fail "asked, enter: failed"
[ ! -e "$out/first/Alt.sfz" ] || fail "no answer installed the extra patch"
[ -f "$out/first/First Guitar.sfz" ] || fail "the recommended instrument is missing"
if "$root/install.sh" --yes --patches maybe --sets first --dir "$out" > /dev/null 2>&1; then fail "a wrong --patches was accepted"; fi

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
