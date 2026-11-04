# Changelog

All notable changes. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.1] - 2026-11-04

### Added

- The sound sets (clean, overdriven and distorted electric guitar, nylon and steel-string guitar, ukulele, bass, drums) and the installers `install.sh` and `install.ps1`.
- The electric guitar sets say which row of the MIDI plugin's settings window they are for: `clean-guitar` the role `clean-guitars`, `overdriven-guitar` `overdriven-guitars`, `distorted-guitar` `distorted-guitars`, in `oxiguitar-set.json` (mateusrdp/oxiguitar#152; the MIDI plugin before its three electric rows read `electric-guitars`).
- `oxiguitar-bettersounds-soundfonts` as a `.deb` and an `.rpm` (the same file for every architecture), which add the command `oxiguitar-install-sounds`.
