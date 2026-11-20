# Architecture and strategy

There is no program here, only two installer scripts and a list. `sets.in` says which instrument belongs to each set. `scripts/pin.sh` reads it, finds the files each instrument plays in the source repository, downloads them once to compute their checksums, and writes `sets.txt`. `sets.txt` lists every file with its address, size and SHA-256. Addresses are pinned to a commit of the source repository, so they don't change under you.

The strategy is to be honest and boring about downloading:

- Nothing is downloaded until you say yes, and nothing is sent anywhere. There is no telemetry.
- A file that doesn't match its checksum is thrown away and the install stops.
- The steel-string guitar is published only as one archive, so that set downloads the archive once, checks it, and takes only the listed files out of it.
- The instrument file is renamed, to `Clean Guitar.sfz` for example, so it reads well in OxiGuitar. Nothing inside any file is edited.

On Debian and Ubuntu, the package asks before downloading, and the default answer is yes, so an unattended install downloads the sets. On Fedora, the download happens in the package's post-install step. A failed download doesn't fail the installation.
