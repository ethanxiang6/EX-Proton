# EX-Proton

EX-Proton is a custom build of Steam Proton. It is an overlay: an upstream
Proton tree is pinned as a git submodule (`proton/`), and this repository adds
component overrides, patches and a CI build on top of it. The upstream tree is
never edited in this repository; everything is applied at build time by
`scripts/prepare.sh`.

The current base is [Proton-GE](https://github.com/GloriousEggroll/proton-ge-custom)
at tag `GE-Proton11-12`, which itself is Valve's Proton (bleeding-edge Wine)
plus wine-staging and GE's patch set, including its Media Foundation / video
playback rework and full FFmpeg codec build.

## Goals

These are goals, not results:

- Zero-stutter gameplay (including shader and frame-pacing behaviour)
- Low input and presentation latency
- Good performance
- Broad game compatibility, including pre-rendered video playback

## Status

Nothing has been benchmarked, and no build has been tested in a game yet. See
the Actions tab for whether the latest build compiled. Do not assume any goal
above has been met.

## Versioning

- The repository name stays `EX-Proton`.
- Releases are tagged `EX-Proton<major>-<n>`, for example `EX-Proton11-1`:
  `<major>` is the Proton major version of the base and `<n>` counts EX-Proton
  releases on that major version.
- When the upstream base publishes a new version, the `proton` submodule pin is
  moved to the new tag, the overrides and patches are re-checked, and a new
  release is tagged. The exact base of each release is recorded in
  [PATCHES.md](PATCHES.md).

## Repository layout

```
proton/                      upstream Proton tree, pinned submodule (do not edit)
overrides.conf               replace one of the upstream tree's components with another commit
                             (lines of: <path-inside-proton> <git-url> <40-char-sha>)
extras.conf                  add a source tree the upstream tree does not have (same line format)
patches/<component>/*.patch  our patches, applied in lexicographic order with git apply
                             (patches/proton/ applies at the root of the proton checkout;
                             any other directory applies inside proton/<component>)
PATCHES.md                   what is integrated and where it comes from
scripts/prepare.sh           submodules -> overrides -> Proton-GE's patch script -> our patches
.github/workflows/build.yml  CI build and release workflow
```

## Building

### CI (GitHub Actions)

- Run the "Build EX-Proton" workflow manually (`workflow_dispatch`, optional
  build-name input), or push a tag matching `EX-Proton*`.
- The tarball and a `.sha512sum` file are uploaded as workflow artifacts. On tag
  pushes they are also attached to a GitHub release.
- CI builds without debug symbols to fit on a hosted runner.

### Local (Linux with Docker or Podman)

```bash
git clone https://github.com/ethanxiang6/EX-Proton.git && cd EX-Proton
scripts/prepare.sh --jobs "$(nproc)"      # downloads many submodules; needs git, bash, patch, wget
mkdir build && cd build
../proton/configure.sh --container-engine=docker --build-name=EX-Proton11-1
make -j"$(nproc)" redist
```

`make redist` writes `EX-Proton11-1.tar.gz` and a checksum into `build/`.
`scripts/prepare.sh` refuses to run on a `proton` tree that already has local
modifications; use a fresh clone.

## Installing a built tarball

1. Extract it into `~/.steam/root/compatibilitytools.d/` so that you get
   `~/.steam/root/compatibilitytools.d/<build name>/`.
2. Restart Steam.
3. For each game: Properties, Compatibility, tick "Force the use of a specific
   Steam Play compatibility tool", and select the EX-Proton build.

## Options added by EX-Proton

Set these per game in Steam's launch options, for example
`PROTON_DXVK_LOWLATENCY=1 %command%`. Everything the base provides
(`PROTON_ENABLE_WAYLAND`, `LOW_LATENCY_LAYER`, `PROTON_FSR4_UPGRADE`, ...) is
documented in `proton/README.md`.

| Variable | Effect |
|---|---|
| `PROTON_DXVK_LOWLATENCY=1` | Use the low-latency DXVK build (D3D8-11) instead of the stock one. |
| `PROTON_VKD3D_LOWLATENCY=1` | Use the low-latency vkd3d-proton build (D3D12) instead of the stock one. |

Both are off by default; see [PATCHES.md](PATCHES.md) for what they are and
their limits.

## Limitations

- Anti-cheat (EAC, BattlEye and similar) support depends on the game developers
  enabling it and on Valve's runtimes. It cannot be added by patching here.
- The build container is Steam Linux Runtime 4.0 (`steamrt4`), as set by the
  upstream tree's `Makefile.in`.

## Credits and links

- [Valve Proton](https://github.com/ValveSoftware/Proton)
- [Proton-GE](https://github.com/GloriousEggroll/proton-ge-custom), the current base
- [proton-cachyos](https://github.com/CachyOS/proton-cachyos)
- Proton-EM and DW-Proton, reviewed for changes worth carrying (see PATCHES.md)

## Licence

Proton is BSD-3-Clause and Wine is LGPL. Builds must ship the upstream LICENSE
files (the `make redist` output includes them; do not remove them). This
repository does not yet have a licence of its own; one still needs to be chosen.
