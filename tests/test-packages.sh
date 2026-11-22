#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Builds the .deb or the .rpm as the Release workflow does and checks it
# without installing it (the workflow installs and removes it on its runner;
# this runs on your machine): the .deb lints clean where lintian is
# installed, asks its question at priority high with yes as the default,
# and installs the sets after configuring; the .rpm runs the installer
# after installing unless OXIGUITAR_SKIP_SOUNDS is set, and removes the
# sets with the package. scripts/test-all.py runs it as two stages.
#
# Usage: tests/test-packages.sh deb|rpm
# Needs dpkg-deb (the .deb) or rpmbuild and rpm (the .rpm).
set -euo pipefail
cd "$(dirname "$0")/.."
kind="${1:?deb or rpm}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
version="$(cat VERSION)"
fail() { echo "FAIL: $*" >&2; exit 1; }
case "$kind" in
deb)
    scripts/package/deb.sh "$version" "$work" > "$work/build.log" 2>&1 || { cat "$work/build.log"; fail "the .deb didn't build"; }
    deb=("$work"/*.deb)
    [[ -f "${deb[0]}" ]] || fail "no .deb was built"
    if command -v lintian > /dev/null; then
        lintian --fail-on error --tag-display-limit 0 "${deb[0]}"
    else
        echo "lintian isn't installed: the .deb is not linted"
    fi
    dpkg-deb -e "${deb[0]}" "$work/control"
    grep -q 'db_input high oxiguitar-bettersounds-soundfonts/download' "$work/control/config" ||
        fail "the .deb doesn't ask at priority high"
    grep -q '^Default: true' "$work/control/templates" || fail "the .deb's default isn't yes"
    grep -q 'oxiguitar-install-sounds' "$work/control/postinst" || fail "the .deb doesn't install the sets"
    files="$(dpkg-deb -c "${deb[0]}")"
    grep -q 'usr/bin/oxiguitar-install-sounds' <<< "$files" || fail "no oxiguitar-install-sounds"
    echo "the .deb: ok"
    ;;
rpm)
    # A pre-release version too, which the .rpm spells with a tilde.
    version="$version-rc.1"
    scripts/package/rpm.sh "$version" "$work" > "$work/build.log" 2>&1 || { cat "$work/build.log"; fail "the .rpm didn't build"; }
    rpm=("$work"/*.rpm)
    [[ -f "${rpm[0]}" ]] || fail "no .rpm was built"
    [[ "$(basename "${rpm[0]}")" == "oxiguitar-bettersounds-soundfonts-${version//-/\~}-1.noarch.rpm" ]] ||
        fail "the .rpm is called $(basename "${rpm[0]}")"
    scripts="$(rpm -qp --scripts "${rpm[0]}")"
    grep -q 'OXIGUITAR_SKIP_SOUNDS' <<< "$scripts" || fail "the .rpm can't skip the download"
    grep -q 'oxiguitar-install-sounds' <<< "$scripts" || fail "the .rpm doesn't install the sets"
    files="$(rpm -qpl "${rpm[0]}")"
    grep -q '/usr/bin/oxiguitar-install-sounds' <<< "$files" || fail "no oxiguitar-install-sounds"
    echo "the .rpm: ok"
    ;;
*) fail "deb or rpm, not $kind" ;;
esac
