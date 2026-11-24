# Asima Hub

Asima OS's online companion, and the one Asima OS app that goes on the internet. On any Linux (and
later Windows) it shows what Asima OS will do on the PC, downloads it and writes the USB stick; on
Asima OS it also downloads updates and hands them to Asima Updater, shows the project's news and
helps send a problem report. It is never part of the Asima OS image: install it only if you want it.

App ID `io.github.asimaos.Hub`. Qt 6 and QML, with Asima UI, the design system it shares with the
Asima OS apps. Website: [asimaos.pages.dev](https://asimaos.pages.dev/) · the OS:
[asimaos/asimaos](https://github.com/asimaos/asimaos).

## What it does

| Runs on | As | Updates itself | Status |
| --- | --- | --- | --- |
| Asima OS and other Linux | Flatpak: Flathub first, an Asima Flatpak repository as the fallback | Through Flatpak; the trial bundle doesn't, so it is downloaded again | Built: a trial bundle on GitHub Releases; Flathub later |
| Other Linux | AppImage; Snap | From the feed; through the Snap Store | Later |
| Windows | `.exe` | From the feed | Later |

The Hub's own files are attached to this repository's GitHub Releases; `releases/latest/download/<file>`
always gives the newest, and Asima Manager on Asima OS offers that link (Discover installs it). The
installer will offer it for after the first sign-in (later).

| Page | Shows | Actions | Status |
| --- | --- | --- | --- |
| Updates (Asima OS) | The newest release from the feed, the version installed now | Download (resumes where it stopped), checked against the feed's SHA-256, then "Install now": the file goes to Asima Updater's service as a file descriptor (`VerifyUpdate`, then `ApplyUpdate` with the administrator's password), progress from its `JobProgress`/`JobFinished` signals, then "Restart now" (logind); "Open in Asima Updater" still opens the file through the desktop portal; without the service (another system) the file opens there too | Built |
| Get Asima OS (everywhere; the first page outside Asima OS) | "What you'll get on this PC", the newest ISO, the USB sticks plugged in | Download the ISO (resumes, checked against the feed's SHA-256), write it to a USB stick (below), how to start the PC from it | Built |
| What's new | The news, and the notes of every version with the installed one marked | Read more (a news item's link) | Built |
| App groups (Asima OS) | System, gaming, office and Windows-compatibility apps, from Flathub or Snap | Pick apps; Asima Manager's service installs them after one password | Later |
| Guides & wiki | Links from the feed | Open in the browser | Built |
| Problem report | The report Asima Maintenance saved | Read and edit it, then "Save and write an email": the report is saved in Downloads and the mail app opens with the project's address from the feed | Built; the address comes once the project has one |

**"What you'll get on this PC" never refuses anyone** . It reads `/sys` and `/proc` as the
installer does and, like the installer, switches features off and says why: no TPM 2.0 means the
disk asks for its passphrase at each start; Secure Boot off means no lockdown of unsigned drivers;
an NVIDIA card older than GTX 16xx / RTX 20xx runs the desktop well and games less well. Only three
things stop an install, because the PC can't start or hold Asima OS: a processor that isn't 64-bit
x86, a start in legacy BIOS mode (the check says how to switch to UEFI) and no disk of at least
48 GB. What can't be read (the firmware, from inside a sandbox or a container) is said, never
guessed; the installer on the stick checks it again, chooses the disk and erases only that one.
`asimaos-hub --pc-check` prints the check (`ASIMAOS_HUB_TEST_SYSROOT` puts a folder in front of
`/sys` and `/proc`, for the tests).

**Writing the USB stick** goes through UDisks, like the desktop's own disk tools. Only whole USB or
removable drives are offered (never one UDisks counts as part of the system, never a read-only
one); one smaller than the ISO is marked "Too small". After a typed `ERASE`, the Hub checks that
the stick is still the one listed (the same drive and size, so another disk plugged in under its
name is never written), unmounts its partitions and has UDisks open it exclusively, which asks for
the administrator's password. It writes the ISO, flushes it, compares what it wrote with the feed's
SHA-256, then reads the stick back and compares again; only then does it call the stick ready.
`asimaos-hub --write-test ISO --sha256 HEX` writes to the file named by `ASIMAOS_HUB_TEST_TARGET`
instead (the tests; without it nothing is written).

**The feed** (format 2, built) is one JSON file on the Asima OS website,
`https://asimaos.pages.dev/feed/feed.json`, with a detached Ed25519 signature,
`feed.json.sig`, made with the **feed key**. The Hub carries the feed key's public half
(`src/feedcheck.h`, with its fingerprint) and refuses a feed whose signature doesn't verify, as a
whole; the release key stays for the OS. The website's `scripts/make-feed` builds the feed from the
website's news posts and its `feed/` folder (the published versions, the app groups, the links) and
signs it. The update file and the ISO are checked against
the feed's SHA-256, and Asima Updater checks an update's release signature again.

```json
{ "format": 2,
  "releases": [ { "version": "2026.12.01.1", "channel": "beta", "date": "2026-12-01", "notes": ["…"],
                  "update": { "url": "https://…/asimaos-2026.12.01.1-x86_64.aosupd", "size": 3612344320, "sha256": "…" },
                  "iso":    { "url": "https://…/asimaos-2026.12.01.1-x86_64.iso", "size": 4617089024, "sha256": "…" } } ],
  "news":   [ { "date": "2026-12-01", "title": "…", "text": "…", "link": "https://…" } ],
  "groups": [ { "id": "gaming", "title": "Gaming", "apps": [ { "id": "com.valvesoftware.Steam", "from": "flathub" } ] } ],
  "hub":    { "version": "0.2.0", "files": { "appimage": { "url": "…", "sha256": "…" }, "windows": { "url": "…", "sha256": "…" } } },
  "links":  { "guides": "https://…", "wiki": "https://…", "website": "https://…" },
  "reports": { "email": "…" } }
```

The feed's address is set at build time (`ASIMAOS_HUB_FEED`, https only): the Flatpak's is the one
above; other builds have none and say so. `asimaos-hub --check-feed FILE [--feed-key HEX]` checks a
feed file against `FILE.sig` and prints what the Hub reads from it (the tests use it). Inside the
Flatpak it reads the installed version from the host (`/run/host/os-release`) and saves downloads
in the Downloads folder (`--filesystem=xdg-download`); it may talk to Asima Updater's service and to
logind on the system bus (`--system-talk-name=io.github.asimaos.Updater1`, `org.freedesktop.login1`)
to install an update and restart. The Flatpak bundle: `packaging/flatpak.sh` (below).

## Building

Everything runs in a rootless Podman container; nothing is installed on the PC.

```bash
./build.sh                 # build into build/ (Qt 6, OpenSSL)
./build.sh test            # build, then the end-to-end tests in tests/ (feed checks, PC check, USB writing)
./build.sh screenshots     # render every screen, light and dark, into screenshots/
./build.sh translations    # collect new strings into i18n/*.ts
packaging/flatpak.sh       # the Flatpak bundle: build/flatpak/AsimaHub-x86_64.flatpak (--install to try it)
```

Asima UI comes from `ui/` (a copy of the OS's `apps/ui`, updated with every release of the Hub).
The feed key's public half is in `src/feedcheck.h`; a fork with its own feed puts its own there.

## Releasing

Until Asima Hub is on Flathub, its Flatpak is a bundle attached to a GitHub Release here; Asima
Manager's "Get Asima Hub" opens the newest one.

1. Raise `VERSION` in `CMakeLists.txt` and add a `<release>` to `io.github.asimaos.Hub.metainfo.xml`.
2. `packaging/flatpak.sh` builds `build/flatpak/AsimaHub-x86_64.flatpak` (flatpak-builder, or
   Flathub's `org.flatpak.Builder` when the host has none; the KDE runtime comes from Flathub).
3. Make a release with the tag `v<version>` and the bundle attached, as a normal release (not a
   pre-release), so that `releases/latest/download/AsimaHub-x86_64.flatpak` points at it.
4. The bundle doesn't update itself: say in the news that a new version is out.

## License

GPL-3.0-or-later, like Asima OS.
