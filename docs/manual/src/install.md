# Installing

There are two ways: a package on Linux, or the installer by hand on any system. The [by hand](use-cases.md) section of the use cases page has the commands for the second.

## Linux packages

The package is called `oxiguitar-bettersounds-soundfonts`. It lives in a signed package repository on GitHub Pages that you add once.

Debian, Ubuntu and relatives:

```sh
sudo install -d -m 0755 /etc/apt/keyrings
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.gpg -o /etc/apt/keyrings/oxiguitar.gpg
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.sources -o /etc/apt/sources.list.d/oxiguitar.sources
sudo apt update
sudo apt install oxiguitar-bettersounds-soundfonts
```

Fedora and relatives:

```sh
sudo curl -fsSL https://mateusrdp.github.io/oxiguitar-packages/oxiguitar.repo -o /etc/yum.repos.d/oxiguitar.repo
sudo dnf install oxiguitar-bettersounds-soundfonts
```

Installing the package installs the sets for every user, about 1.5 GB, downloaded from their authors and checked against the checksums in `sets.txt`. On Debian and Ubuntu it asks first, and yes is the default, so an unattended install downloads them. To answer no ahead of time:

```sh
echo 'oxiguitar-bettersounds-soundfonts oxiguitar-bettersounds-soundfonts/download boolean false' | sudo debconf-set-selections
```

With dnf, set `OXIGUITAR_SKIP_SOUNDS=1` in the environment of the install to skip the download. Removing the package removes the sets it installed. If a download fails, the installation still succeeds. Run `sudo oxiguitar-install-sounds --system` to try again, or to choose which sets any time later.

## By hand

This is the only way on Windows and macOS. Take the zip of a release from the [releases page](https://github.com/mateusrdp/oxiguitar-bettersounds-soundfonts/releases), unpack it, and run `install.sh` (Linux and macOS) or `install.ps1` (Windows) from the unpacked folder. The use cases page lists the options.
