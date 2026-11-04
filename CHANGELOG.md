# Changelog

All notable changes. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
