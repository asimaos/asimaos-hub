# Contributing to Asima Hub

Thank you for helping. Asima Hub is the Asima OS project's app for the news, the downloads, the USB
stick and the system's updates; [README.md](README.md) says what it does and how to build it.

- **Build and test** in a rootless Podman container: `./build.sh test` builds the Hub and runs its
  end-to-end tests, `./build.sh screenshots` renders every screen, light and dark. A change to a
  screen is checked from its screenshots.
- **Asima UI** (`ui/`) is shared with the Asima OS apps and comes from the
  [asimaos](https://github.com/asimaos/asimaos) repository (`apps/ui`): change it there.
- **The rules** are Asima OS's: plain words, British spelling, honest about limits, secrets never on
  a command line. See its [CONTRIBUTING.md](https://github.com/asimaos/asimaos/blob/main/CONTRIBUTING.md).
- This repository is published from the maintainer's private working repository, so a pull request
  isn't merged here directly: its change is applied there, keeping you as its author, and appears
  here with the next publish. Contributions are under the [GPL-3.0-or-later](LICENSE); no sign-off
  line or extra agreement is needed.
- A security problem? Please see [SECURITY.md](SECURITY.md), never a public issue.
