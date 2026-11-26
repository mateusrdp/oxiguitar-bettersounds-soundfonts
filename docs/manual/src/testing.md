# Testing

Every test of this repository runs with one command, on your own machine, and anyone can run it. When something fails, it tells you how to report it.

## Run everything

```sh
python3 scripts/test-all.py
```

On Windows, type `python` instead of `python3` if that's what you have.

You need:

- git, and Python 3.8 or newer (nothing to install with pip);
- for the sets list stage: `bash`.
- for the shell lint stage: `bash`, `shellcheck`.
- for the install.sh stage: `bash`, `curl`.
- for the install.ps1 stage: `pwsh`.
- for the install.ps1 (Windows PowerShell 5.1) stage: `powershell`.
- for the .deb stage: `bash`, `dpkg-deb`.
- for the .rpm stage: `bash`, `rpmbuild`, `rpm`.

It runs:

1. `sets.txt` checked against `sets.in` (`scripts/check-sets.sh`);
1. shellcheck on every shell script;
1. `install.sh` against two made-up sets served from local files, with no network (`tests/test-install.sh`);
1. `install.ps1` the same way, in PowerShell 7 (`tests/test-install.ps1`; needs `pwsh`);
1. on Windows, `install.ps1` in Windows PowerShell 5.1 too;
1. on Linux, the `.deb` built and checked without installing it (`tests/test-packages.sh deb`; lintian too where it is installed);
1. on Linux, the `.rpm` built and checked without installing it (`tests/test-packages.sh rpm`; needs rpmbuild);
1. a check of the [Features](features.md) page: every feature names a test, and every test it names exists.

It tests the system and processor it runs on, and only those (as Rust sees them: `rustc -vV`'s host). Tests for other systems are left out and the summary says so; they are not failures.

The stages that build packages need `dpkg-deb` (the `.deb`) and `rpmbuild` and `rpm` (the `.rpm`); lintian is used when it is installed. They build each package into a temporary folder and look inside it, and never install it: the Release workflow installs and removes them on its own runners. PowerShell 7 (`pwsh`) runs `install.ps1` on any system, and Windows PowerShell 5.1 too on Windows.

## What you get

A line per stage while it runs, then the result. In `target/test-all/<date>-<time>/`:

- `summary.md`: the result, your system, what failed and why, short enough to paste into a GitHub issue;
- `test-all.log`: everything that happened, every command and its output;

The script exits with 0 when everything passed, 1 when something failed, and 2 when it couldn't start.

## When something fails

1. Update to the newest `develop` (`git checkout develop && git pull`) and run it again: it may be fixed already.
2. Look for an issue about the same test at [github.com/mateusrdp/oxiguitar-bettersounds-soundfonts/issues](https://github.com/mateusrdp/oxiguitar-bettersounds-soundfonts/issues).
3. Otherwise [open one](https://github.com/mateusrdp/oxiguitar-bettersounds-soundfonts/issues/new): call it `test-all: <the first failing test>`, paste the whole `summary.md`, and attach `test-all.log` (drag it onto the text box; zip it first if it's over 25 MB). Read the log first: it has your folder names, so change anything you'd rather keep private.
4. You can also give `summary.md` and `test-all.log` to a language model along with this repository and ask it to find the cause.

## Options

- `--release`: an optimised test build: slower to build, faster corpus tests.
- `--ignore-rust-version`: for a Rust older than `rust-version` (unsupported, but handy).
- `--out DIR`: where the results go.

## Adding a feature

A new feature comes with its tests and a row on the [Features](features.md) page, in the same pull request; a new corpus test uses `tests/support/corpus.rs`. The script fails until the row names tests that exist.
