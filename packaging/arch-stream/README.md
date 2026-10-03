# mixxx-stream — experimental streaming fork of Mixxx (Arch package)

> **Not upstream. Use at your own risk.**
>
> This is an experimental fork of Mixxx that adds SoundCloud and Deezer support
> on top of the TIDAL integration. It is tracked on the `experimental/streaming`
> branch and is **deliberately not kept in sync with the upstream `main`
> branch**, so it will fall behind upstream bug fixes, improvements and security
> patches over time. Packaging it here simply makes it possible to install the
> fork alongside the official `mixxx` package without system updates clobbering
> it.

## Why this is safe with system updates

The package installs to its **own name and prefix**, so a `pacman -Syu` (or any
update to the official `mixxx` package) cannot overwrite or break it:

| Path | Provided by |
|------|-------------|
| `/opt/mixxx-stream/bin/mixxx` | this package |
| `/opt/mixxx-stream/share/mixxx` | this package |
| `/usr/bin/mixxx-stream` | this package (wrapper) |
| `/usr/local/bin/mixxx` | this package (symlink, shadows official `mixxx` in interactive shells) |
| `/usr/share/applications/org.mixxx.stream.desktop` | this package |
| `/usr/lib/udev/rules.d/69-mixxx-stream-usb-uaccess.rules` | this package |

The official `mixxx` package keeps its own `/usr/bin/mixxx` and `/usr/share/mixxx`
untouched. The symlink at `/usr/local/bin/mixxx` is owned by a file that no
pacman package provides (official `mixxx` only ships `/usr/bin/mixxx`), so there
is no file conflict; `pacman -R mixxx-stream` removes it cleanly. `/usr/local/bin`
comes before `/usr/bin` in `PATH`, so typing `mixxx` runs the fork. Use
`command mixxx` or `/usr/bin/mixxx` to run the official package explicitly.

## Layout

```
packaging/arch/
  PKGBUILD                    # builds the package from a prebuilt tree
  mixxx-stream-files.tar.zst  # prebuilt file tree (bin + share), from the fork
  update-package.sh           # regenerate the tarball + pkgver after a rebuild
  make-repo.sh                # build the package and add it to a pacman repo
dist/arch-repo/               # generated: the pacman repository
```

The package ships a **prebuilt** binary so users do not have to run Mixxx's very
large/slow build. The binary dynamically links normal system libraries, so
`depends` in the `PKGBUILD` lists those packages and pacman resolves the rest.

## Build / rebuild the package

After rebuilding the fork (see the main `replace-mixxx.sh` / build instructions):

```bash
bash packaging/arch/update-package.sh   # refresh tarball + pkgver from build/
bash packaging/arch/make-repo.sh        # build package + update dist/arch-repo
```

## Install

Directly from the built package:

```bash
sudo pacman -U packaging/arch/mixxx-stream-*.pkg.tar.zst
```

Or from the repository (served over HTTP or a local path). Add to
`/etc/pacman.conf`:

```ini
[mixxx-stream]
SigLevel = Optional TrustAll
Server = https://your-host.example/arch-repo
# or a local path:
# Server = file:///home/cure/Projects/mixxx-stream/dist/arch-repo
```

Then:

```bash
sudo pacman -Sy mixxx-stream      # only syncs the mixxx-stream db
sudo pacman -S mixxx-stream
```

Using `-Sy` only for this repository avoids partial-upgrade issues with the
official repos.

## Uninstall

```bash
sudo pacman -R mixxx-stream
```

## Notes

- The package is `x86_64` only and built for this machine's current library
  versions. On a different machine, or after your system libraries change ABI
  incompatibly, rebuild with `update-package.sh` + `make-repo.sh`.
- The fork's version tracks upstream `2.7.0.alpha` plus a fork revision
  (`r<commits-ahead>.g<hash>`), not an upstream release.
