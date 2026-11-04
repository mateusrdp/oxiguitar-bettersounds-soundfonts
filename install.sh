#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Mateus Rocha de Paula and the OxiGuitar contributors
#
# Installs OxiGuitar's recommended sound sets (see README.md). Works with the
# bash that ships with macOS (3.2). Nothing is downloaded before you have
# seen what and from where and said yes; every file is checked against the
# SHA-256 in sets.txt and a file that does not match is thrown away.
set -eu

here="$(cd "$(dirname "$0")" && pwd)"
sets_file="${OXIGUITAR_SETS_FILE:-$here/sets.txt}"

usage() {
    cat <<'TXT'
Usage: install.sh [options]

  --list           show the sound sets and exit
  --sets A,B,...   install these sets (or "all"); without it, you are asked
  --dir DIR        install into DIR (default: your OxiGuitar soundfonts folder)
  --system         install for every user, into /usr/share/oxiguitar/soundfonts
  --yes            do not ask for confirmation (installs all sets unless --sets)
  --uninstall      remove the named sets instead (needs --sets)
  --help           this text
TXT
}

die() { echo "install.sh: $*" >&2; exit 1; }

list=0 want="" dir="" system=0 yes=0 remove=0
while [ $# -gt 0 ]; do
    case "$1" in
        --list) list=1 ;;
        --sets) [ $# -ge 2 ] || die "--sets needs a value"; want="$2"; shift ;;
        --dir) [ $# -ge 2 ] || die "--dir needs a value"; dir="$2"; shift ;;
        --system) system=1 ;;
        --yes|-y) yes=1 ;;
        --uninstall) remove=1 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; die "unknown option: $1" ;;
    esac
    shift
done

[ -f "$sets_file" ] || die "cannot find $sets_file"

field() { awk -F'|' -v id="$1" -v n="$2" '$1 == "set" && $2 == id { print $n }' "$sets_file"; }
all_ids() { awk -F'|' '$1 == "set" { print $2 }' "$sets_file"; }
hosts() {
    awk -F'|' -v id="$1" '$1 == "file" && $2 == id { print $5 }' "$sets_file" |
        sed -e 's#^[a-z]*://##' -e 's#/.*##' | sort -u | tr '\n' ' ' | sed 's/ $//'
}
mb() { awk -v b="$1" 'BEGIN { printf "%.1f MB", b / 1000000 }'; }

if [ "$list" = 1 ]; then
    printf '%-18s %-10s %-12s %s\n' "SET" "SIZE" "LICENCE" "CREDIT"
    for id in $(all_ids); do
        printf '%-18s %-10s %-12s %s\n' "$id" "$(mb "$(field "$id" 9)")" "$(field "$id" 5)" "$(field "$id" 6)"
    done
    exit 0
fi

if [ -z "$dir" ]; then
    if [ "$system" = 1 ]; then
        dir="/usr/share/oxiguitar/soundfonts"
    elif [ -n "${OXIGUITAR_HOME:-}" ]; then
        dir="$OXIGUITAR_HOME/soundfonts"
    elif [ "$(uname -s)" = Darwin ]; then
        dir="$HOME/Library/Application Support/OxiGuitar/soundfonts"
    else
        dir="${XDG_DATA_HOME:-$HOME/.local/share}/oxiguitar/soundfonts"
    fi
fi

# Which sets.
if [ -z "$want" ]; then
    if [ "$yes" = 1 ]; then
        want=all
    elif [ "$remove" = 1 ]; then
        die "say which sets to remove with --sets (see --list)"
    else
        echo "OxiGuitar sound sets:"
        echo
        for id in $(all_ids); do
            printf '  %-18s %-10s %s\n' "$id" "$(mb "$(field "$id" 9)")" "$(field "$id" 5)"
        done
        echo
        printf 'Which sets? Names separated by commas, or "all" [all]: '
        read -r want || want=""
        [ -n "$want" ] || want=all
    fi
fi
if [ "$want" = all ]; then
    chosen="$(all_ids)"
else
    chosen=""
    oldifs="$IFS"; IFS=','
    for id in $want; do
        id="$(echo "$id" | tr -d ' ')"
        [ -n "$(field "$id" 2)" ] || { IFS="$oldifs"; die "no such set: $id (see --list)"; }
        chosen="$chosen
$id"
    done
    IFS="$oldifs"
fi

confirm() {
    [ "$yes" = 1 ] && return 0
    printf '%s [y/N] ' "$1"
    read -r answer || answer=""
    case "$answer" in y|Y|yes|YES|Yes) return 0 ;; *) return 1 ;; esac
}

if [ "$remove" = 1 ]; then
    echo "This removes, from $dir:"
    for id in $chosen; do echo "  $id"; done
    confirm "Remove them?" || { echo "Nothing removed."; exit 0; }
    for id in $chosen; do
        # Only a folder this installer made (it holds oxiguitar-set.json).
        if [ -f "$dir/$id/oxiguitar-set.json" ]; then rm -rf "${dir:?}/$id"; echo "removed $id"; else echo "$id: not installed"; fi
    done
    exit 0
fi

# What will happen, before anything does.
total=0
echo "These sets will be installed into:"
echo "  $dir"
echo
for id in $chosen; do
    size="$(field "$id" 9)"
    total=$((total + size))
    echo "  $id: $(mb "$size"), $(field "$id" 5), $(field "$id" 6)"
    echo "      from $(hosts "$id")"
    notice="$(field "$id" 10)"
    [ -z "$notice" ] || echo "      the licence asks for this credit: $notice"
done
echo
echo "Total download: $(mb "$total") at most (files already here are not fetched again)."
confirm "Download and install?" || { echo "Nothing downloaded."; exit 0; }

if command -v sha256sum >/dev/null 2>&1; then
    sha256() { sha256sum "$1" | awk '{ print $1 }'; }
elif command -v shasum >/dev/null 2>&1; then
    sha256() { shasum -a 256 "$1" | awk '{ print $1 }'; }
elif command -v openssl >/dev/null 2>&1; then
    sha256() { openssl dgst -sha256 "$1" | awk '{ print $NF }'; }
else
    die "need sha256sum, shasum or openssl to check the downloads"
fi

fetch() { # URL FILE
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 3 --connect-timeout 20 -o "$2" "$1" </dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q -t 3 -O "$2" "$1" </dev/null
    else
        die "need curl or wget"
    fi
}

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

mkdir -p "$dir"
for id in $chosen; do
    set_dir="$dir/$id"
    echo "== $id"
    n=0
    count="$(field "$id" 8)"
    # The file lines of this set, read from a copy so the loop can fetch.
    list_file="$dir/.oxiguitar-files.$$"
    awk -F'|' -v id="$id" '$1 == "file" && $2 == id' "$sets_file" > "$list_file"
    pending="$dir/.oxiguitar-pending.$$"
    : > "$pending"
    # shellcheck disable=SC2094,SC2034
    while IFS='|' read -r _ _ sum size url rel; do
        n=$((n + 1))
        target="$set_dir/$rel"
        mkdir -p "$(dirname "$target")"
        if [ -f "$target" ] && [ "$(sha256 "$target")" = "$sum" ]; then
            continue
        fi
        case "$url" in
            archive:*) printf '%s|%s|%s\n' "${url#archive:}" "$sum" "$rel" >> "$pending"; continue ;;
        esac
        part="$target.part"
        printf '\r  %d/%d' "$n" "$count"
        fetch "$url" "$part" || { rm -f "$part" "$list_file"; die "could not download $url"; }
        if [ "$(sha256 "$part")" != "$sum" ]; then
            rm -f "$part" "$list_file"
            die "$rel does not match the checksum in sets.txt; it was thrown away. Nothing from it is installed."
        fi
        mv "$part" "$target"
    done < "$list_file"
    rm -f "$list_file"
    # A set that is one archive: fetched once, and only the files listed for
    # it are taken out of it, each checked on its own.
    if [ -s "$pending" ]; then
        read -r _ _ asum _ aurl < <(awk -F'|' -v id="$id" '$1 == "archive" && $2 == id' "$sets_file" | tr '|' ' ') || true
        [ -n "${aurl:-}" ] || { rm -f "$pending"; die "$id: sets.txt has no archive for it"; }
        arc="$dir/.oxiguitar-archive.$$"
        unpack="$dir/.oxiguitar-unpack.$$"
        printf '\r  downloading the archive'
        fetch "$aurl" "$arc" || { rm -rf "$arc" "$pending"; die "could not download $aurl"; }
        if [ "$(sha256 "$arc")" != "$asum" ]; then
            rm -rf "$arc" "$pending"
            die "the archive for $id does not match the checksum in sets.txt; it was thrown away."
        fi
        rm -rf "$unpack"; mkdir -p "$unpack"
        tar -xf "$arc" -C "$unpack" || { rm -rf "$arc" "$unpack" "$pending"; die "could not unpack the archive for $id (tar needs xz support)"; }
        # shellcheck disable=SC2094
        while IFS='|' read -r inner sum rel; do
            [ -f "$unpack/$inner" ] || { rm -rf "$arc" "$unpack" "$pending"; die "$inner is missing from the archive"; }
            if [ "$(sha256 "$unpack/$inner")" != "$sum" ]; then
                rm -rf "$arc" "$unpack" "$pending"
                die "$rel does not match the checksum in sets.txt; it was thrown away."
            fi
            mkdir -p "$(dirname "$set_dir/$rel")"
            mv "$unpack/$inner" "$set_dir/$rel"
        done < "$pending"
        rm -rf "$arc" "$unpack"
    fi
    rm -f "$pending"
    echo
    role="$(field "$id" 4)"
    {
        printf '{\n  "name": "%s",\n  "role": "%s",\n  "licence": "%s",\n  "credit": "%s",\n  "source": "%s"\n}\n' \
            "$(json_escape "$(field "$id" 3)")" "$role" "$(json_escape "$(field "$id" 5)")" \
            "$(json_escape "$(field "$id" 6)")" "$(json_escape "$(field "$id" 7)")"
    } > "$set_dir/oxiguitar-set.json"
done

# CREDITS.txt lists every set installed here, whatever its licence.
credits="$dir/CREDITS.txt"
{
    echo "OxiGuitar sound sets installed here"
    echo
    for id in $(all_ids); do
        [ -f "$dir/$id/oxiguitar-set.json" ] || continue
        echo "$id"
        echo "  by:      $(field "$id" 6)"
        echo "  licence: $(field "$id" 5)"
        echo "  source:  $(field "$id" 7)"
        notice="$(field "$id" 10)"
        [ -z "$notice" ] || echo "  credit:  $notice"
        echo
    done
} > "$credits"

echo
echo "Done. Open OxiGuitar's settings to pick the sets for your tracks."
echo "Credits are in $credits"
