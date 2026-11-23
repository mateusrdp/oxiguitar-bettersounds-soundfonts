# Architecture and strategy

There is no program here, only two installer scripts and a list. `sets.in` says which instrument belongs to each set. `scripts/pin.sh` reads it, finds the files each instrument plays in the source repository, downloads them once to compute their checksums, and writes `sets.txt`. `sets.txt` lists every file with its address, size and SHA-256. Addresses are pinned to a commit of the source repository, so they don't change under you.

The strategy is to be honest and boring about downloading:

- Nothing is downloaded until you say yes, and nothing is sent anywhere. There is no telemetry.
- A file that doesn't match its checksum is thrown away and the install stops.
- The steel-string guitar is published only as one archive, so that set downloads the archive once, checks it, and takes only the listed files out of it.
- The instrument file is renamed, to `Clean Guitar.sfz` for example, so it reads well in OxiGuitar. Nothing inside any file is edited.

On Debian and Ubuntu, the package asks before downloading, and the default answer is yes, so an unattended install downloads the sets. On Fedora, the download happens in the package's post-install step. A failed download doesn't fail the installation.

## Current limitations

- **One instrument per job.** There is one set for each kind of track. There is no piano, no keyboard, no strings: tracks of those kinds play with the system's General MIDI set.
- **No pick between several of each.** The point is a good default, not a catalogue. Other sets you like work too: put them in the `soundfonts` folder and pick them in the MIDI plugin's dialog.
- **The sources can move.** The files come straight from their authors' sites. If one moves a file, its checksum fails and the install stops, until `sets.txt` is pinned again.
- **Big downloads.** About 1.5 GB for everything. On a slow or metered connection, take only the sets you need with `--sets`.

## Left out on purpose

- **Hosting the sets ourselves.** The files stay with their authors, so the credit and the licence stay with them too, and nobody has to trust a copy.
- **Editing the sets.** Nothing inside any file is changed. Only the instrument file is renamed, so it reads well in OxiGuitar.
- **Downloading from OxiGuitar itself.** The app never connects to the internet. The installer is a separate script, or a package step that asks first.
- **Sets with licences that restrict use**, such as non-commercial ones. Everything here can be used in any music you make.

## Where you can help

- **Suggest sets.** A free, well-recorded piano, organ or string section under CC0 or CC BY would fill the biggest gaps. Open an issue with a link and the licence.
- **Listen.** Tell us which sets sound wrong in OxiGuitar, and on which notes or techniques.
- **Test the installers** on Windows and macOS, which the maintainer can't try by hand.
