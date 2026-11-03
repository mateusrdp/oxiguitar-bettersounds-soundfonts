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
| `clean-guitar` | Clean electric guitar | 128 MB | CC0 1.0 | FreePats (Electric Guitar FSBS, clean) |
| `overdriven-guitar` | Overdriven electric guitar | 136 MB | CC0 1.0 | FreePats (Electric Guitar FSBS, dist2) |
| `distorted-guitar` | Distorted electric guitar | 313 MB | CC0 1.0 | FreePats (Electric Guitar FSBS, dist1) |
| `nylon-guitar` | Nylon-string (classical) guitar | 5 MB | CC0 1.0 | FreePats project (Spanish classical guitar) |
| `ukulele` | Ukulele | 3 MB | CC0 1.0 | Mateusz Dąbrowski, for FreePats (Ukulele) |
| `bass` | Electric bass (fingered) | 3 MB | CC0 1.0 | Andrea Biasior, for FreePats (Finger Bass YR) |
| `drums` | Drum kit | 139 MB | CC BY 4.0 | Lars Muldjord (MuldjordKit, DrumGizmo), FreePats version |

Every set is credited, whatever its licence (see [Credits](#credits)). The
sets come from [FreePats](https://freepats.zenvoid.org/), a project of
freely licensed sound banks; their files are fetched from the repositories
linked in `sets.txt`.

There is no steel-string acoustic guitar yet: the best free one is only
published on the FreePats website, and adding it needs a download that this
repository can pin from a GitHub runner (planned).

## Install

You need `bash` and `curl` (Linux, macOS) or PowerShell (Windows). Download
this repository (green Code button, Download ZIP, or the zip of a release),
unpack it and run the installer from the unpacked folder.

Linux and macOS:

```sh
./install.sh --list          # what is on offer
./install.sh                 # asks which sets, then asks before downloading
./install.sh --sets bass,drums
./install.sh --yes           # every set, no questions
```

Windows (PowerShell):

```powershell
.\install.ps1 -List
.\install.ps1
.\install.ps1 -Sets bass,drums
.\install.ps1 -Yes
```

If Windows refuses to run the script, run it with
`powershell -ExecutionPolicy Bypass -File .\install.ps1`.

Before anything is downloaded the installer shows, for each set, its size,
licence, author and the hosts the files come from, and waits for a yes.

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
licence and an `oxiguitar-set.json` that tells OxiGuitar what it is. Open
OxiGuitar's settings, choose the MIDI/SFZ player and pick the set for each
kind of track; the installed sets are suggested for the tracks they fit.

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
