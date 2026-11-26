# Changelog

## [0.2.4] - 2026-11-26

### Added

- **Every test with one command** (mateusrdp/oxiguitar#273): `scripts/test-all.py` builds and runs all of this repository's tests, with a progress bar, a summary to paste into an issue and a log to diagnose from. The manual has a Features page naming the tests of every feature (CI checks it) and a Testing page.
- `tests/test-packages.sh deb|rpm` builds the `.deb` or the `.rpm` and checks it without installing it; CI runs it on Linux for every pull request, not only at release.

### Fixed

- The `.rpm` of a version with a dash (such as `0.3.0-rc.1`) failed to build: bash 5.2 turned the `~` that replaces the dash into the home folder's path.

### Changed

- **CI outlasts a slow Ubuntu mirror**: it installs packages with `scripts/apt-install.sh`, the same file as in every OxiGuitar repository. apt is stopped only when its downloads have not grown for 2 minutes, then tried again on the next mirror; while they grow, it may take as long as it needs (24 Nov 2026: fixed 5-minute tries failed jobs on mirrors at 80 to 185 kB/s).
- **The manual explains the ideas behind the plugin** (its overview, with pictures), shows how to use it with screenshots, says in Architecture and strategy what it can't do yet, what is left out on purpose and where help is wanted, and has a Credits page listing every project it uses, with links and thanks. The README has a plain-words introduction and a Credits section.

## [0.2.3] - 2026-11-16

### Added

- **OxiGuitar's Flatpak** (#163): when the Flatpak is installed, `install.sh` also installs the sets into its own folder, `~/.var/app/io.github.mateusrdp.OxiGuitar/data/oxiguitar/soundfonts`, the only one the Flatpak can see (hard links where it can, so they take no more room), or only there when OxiGuitar isn't installed any other way; `--uninstall` removes them from both. `--dir`, `--system` and `OXIGUITAR_HOME` leave it out.

## [0.2.2] - 2026-11-04

