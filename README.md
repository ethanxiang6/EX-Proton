# EX-Proton

EX-Proton is a custom build of Steam Proton. It is an overlay: an upstream
Proton tree is pinned as a git submodule (`proton/`), and this repository adds
component overrides, patches and a CI build on top of it. The upstream tree is
never edited in this repository; everything is applied at build time by
`scripts/prepare.sh`.

The current base is Valve's [Proton Experimental](https://github.com/ValveSoftware/Proton)
at tag `experimental-11.0-20261105c`. Video playback is Valve's own
(winegstreamer + GStreamer), unchanged. EX-Proton adds a small set of Wine
latency / performance patches, protonfixes, and optional low-latency and
shader-cache switches on top.

There are two builds of each release:

| Build | For | Status |
|---|---|---|
| `EX-Proton1-1` | x86-64 Linux PCs (almost every gaming PC) | Tested in a game |
| `EX-Proton1-1-aarch64` | ARM64 Linux machines; runs x86 Windows games through FEX | Built, untested; published as a pre-release |

## Goals

These are goals, not results:

- Zero-stutter gameplay (including shader and frame-pacing behaviour)
- Low input and presentation latency
- Good performance
- Broad game compatibility, including pre-rendered video playback

## Status

`EX-Proton1-1` has been tested by the maintainer in one game (Crimson Desert,
AMD GPU): it launches and pre-rendered videos play smoothly. Nothing has been
benchmarked, and not every optional switch has been tested. Do not assume any
goal above has been met.

`EX-Proton1-1-aarch64` has not been run on any ARM64 hardware.

## Versioning

- The repository name stays `EX-Proton`.
- Releases are tagged `EX-Proton<series>-<n>`, for example `EX-Proton1-1`:
  `<series>` is EX-Proton's own series number and `<n>` counts releases in that
  series. The numbers are not tied to the upstream Proton version.
- The ARM64 build of a release has the same name with `-aarch64` appended, for
  example `EX-Proton1-1-aarch64`, and is published as a separate release.
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
                             any other directory applies inside proton/<component>;
                             "__" in a directory name stands for "/")
patches/x86_64-only.list     patches left out of the ARM64 build
PATCHES.md                   what is integrated and where it comes from
release-notes/<tag>.md       text of each GitHub release
scripts/prepare.sh           submodules -> overrides -> extras -> our patches
.github/workflows/           build.yml (x86-64), build-arm64.yml (ARM64),
                             release-from-run.yml, rename-release.yml
```

## Building

### CI (GitHub Actions)

- x86-64: run the "Build EX-Proton" workflow (`workflow_dispatch`, optional
  build-name input).
- ARM64: run the "Build EX-Proton (ARM64)" workflow. It builds on a GitHub ARM64
  runner with Valve's `--target-arch=arm64`; Valve's tree needs an ARM64 build
  machine for this.
- Each uploads the tarball and a `.sha512sum` file as workflow artifacts.
- To publish a tested build, run "Release from build run" with the build's run
  id and the tag, after adding `release-notes/<tag>.md`. Tags ending in
  `-aarch64` are published as pre-releases.
- CI builds without debug symbols to fit on a hosted runner.

### Local (Linux with Docker or Podman)

```bash
git clone https://github.com/ethanxiang6/EX-Proton.git && cd EX-Proton
scripts/prepare.sh --jobs "$(nproc)"      # downloads many submodules; needs git, bash, patch, wget
mkdir build && cd build
../proton/configure.sh --enable-ccache --container-engine=docker --build-name=EX-Proton1-1
make -j"$(nproc)" redist
tar --transform 's,^redist,EX-Proton1-1,' -czf EX-Proton1-1.tar.gz redist
```

`make redist` writes the build into `build/redist/`; the last line packages it.
For ARM64, on an ARM64 Linux machine, pass `--target-arch arm64` to
`scripts/prepare.sh` and `--target-arch=arm64` to `configure.sh`.
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
documented in `proton/README.md`. Proton-GE options not listed here (for
example `WINE_FULLSCREEN_FSR`, `PROTON_ENABLE_HDR`, `PROTON_NATIVE_AGS`) do not
exist in this build. The same options exist in the ARM64 build, untested there.

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
- ARM64: x86 games run through FEX translation, so CPU-heavy games run slower
  than on x86-64 hardware. It needs a working Vulkan driver on the ARM64
  machine, and it cannot be used by x86 Steam running under an emulator.

## Credits and links

- [Valve Proton](https://github.com/ValveSoftware/Proton)
- [Proton-GE](https://github.com/GloriousEggroll/proton-ge-custom), source of the Wine patches and an earlier base
- [proton-cachyos](https://github.com/CachyOS/proton-cachyos)
- Proton-EM and DW-Proton, reviewed for changes worth carrying (see PATCHES.md)

## Licence

Proton is BSD-3-Clause and Wine is LGPL. Builds must ship the upstream LICENSE
files (the `make redist` output includes them; do not remove them). This
repository does not yet have a licence of its own; one still needs to be chosen.
