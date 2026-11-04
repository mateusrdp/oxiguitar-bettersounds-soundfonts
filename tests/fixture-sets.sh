#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Makes a sets.txt in DIR with one tiny set, `drums`, served from a local
# file, so the packages can be tested installing sets without the network or
# 1.2 GB. Use it with OXIGUITAR_SETS_FILE=DIR/sets.txt.
#
# Usage: tests/fixture-sets.sh DIR
set -eu
dir="${1:?usage: fixture-sets.sh DIR}"
mkdir -p "$dir/src"
printf 'sfz kit' > "$dir/src/kit.sfz"
sum="$(sha256sum "$dir/src/kit.sfz" | awk '{print $1}')"
size="$(wc -c < "$dir/src/kit.sfz" | tr -d ' ')"
{
    echo "set|drums|Test|drums|CC0 1.0|Nobody|https://example.org/drums|1|0|"
    echo "file|drums|$sum|$size|file://$(cd "$dir/src" && pwd)/kit.sfz|Kit.sfz"
} > "$dir/sets.txt"
