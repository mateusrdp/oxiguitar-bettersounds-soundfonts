#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Builds oxiguitar-bettersounds-soundfonts_VERSION_all.deb: the installer,
# its list of sets, the command oxiguitar-install-sounds, and a debconf
# question that asks, at priority high (so apt shows it), whether to
# download the sets to /usr/share/oxiguitar/soundfonts as the package is
# installed. Yes is the default, as installing this package is asking for the
# sets: an unattended install downloads them all, and a preseeded "false"
# (or answering no) downloads nothing. A failed download only warns; purging
# the package removes the sets it installed. Needs dpkg-deb.
#
# Usage: scripts/package/deb.sh VERSION OUT-DIR
set -euo pipefail
trap 'echo "::error::deb.sh line $LINENO: $BASH_COMMAND"' ERR
# shellcheck source=scripts/package/common.sh
. "$(dirname "$0")/common.sh"

version="${1:?usage: deb.sh VERSION OUT-DIR}"
out_dir="${2:?}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
tree="$work/$package"
mkdir -p "$tree/DEBIAN" "$tree/usr/share/doc/$package" "$out_dir"
files_into "$tree"

cat > "$tree/usr/share/doc/$package/copyright" <<COPYRIGHT
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $package
Source: https://github.com/mateusrdp/oxiguitar-bettersounds-soundfonts

Files: *
Copyright: 2026 Mateus Rocha de Paula and the OxiGuitar contributors
License: GPL-3+
 The licence's full text is in /usr/share/common-licenses/GPL-3. The sound
 sets are not part of this package; each keeps its own licence, listed in
 ${share}/sets.txt and in CREDITS.txt next to the sets once downloaded.
COPYRIGHT
{
    echo "$package ($version) unstable; urgency=medium"
    echo
    echo "  * See CHANGELOG.md in the source repository for what changed."
    echo
    echo " -- Mateus Rocha de Paula <mateusrdp@users.noreply.github.com>  $(date -R)"
} | gzip -9n -c > "$tree/usr/share/doc/$package/changelog.gz"
chmod 644 "$tree/usr/share/doc/$package/"*

install -d -m755 "$tree/usr/share/man/man1"
gzip -9n -c "$repo/scripts/package/oxiguitar-install-sounds.1" > "$tree/usr/share/man/man1/oxiguitar-install-sounds.1.gz"
chmod 644 "$tree/usr/share/man/man1/oxiguitar-install-sounds.1.gz"

cat > "$tree/DEBIAN/control" <<CONTROL
Package: $package
Version: $version
Section: sound
Priority: optional
Architecture: all
Installed-Size: $(($(du -sk "$tree/usr" | cut -f1)))
Maintainer: Mateus Rocha de Paula <mateusrdp@users.noreply.github.com>
Homepage: https://github.com/mateusrdp/oxiguitar-bettersounds-soundfonts
Depends: curl | wget, xz-utils, debconf | debconf-2.0
Recommends: oxiguitar-midi
Description: $summary
$(printf '%s\n' "$description" | fold -s -w 78 | sed -e 's/ *$//' -e 's/^/ /')
CONTROL

cat > "$tree/DEBIAN/templates" <<'TEMPLATES'
Template: oxiguitar-bettersounds-soundfonts/download
Type: boolean
Default: true
Description: Download OxiGuitar's recommended sound sets now?
 The sound sets are large (about 1.5 GB in all) and are downloaded from their
 authors, not from this package; each file is checked against a pinned
 checksum. They are installed for every user, and OxiGuitar plays with
 them as soon as they are there. If you say no, run
 "oxiguitar-install-sounds --system" later, or "oxiguitar-install-sounds"
 as yourself for your own account.

Template: oxiguitar-bettersounds-soundfonts/sets
Type: string
Default: all
Description: Sound sets to download (names separated by commas, or "all"):
 Run "oxiguitar-install-sounds --list"
 for the names, sizes and licences.
TEMPLATES

cat > "$tree/DEBIAN/config" <<'CONFIG'
#!/bin/sh
set -e
. /usr/share/debconf/confmodule
db_input high oxiguitar-bettersounds-soundfonts/download || true
db_go || true
db_get oxiguitar-bettersounds-soundfonts/download
if [ "$RET" = true ]; then
    db_input high oxiguitar-bettersounds-soundfonts/sets || true
    db_go || true
fi
CONFIG

cat > "$tree/DEBIAN/postinst" <<POSTINST
#!/bin/sh
set -e
. /usr/share/debconf/confmodule
if [ "\$1" = configure ]; then
    db_get oxiguitar-bettersounds-soundfonts/download
    if [ "\$RET" = true ]; then
        db_get oxiguitar-bettersounds-soundfonts/sets
        sets="\${RET:-all}"
        # A failed download is not a failed installation: say how to retry.
        if ! $share/install.sh --yes --system --sets "\$sets"; then
            echo "oxiguitar-bettersounds-soundfonts: the sound sets could not be downloaded." >&2
            echo "Run 'oxiguitar-install-sounds --system' to try again." >&2
        fi
    fi
fi
db_stop || true
exit 0
POSTINST

set_ids="$(awk -F'|' '$1 == "set" { print $2 }' "$repo/sets.txt" | tr '\n' ' ')"
cat > "$tree/DEBIAN/postrm" <<POSTRM
#!/bin/sh
set -e
if [ "\$1" = purge ]; then
    dir=/usr/share/oxiguitar/soundfonts
    # Only the folders the installer made (they hold oxiguitar-set.json).
    # The sets this version knows (sets.txt is already gone when purging).
    for id in $set_ids; do
        if [ -f "\$dir/\$id/oxiguitar-set.json" ]; then rm -rf "\${dir:?}/\$id"; fi
    done
    rm -f "\$dir/CREDITS.txt"
    rmdir "\$dir" 2>/dev/null || true
    if [ -e /usr/share/debconf/confmodule ]; then
        . /usr/share/debconf/confmodule
        db_purge || true
    fi
fi
exit 0
POSTRM
chmod 755 "$tree/DEBIAN/config" "$tree/DEBIAN/postinst" "$tree/DEBIAN/postrm"
chmod 644 "$tree/DEBIAN/templates"

out="$out_dir/${package}_${version}_all.deb"
dpkg-deb --root-owner-group -Zxz --build "$tree" "$out"
dpkg-deb --info "$out"
dpkg-deb --contents "$out"
echo "$out"
