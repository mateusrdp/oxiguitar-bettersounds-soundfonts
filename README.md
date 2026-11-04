# oxiguitar-bettersounds-soundfonts

Recommended free sound sets for [OxiGuitar](https://github.com/mateusrdp/oxiguitar),
and the installer that fetches them.

OxiGuitar plays a score with sound sets you choose (SoundFont or SFZ files).
This repository picks one good, free instrument for each job, so you do not
have to hunt for them. Each set is **one instrument** with no variations to
choose between: pick the set for a track and it sounds right.

## The sets

| Set | Sound | Size | Licence | By |
|---|---|---|---|---|
| `black-and-green-guitars` | Clean electric guitars, the green one with hammer-ons (plays by itself for clean guitars; 10 other programs, 519 MB more, with all patches) | 61 MB | CC0 1.0 | Karoryfer Samples (Black and Green Guitars, green hammer-on) |
| `clean-guitar` | Clean electric guitar (listed to pick; not played by itself) | 128 MB | CC0 1.0 | FreePats (Electric Guitar FSBS, clean) |
| `overdriven-guitar` | Overdriven electric guitar | 136 MB | CC0 1.0 | FreePats (Electric Guitar FSBS, dist2) |
| `distorted-guitar` | Distorted electric guitar | 313 MB | CC0 1.0 | FreePats (Electric Guitar FSBS, dist1) |
| `nylon-guitar` | Nylon-string (classical) guitar | 5 MB | CC0 1.0 | FreePats project (Spanish classical guitar) |
| `steel-guitar` | Steel-string acoustic guitar | 13 MB | GPL-3.0-or-later with exception | FreePats (FSS Steel String Guitar) |
| `ukulele` | Ukulele | 3 MB | CC0 1.0 | Mateusz Dąbrowski, for FreePats (Ukulele) |
| `bass` | Electric bass (plucked) | 471 MB | CC0 1.0 | Karoryfer Samples (Black and Blue Basses, plucked) |
| `drums` | Drum kit (the full DrumGizmo kit, stereo mix) | 347 MB | CC BY 4.0 | Lars Muldjord and the DrumGizmo team, SFZ by kinwie (MuldjordKit, stereo) |

Every set is credited, whatever its licence (see [Credits](#credits)). The
sets come from [FreePats](https://freepats.zenvoid.org/), a project of
freely licensed sound banks, the bass and the Black and Green Guitars from Karoryfer Samples, and the drum kit from DrumGizmo; their files
are fetched from the places listed in `sets.txt`.

## Install

**With the .deb or .rpm** (apt, dnf), installing the package installs the
sets, for every user: about 1.5 GB, downloaded from their authors and checked
against the checksums in `sets.txt`. On Debian and Ubuntu the package asks
first (the default answer is yes, so an unattended install downloads them);
answering no, or `echo 'oxiguitar-bettersounds-soundfonts oxiguitar-bettersounds-soundfonts/download boolean false' | sudo debconf-set-selections`
before installing, downloads nothing. With dnf, `OXIGUITAR_SKIP_SOUNDS=1`
in the environment of the install skips it. Removing the package removes the
sets it installed. A failed download does not fail the installation:
`sudo oxiguitar-install-sounds --system` tries again.

**By hand** (any system, and the only way on Windows and macOS): you need
`bash` and `curl` (Linux, macOS) or PowerShell (Windows). Download
this repository (green Code button, Download ZIP, or the zip of a release),
unpack it and run the installer from the unpacked folder.

Linux and macOS:

```sh
./install.sh --list          # what is on offer
./install.sh                 # asks which sets, then asks before downloading
./install.sh --sets bass,drums
./install.sh --yes           # every set, only the recommended patch of each
./install.sh --yes --patches all   # every set, every patch
```

Windows (PowerShell):

```powershell
.\install.ps1 -List
.\install.ps1
.\install.ps1 -Sets bass,drums
.\install.ps1 -Yes
.\install.ps1 -Yes -Patches all
```

If Windows refuses to run the script, run it with
`powershell -ExecutionPolicy Bypass -File .\install.ps1`.

Before anything is downloaded the installer shows, for each set, its size,
licence, author and the hosts the files come from, and waits for a yes.

### One patch or all of them

Some sets hold several instruments (patches): the clean guitar has 2 and the
bass 11 (about 650 MB more). By default you get the recommended one of each,
which is the one OxiGuitar plays. For a set with others the installer asks
`Install them all, or only the recommended one? [a/R]`; `--patches all`
(`-Patches all`) answers yes for every set and `--patches recommended` no,
and `--yes` alone means recommended. With all of them installed the MIDI
plugin lists each by a short name, such as `FreePats: Electric Guitar FSBS
(clean bridge small)`, so you can pick any for a track, and still plays the
recommended one when you pick nothing. Run the installer again to change your
mind.

### Where the sets go

| System | Folder |
|---|---|
| Linux | `~/.local/share/oxiguitar/soundfonts/` (or under `$XDG_DATA_HOME`) |
| macOS | `~/Library/Application Support/OxiGuitar/soundfonts/` |
| Windows | `%APPDATA%\OxiGuitar\soundfonts\` |
| For every user (Linux) | `./install.sh --system`, into `/usr/share/oxiguitar/soundfonts/` (run as root) |

`OXIGUITAR_HOME` moves OxiGuitar's whole data folder; the installer follows
it. `--dir DIR` (`-Dir DIR`) picks any other folder.

Each set gets its own folder holding the instrument, its samples, its
licence and an `oxiguitar-set.json` that tells OxiGuitar what it is (its
name, licence and credit, and the row it is made for). OxiGuitar uses
each set for its row by itself, from the next time it plays: the clean guitar
set for clean guitars, the bass for basses, and so on. To use another set for
a row, pick it in Tools, Plugins, MIDI (SoundFont, SFZ), Settings, which
always wins over the automatic one. (The nylon-string guitar and the ukulele share the Nylon-string guitars row, where the larger, the guitar, plays unless you pick the ukulele there; the steel-string guitar has the Steel-string guitars row. A track's Sound section picks another set for just that track.)

### Update, remove

Run the installer again: files already there and unchanged are skipped.
To remove sets: `./install.sh --uninstall --sets bass` (`-Uninstall -Sets
bass`). Only folders the installer made are removed.

## What it downloads, and how it is kept honest

- Nothing is downloaded until you say yes, and nothing is sent anywhere:
  the installer only reads. There is no telemetry.
- `sets.txt` lists every file with its address, size and SHA-256. The
  addresses are pinned to a commit of the source repository, so they do not
  change under you. A file that does not match its checksum is thrown away
  and the install stops.
- The steel-string guitar is published only as one archive on the FreePats
  site, so that set downloads the archive once, checks it, and takes only the
  listed files out of it.
- The instrument file is renamed (to `Clean Guitar.sfz`, say) so it reads
  well in OxiGuitar; nothing inside any file is edited.

## Credits

Every set is credited in its `oxiguitar-set.json`, in a `CREDITS.txt` the
installer writes next to the sets, and in the licence file kept with it.
The drum kit's licence (CC BY 4.0) asks for this credit wherever the sounds
are used in a published recording: **Drum samples provided by DrumGizmo.org**.

## For maintainers

`sets.in` says which instrument is in each set. `scripts/pin.sh` reads it,
finds the files each instrument plays in the source repository, downloads
them once to compute their checksums and writes `sets.txt`; commit both.
`scripts/check-sets.sh` checks they agree, and `tests/` runs both
installers against made-up sets without the network.

## Licence

The installer and scripts: GPL-3.0-or-later. See LICENSE. The sound sets
are not part of this repository; each keeps its own licence, listed above.
Contributions are welcome under the same terms; see
[CONTRIBUTING.md](CONTRIBUTING.md).
