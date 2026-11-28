# EX-Proton

EX-Proton is a fork of Valve's [Proton](https://github.com/ValveSoftware/Proton),
based on Proton Experimental. It keeps Valve's history: the current base is
tag `experimental-11.0-20261123b`, and EX-Proton's changes are ordinary commits
on top of it. Video playback is Valve's own (winegstreamer + GStreamer),
unchanged.

Valve's own README is [`README.md`](../README.md) at the repository root; it
still describes how the Proton build system works.

## What EX-Proton adds

- Eight Wine performance patches from Proton-GE (faster `QueryPerformanceCounter`,
  heap and lock fixes, NTSync mutex fix, DLSS address range, asynchronous power
  status, and more; see [PATCHES.md](../PATCHES.md)).
- **Discord activity:** a bridge that passes a game's Discord Rich Presence to
  the Linux Discord client (also Flatpak, Snap and Vesktop), on by default.
- protonfixes (per-game fixes from umu-protonfixes), run automatically.
- Optional switches for low latency, FSR4 and a per-game shader cache (below).

## Builds

| Build | For | Status |
|---|---|---|
| `EX-Proton1-2` | x86-64 Linux PCs; this fork, on Proton Experimental `20261123b` | Released, not yet tested in a game |
| `EX-Proton1-2-aarch64` | ARM64 Linux machines (x86 games through FEX) | Released as a pre-release, untested on hardware |
| `EX-Proton1-1` | x86-64, previous base (Experimental `20261105c`, no Discord bridge) | Released, tested in a game |
| `EX-Proton1-1-aarch64` | ARM64, previous base | Released as a pre-release, untested on hardware |

Nothing has been benchmarked. Do not assume any performance or latency gain.

## Options added by EX-Proton

Set them in the game's Steam launch options before `%command%`, for example
`LOW_LATENCY_LAYER=1 %command%`.

| Variable | Effect |
|---|---|
| `PROTON_DISCORD_BRIDGE=0` | Turn off the Discord bridge (on by default; x86-64 builds only). |
| `PROTON_DXVK_LOWLATENCY=1` | Low-latency DXVK build (D3D8-11). |
| `PROTON_VKD3D_LOWLATENCY=1` | Low-latency vkd3d-proton build (D3D12). Its author lists Intel GPUs, AMD Anti-Lag 2 and frame generation as unsupported. |
| `LOW_LATENCY_LAYER=1` | Korthos Vulkan low-latency layer. |
| `PROTON_FSR4_UPGRADE=1` | Downloads AMD's FSR4 DLL into the prefix (via protonfixes) and upgrades FSR 3.1 games to FSR4. |
| `PROTON_LOCAL_SHADER_CACHE=1` | Per-game shader cache, for use with Steam's shader pre-caching off. |
| `PROTONFIXES_DISABLE=1` | Turn off protonfixes. |

HDR and fullscreen FSR upscaling are not patched in; use gamescope, for example
`DXVK_HDR=1 gamescope -f --hdr-enabled -- %command%`.

### Discord

Discord shows what you are playing in two ways:

- **Rich Presence** (game details, party, time): the game talks to Discord over a
  Windows pipe. EX-Proton's bridge forwards that pipe to the Linux Discord
  client. It needs the Discord desktop client running before the game starts.
  Only games with Discord Rich Presence support use this.
- **Plain "Playing ..." status** for other games: Discord detects the game's
  process itself. That depends on Discord, not on Proton; adding the game under
  Discord's Settings, Registered Games helps when it is not picked up.

The bridge is a Windows program that makes x86-64 Linux system calls, so it is
not included in the ARM64 build.

## Installing

1. Download the release tarball on the Linux machine and extract it with `tar`
   (not a graphical archive tool, not on Windows):
   `tar -xf <build name>.tar.gz -C ~/.steam/root/compatibilitytools.d/`
2. Restart Steam.
3. Per game: Properties, Compatibility, "Force the use of a specific Steam Play
   compatibility tool", and pick the EX-Proton build.

A tarball downloaded from the Actions tab arrives inside a `.zip`; unzip that
first.

## Repository layout

```
(Valve's Proton tree)        Makefile.in, proton, steam_helper/, submodules, ...
extras/                      extra source trees (submodules) and their build rules (*.mk)
patches/<component>/*.patch  patches applied to submodules at build time
                             ("__" in a directory name stands for "/")
patches/x86_64-only.list     patches left out of the ARM64 build
scripts/prepare.sh           fetch submodules, apply patches/
PATCHES.md                   what is changed and where it comes from
release-notes/<tag>.md       text of each GitHub release
.github/workflows/           build.yml (x86-64), build-arm64.yml (ARM64),
                             release-from-run.yml, rename-release.yml
```

Changes to Proton's own files are committed directly. Wine and the extra
components are submodules, so changes to them are patch files.

## Building

### CI (GitHub Actions)

- x86-64: run "Build EX-Proton".
- ARM64: run "Build EX-Proton (ARM64)" (GitHub ARM64 runner; Valve's tree needs
  an ARM64 build machine for this).
- To publish a build: add `release-notes/<tag>.md`, then run "Release from build
  run" with the build's run id and the tag. Tags ending in `-aarch64` become
  pre-releases.

### Local (Linux with Docker or Podman)

```bash
git clone https://github.com/ethanxiang6/EX-Proton.git && cd EX-Proton
scripts/prepare.sh --jobs "$(nproc)"     # add --target-arch arm64 on an ARM64 machine
mkdir build && cd build
../configure.sh --enable-ccache --container-engine=docker --build-name=EX-Proton1-2
make -j"$(nproc)" redist
tar --transform 's,^redist,EX-Proton1-2,' -czf EX-Proton1-2.tar.gz redist
```

For ARM64 also pass `--target-arch=arm64` to `configure.sh`.

## Updating to a new Proton Experimental

```bash
git fetch https://github.com/ValveSoftware/Proton.git tag experimental-11.0-<date>
git merge experimental-11.0-<date>
```

Then check that `patches/` still applies (the CI prepare step does this) and
build. Releases are numbered `EX-Proton<series>-<n>` independently of Valve's
version; the ARM64 build adds `-aarch64`.

## Limitations

- Anti-cheat support depends on game developers and Valve's runtimes.
- ARM64: x86 games run through FEX translation, so CPU-heavy games run slower;
  it needs a working Vulkan driver and the ARM64 Steam client.

## Credits

[Valve Proton](https://github.com/ValveSoftware/Proton);
[Proton-GE](https://github.com/GloriousEggroll/proton-ge-custom) (Wine patches,
Discord bridge integration); [rpc-bridge](https://github.com/enderice2/rpc-bridge);
[umu-protonfixes](https://github.com/open-wine-components/umu-protonfixes);
[netborg-afps](https://github.com/netborg-afps) low-latency DXVK / vkd3d-proton;
[Korthos low_latency_layer](https://github.com/Korthos-Software/low_latency_layer).

## Licence

Proton is BSD-3-Clause (`LICENSE`, `LICENSE.proton`) and Wine is LGPL. Builds
ship the upstream licence files. EX-Proton's own additions do not yet have a
separate licence.
