# shellcheck shell=bash disable=SC2034
# Sourced by deb.sh and rpm.sh: puts the package's files into a tree.
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
package="oxiguitar-bettersounds-soundfonts"
share="/usr/share/oxiguitar-bettersounds"
summary="Recommended free sound sets for OxiGuitar, and their installer"
description="Installs OxiGuitar's recommended sound sets (clean, overdriven and distorted electric guitar, nylon and steel-string guitar, ukulele, bass and drums) into the system's sound folder. The sets are downloaded from their authors, checked against pinned checksums, and are not part of this package. Run oxiguitar-install-sounds to choose which ones."

# files_into TREE: the program, the list of sets and the command.
files_into() {
    local tree="$1"
    install -d -m755 "$tree$share" "$tree/usr/bin"
    install -m755 "$repo/install.sh" "$tree$share/install.sh"
    install -m644 "$repo/sets.txt" "$tree$share/sets.txt"
    printf '#!/bin/sh\nexec %s/install.sh "$@"\n' "$share" > "$tree/usr/bin/oxiguitar-install-sounds"
    chmod 755 "$tree/usr/bin/oxiguitar-install-sounds"
}
