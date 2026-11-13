# EX-Proton

EX-Proton is a custom build of Steam Proton. It is an overlay: an upstream
Proton tree is pinned as a git submodule (`proton/`), and this repository adds
component overrides, patches and a CI build on top of it. The upstream tree is
never edited in this repository; everything is applied at build time by
`scripts/prepare.sh`.

The current base is Valve's [Proton Experimental](https://github.com/ValveSoftware/Proton)
at tag `experimental-11.0-20261105c`. Video playback is Valve's own
(winegstreamer + GStreamer), unchanged. EX-Proton adds a small set of Wine
latency / performance patches and optional low-latency DXVK and vkd3d-proton
builds on top.

## Goals

These are goals, not results:

- Zero-stutter gameplay (including shader and frame-pacing behaviour)
- Low input and presentation latency
- Good performance
- Broad game compatibility, including pre-rendered video playback

## Status

`EX-Proton11-1` has been tested by the maintainer in one game (Crimson Desert,
AMD GPU): it launches and pre-rendered videos play smoothly. Nothing has been
benchmarked, and not every optional switch has been tested. Do not assume any
goal above has been met.

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
scripts/prepare.sh           submodules -> overrides -> extras -> our patches
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
../proton/configure.sh --enable-ccache --container-engine=docker --build-name=EX-Proton11-1
make -j"$(nproc)" redist
tar --transform 's,^redist,EX-Proton11-1,' -czf EX-Proton11-1.tar.gz redist
```

`make redist` writes the build into `build/redist/`; the last line packages it.
`scripts/prepare.sh` refuses to run on a `proton` tree that already has local
modifications; use a fresh clone.

## Installing a built tarball

1. Extract it on the Linux machine with `tar` (not a graphical archive tool,
   and not on Windows: the build needs its file permissions and symlinks):
   `tar -xf <build name>.tar.gz -C ~/.steam/root/compatibilitytools.d/`
   so that you get `~/.steam/root/compatibilitytools.d/<build name>/proton`.
   A tarball downloaded from the Actions tab arrives wrapped in a `.zip`;
   unzip that first.
2. Restart Steam.
3. For each game: Properties, Compatibility, tick "Force the use of a specific
   Steam Play compatibility tool", and select the EX-Proton build.

## Options added by EX-Proton

Set these per game in Steam's launch options, for example
`PROTON_DXVK_LOWLATENCY=1 %command%`. Everything the base provides is
documented in `proton/README.md`. Options that exist only in Proton-GE (for
example `LOW_LATENCY_LAYER`, `PROTON_FSR4_UPGRADE`, `WINE_FULLSCREEN_FSR`) do
not exist in this build.

| Variable | Effect |
|---|---|
| `PROTON_DXVK_LOWLATENCY=1` | Use the low-latency DXVK build (D3D8-11) instead of the stock one. |
| `PROTON_VKD3D_LOWLATENCY=1` | Use the low-latency vkd3d-proton build (D3D12) instead of the stock one. |

| `LOW_LATENCY_LAYER=1` | Load the Korthos Vulkan low-latency layer (same switch as Proton-GE). |
| `PROTON_FSR4_UPGRADE=1` | Download AMD's FSR4 DLL into the prefix (via protonfixes, from a third-party manifest) and upgrade FSR 3.1 games to FSR4 through Wine's `amdxc64`. |
| `PROTON_LOCAL_SHADER_CACHE=1` | Keep a per-game shader cache (Mesa / driver, DXVK, vkd3d-proton) in the game's Steam shader directory. Meant for use with Steam's shader pre-caching switched off. |

All are off by default; see [PATCHES.md](PATCHES.md) for what they are and
their limits. protonfixes (per-game fixes from umu-protonfixes) runs
automatically; `PROTONFIXES_DISABLE=1` turns it off.

HDR and fullscreen FSR upscaling are not patched into this build. On this base
they are provided by gamescope, for example
`DXVK_HDR=1 gamescope -f --hdr-enabled -- %command%` and
`gamescope -w 1920 -h 1080 -W 3840 -H 2160 -F fsr -f -- %command%`.

## Limitations

- Anti-cheat (EAC, BattlEye and similar) support depends on the game developers
  enabling it and on Valve's runtimes. It cannot be added by patching here.
- The build container is Steam Linux Runtime 4.0 (`steamrt4`), as set by the
  upstream tree's `Makefile.in`.

## Credits and links

- [Valve Proton](https://github.com/ValveSoftware/Proton)
- [Proton-GE](https://github.com/GloriousEggroll/proton-ge-custom), source of the Wine patches and an earlier base
- [proton-cachyos](https://github.com/CachyOS/proton-cachyos)
- Proton-EM and DW-Proton, reviewed for changes worth carrying (see PATCHES.md)

## Licence

Proton is BSD-3-Clause and Wine is LGPL. Builds must ship the upstream LICENSE
files (the `make redist` output includes them; do not remove them). This
repository does not yet have a licence of its own; one still needs to be chosen.
