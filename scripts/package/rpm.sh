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
echo "OxiGuitar sound sets are not installed yet."
echo "Run 'oxiguitar-install-sounds' to choose and download them for your account,"
echo "or 'sudo oxiguitar-install-sounds --system' for every user."

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
