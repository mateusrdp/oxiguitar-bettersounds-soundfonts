#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Builds oxiguitar-bettersounds-soundfonts-VERSION-1.noarch.rpm: the
# installer, its list of sets and the command oxiguitar-install-sounds. An
# RPM cannot ask questions, so nothing is downloaded on installation: it
# says to run the command. Needs rpmbuild.
#
# Usage: scripts/package/rpm.sh VERSION OUT-DIR
set -euo pipefail
trap 'echo "::error::rpm.sh line $LINENO: $BASH_COMMAND"' ERR
# shellcheck source=scripts/package/common.sh
. "$(dirname "$0")/common.sh"

version="${1:?usage: rpm.sh VERSION OUT-DIR}"
out_dir="${2:?}"
rpm_version="${version//-/~}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
top="$work/rpmbuild"
mkdir -p "$top"/{BUILD,RPMS,SOURCES,SPECS,SRPMS} "$out_dir"
files_into "$top/SOURCES/root"

cat > "$top/SPECS/$package.spec" <<SPEC
Name: $package
Version: $rpm_version
Release: 1
Summary: $summary
License: GPL-3.0-or-later
URL: https://github.com/mateusrdp/oxiguitar-bettersounds-soundfonts
BuildArch: noarch
Requires: bash, tar, xz, (curl or wget)
Recommends: oxiguitar-midi

%description
$description

%global debug_package %{nil}

%install
cp -a %{_sourcedir}/root/. %{buildroot}/

%post
# Installing this package is asking for the sets: they are downloaded for
# every user now. OXIGUITAR_SKIP_SOUNDS=1 in the environment of the install
# skips that; OXIGUITAR_PATCHES=all installs every patch of each set, not only
# the recommended one. A failed download is not a failed installation.
if [ -n "\${OXIGUITAR_SKIP_SOUNDS:-}" ]; then
    echo "OxiGuitar sound sets not downloaded; run 'sudo oxiguitar-install-sounds --system' to get them."
elif ! $share/install.sh --yes --system --patches "\${OXIGUITAR_PATCHES:-recommended}"; then
    echo "OxiGuitar sound sets could not be downloaded." >&2
    echo "Run 'sudo oxiguitar-install-sounds --system' to try again." >&2
fi
exit 0

%preun
# Removing the package (not upgrading it) removes the sets it installed:
# only the folders the installer made (they hold oxiguitar-set.json).
if [ "\$1" = 0 ]; then
    dir=/usr/share/oxiguitar/soundfonts
    for id in \$(awk -F'|' '\$1 == "set" { print \$2 }' $share/sets.txt); do
        if [ -f "\$dir/\$id/oxiguitar-set.json" ]; then rm -rf "\${dir:?}/\$id"; fi
    done
    rm -f "\$dir/CREDITS.txt"
    rmdir "\$dir" 2>/dev/null || true
fi
exit 0

%files
$share/install.sh
$share/sets.txt
/usr/bin/oxiguitar-install-sounds
SPEC

rpmbuild -bb --target noarch \
    --define "_topdir $top" \
    --define "_rpmdir $out_dir" \
    --define "_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm" \
    "$top/SPECS/$package.spec"
out="$out_dir/$package-$rpm_version-1.noarch.rpm"
rpm -qpi "$out"
rpm -qpl "$out"
echo "$out"
