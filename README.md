# EXProton

EXProton is a custom build of Steam Proton: an overlay patch set plus a CI
build on top of Valve's Proton 11.0-2e (tag `proton-11.0-2e`, commit
`bc896217ffcd67f892f952b010f898fe7bd0f0a1`). Valve's Proton is pinned as a git
submodule (`proton/`) and is never modified in this repository; our changes
live outside it and are applied at build time by `scripts/prepare.sh`.

## Goals

These are goals, not results:

- Zero-stutter gameplay (including shader and frame-pacing behaviour)
- Low input and presentation latency
- Good performance
- Broad game compatibility

## Status

As of 2026-11-11 no build has completed and nothing has been benchmarked. The
build scripts and workflow have been written but never executed. Expect
problems, and do not assume any goal above has been met.

The first release is planned as tag `EXProton-11.0-2e-1`.

## Repository layout

```
proton/                    Valve Proton, pinned submodule (do not edit)
patches/<component>/*.patch  patches applied in lexicographic order with git apply
                           (patches/proton/ applies at the root of the proton checkout;
                           any other directory applies inside proton/<component>)
overrides.conf             optional: replace a component with a specific upstream commit
                           (lines of: <path-inside-proton> <git-url> <40-char-sha>)
PATCHES.md                 the exact patch list and provenance
scripts/prepare.sh         initialises submodules, applies overrides and patches
.github/workflows/build.yml  CI build and release workflow
```

## Building

### CI (GitHub Actions)

- Run the "Build EXProton" workflow manually (`workflow_dispatch`, optional
  build-name input), or push a tag matching `EXProton-*`.
- The tarball and a `.sha512sum` file are uploaded as workflow artifacts. On tag
  pushes they are also attached to a GitHub release.
- The build needs a lot of disk and time (the job timeout is 350 minutes). It
  may not fit on a standard hosted runner; this is unverified.

### Local (Linux with Docker or Podman)

```bash
git clone <this repo> EXProton && cd EXProton
scripts/prepare.sh --jobs "$(nproc)"      # downloads many submodules; refuses a modified proton tree
mkdir build && cd build
../proton/configure.sh --enable-ccache --container-engine=docker --build-name=EXProton-11.0-2e-1
make -j"$(nproc)" redist
```

Use `--container-engine=podman` for Podman (see `proton/README.md` for SELinux
notes). The Proton SDK container image is whatever Proton's `Makefile.in`
defaults to; `make get-steamrt-image` in the build directory prints it.

`make redist` writes the distributable tree to `build/redist/`. It does not make
a tarball; CI creates one with the build name as the top-level directory. To do
the same locally:

```bash
tar --transform 's,^redist,EXProton-11.0-2e-1,' -czf EXProton-11.0-2e-1.tar.gz redist
```

## Installing a built tarball

1. Extract it into `~/.steam/root/compatibilitytools.d/` so that you get
   `~/.steam/root/compatibilitytools.d/<build name>/`.
2. Restart Steam.
3. For each game: Properties, Compatibility, tick "Force the use of a specific
   Steam Play compatibility tool", and select the EXProton build.

## Patches

See [PATCHES.md](PATCHES.md) for the exact list of patches and where each one
comes from. That file is the source of truth; this README does not list them.

## Limitations

- Anti-cheat (EAC, BattlEye and similar) support depends on the game developers
  enabling it and on Valve's runtimes. It cannot be added by patching here.
- This build is based on Proton 11.0, whose SDK container is Steam Linux Runtime
  4.0 (`steamrt4`). Proton 10 used Steam Runtime 3 "Sniper"; Sniper is not used
  here. Patches written for Sniper-era Proton may not apply or behave the same.
- Untested: see Status.

## Credits and links

- [Valve Proton](https://github.com/ValveSoftware/Proton), the base of everything here
- [Proton-GE](https://github.com/GloriousEggroll/proton-ge-custom), the model for the CI workflow
- [proton-cachyos](https://github.com/CachyOS/proton-cachyos)
- [wine-tkg-git](https://github.com/Frogging-Family/wine-tkg-git)

## Licence

Proton is BSD-3-Clause and Wine is LGPL. Builds must ship Proton's LICENSE files
(the `make redist` output includes them; do not remove them). This repository
does not yet have a licence of its own; one still needs to be chosen.
