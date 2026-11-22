# Features and their tests

Every feature of this repository and the tests that check it. This repository
has no Rust code yet: its tests are the stages of `tests/suite.json`, named
here as `stage:NAME`. `python3 scripts/test-all.py` runs every stage your
system can run and checks that each row names a stage that exists. A new
feature comes with its tests and a row here, in the same pull request.

## The sets

| Feature | Tests |
| --- | --- |
| `sets.txt` lists every set of `sets.in`, each file pinned to a commit, with a well-formed checksum, sizes that add up, one `.sfz`, a licence and nothing outside its folder | `stage:sets list` |

## The installer

| Feature | Tests |
| --- | --- |
| Lists the sets on offer (`--list`, `-List`) | `stage:install.sh`, `stage:install.ps1` |
| Asks before downloading; without a yes nothing is downloaded | `stage:install.sh`, `stage:install.ps1` |
| Installs the chosen sets (`--sets`, `-Sets`) and refuses an unknown set | `stage:install.sh`, `stage:install.ps1` |
| Checks every download against its checksum, and leaves nothing behind when one doesn't match | `stage:install.sh`, `stage:install.ps1` |
| Running it again changes nothing; a missing or cut-short file comes back; what is already there is recognised with every address dead | `stage:install.sh`, `stage:install.ps1` |
| Removes what an older version of a set left, and never a folder it didn't make | `stage:install.sh`, `stage:install.ps1` |
| The recommended patch by default, every patch on request (`--patches all`) or when asked | `stage:install.sh`, `stage:install.ps1` |
| What it makes can be read by everyone, whatever the umask | `stage:install.sh` |
| One download at a time works the same | `stage:install.sh` |
| OxiGuitar's Flatpak gets the sets in its own folder | `stage:install.sh` |
| Removes a set it installed (`--uninstall`) | `stage:install.sh`, `stage:install.ps1` |
| Runs in Windows PowerShell 5.1 as well as PowerShell 7 | `windows:stage:install.ps1 (Windows PowerShell 5.1)` |
| Every shell script passes shellcheck | `stage:shell lint` |

## The Linux packages

| Feature | Tests |
| --- | --- |
| The `.deb` lints clean, asks at priority high with yes as the default, installs the sets after configuring and ships `oxiguitar-install-sounds` | `linux:stage:.deb` |
| The `.rpm` installs the sets unless `OXIGUITAR_SKIP_SOUNDS` is set, removes them with the package and ships `oxiguitar-install-sounds` | `linux:stage:.rpm` |
