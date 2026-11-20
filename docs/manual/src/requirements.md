# Requirements and assumptions

## Requirements

- About 1.5 GB of disk and a network connection for the download, for every set. A few sets are much smaller.
- `bash` and `curl` on Linux and macOS, or PowerShell on Windows.
- A sound plugin that plays SFZ and SoundFont sets, such as the MIDI plugin, to use them. See [its manual](https://mateusrdp.github.io/oxiguitar-midi/).

## Assumptions

- You are happy for the installer to fetch files from the places `sets.txt` lists, after it has shown you them and you have said yes.
- The sets' authors keep their files where they are. If one moves, the checksum fails and the install stops rather than using something else.
