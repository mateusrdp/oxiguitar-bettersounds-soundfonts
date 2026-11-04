# Changelog

All notable changes. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.2] - 2026-11-04

### Fixed

- **The installed sets could be read by root only**, so OxiGuitar listed none of the new drums (and any set installed or updated by 0.2.0 or 0.2.1 whose folders were new). `curl --create-dirs` makes folders for its own user alone (mode 750), and the `.deb` installs as root. The installer now makes the folders itself, and finishes each set with `chmod -R a+rX`, which also repairs folders an earlier version left closed: install again (`apt upgrade` does) and they open. A test runs the installer under `umask 077`.

## [0.2.1] - 2026-11-04

### Fixed

- **0.2.0 downloaded everything again, then stopped with "does not match the checksum" on systems whose language is not English.** The installer read the words `OK` and `FAILED` from `sha256sum -c`, which coreutils translates in some languages, so it found no file right (it re-fetched all of them, which showed as `145/137`) and then no download right either. It now reads only the sums (never the words) from `sha256sum`/`shasum`, and the progress count no longer includes its own temporary files.

## [0.2.0] - 2026-11-04

### Changed

- **The installers are much faster.** Starting a program for each of the 8,750 files (a download, a checksum, a move) took far longer than the download itself. Now what is already here is checked in one pass, what is missing is fetched by 8 downloads at once (`OXIGUITAR_JOBS` changes the number), each fetching many files over one connection, and what came is checked in one pass again. A rerun with everything in place takes a second or so instead of minutes, and a file missing or cut short is fetched again alone. Without `curl`, `install.sh` still goes one file at a time. `install.ps1` does the same with 8 workers and checks files in its own process.

### Fixed

- **A set's older files are removed when it is installed again.** The drum kit changed from FreePats' to DrumGizmo's and both stayed in `drums/`, so the list showed two kits. The installers now remove, from a folder they made (it holds `oxiguitar-set.json`), every file that is not part of this version of the set, and the folders left empty. Folders they did not make are not touched, and the patches you chose to leave out are not "older files": they stay listed in `sets.txt` and are kept.

## [0.1.5] - 2026-11-04

### Added

- **Black and Green Guitars** (Karoryfer Samples, CC0): `black-and-green-guitars` for the clean guitars row, with the green guitar's hammer-on program (`06-green_hammer-on`) as the one that plays by itself; the other ten programs (keyswitched, twang, staccato, the black Hofner and the combination) come with "all patches". The FreePats clean guitar stays installed, to pick, with the role `none` (it is not played by itself, so the choice for the row is not left to chance).

### Changed

- **The drum kit is the full DrumGizmo MuldjordKit** (stereo mix of every microphone, 347 MB, sfzinstruments/DrumGizmo.MuldjordKit), not FreePats' reduced version (139 MB), which had far fewer sounds. It is listed as `DrumGizmo: MuldjordKit (stereo)`.
- The installers' download is about 1.5 GB in all.
- `scripts/pin.sh` reads an instrument as a player does: `#include` files are placed where they stand, `#define $name value` replaces `$name` after it, and several includes may share a line (the DrumGizmo kit needs all three). `none` is a role of `sets.in` for a set that is only to be picked.

## [0.1.4] - 2026-11-04

### Fixed

- **The `.deb` and `.rpm` never asked which patches to install** (only the installer run by hand did, so a package install always got the recommended ones). The `.deb` now asks, at priority high after the question about downloading, "recommended" or "all" (`dpkg-reconfigure oxiguitar-bettersounds-soundfonts` asks again, and purging then reinstalling does too); the `.rpm` installs every patch when `OXIGUITAR_PATCHES=all` is in the environment of the install.

## [0.1.3] - 2026-11-04

### Added

- Install every patch of a set, not only the recommended one: `install.sh --patches all|recommended`, `install.ps1 -Patches all|recommended`, and a question for each set that has others (the clean guitar has 2 patches, the bass 11). `oxiguitar-set.json` then names the `recommended` patch and gives every patch's short `patches` name, which the MIDI plugin shows. `sets.txt` gains `extra` and `patch` lines and a seventh `extra` field on file lines.

## [0.1.2] - 2026-11-04

### Changed

- **Installing the `.deb` or `.rpm` installs the sound sets.** The `.deb` asked whether to download them at a priority apt doesn't show, with no as the default, so it never downloaded anything; the `.rpm` only printed a hint. Now the `.deb` asks (at priority high) with yes as the default, so an unattended install downloads all of them, and the `.rpm` downloads them as it installs (`OXIGUITAR_SKIP_SOUNDS=1` skips it). Both install them for every user, and removing the package removes what it installed. A failed download only warns.
- The acoustic sets name the two new rows: `nylon-guitar` and `ukulele` the role `nylon-guitars`, `steel-guitar` `steel-guitars` (they said `acoustic-guitars`, one row for both). The MIDI plugin before its split of the row reads the new names as no role.
- OxiGuitar's MIDI plugin plays each set for the row its `oxiguitar-set.json` names without a pick (needs oxiguitar-midi after 0.2.0); the installer's closing message says so.

## [0.1.1] - 2026-11-04

### Added

- The sound sets (clean, overdriven and distorted electric guitar, nylon and steel-string guitar, ukulele, bass, drums) and the installers `install.sh` and `install.ps1`.
- The electric guitar sets say which row of the MIDI plugin's settings window they are for: `clean-guitar` the role `clean-guitars`, `overdriven-guitar` `overdriven-guitars`, `distorted-guitar` `distorted-guitars`, in `oxiguitar-set.json` (mateusrdp/oxiguitar#152; the MIDI plugin before its three electric rows read `electric-guitars`).
- `oxiguitar-bettersounds-soundfonts` as a `.deb` and an `.rpm` (the same file for every architecture), which add the command `oxiguitar-install-sounds`.
