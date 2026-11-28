# EX-Proton: what is changed and where it comes from

Nothing listed here has been benchmarked. "Builds" means the CI build completed;
it does not mean the change was tested in a game.

## Base

| Item | Pin |
|---|---|
| Upstream | ValveSoftware/Proton tag `experimental-11.0-20261123b`, commit `7d2df865ff88ea89171d1fe4cd02ec98d4099ef5` (Proton Experimental), merged with its history |
| Wine | ValveSoftware/wine `4c5e47d409a8012da3c678f09650acef4a7a27a1` (that tag's pin) |
| DXVK / vkd3d-proton | `9e57fa0b2c5b495ba1c890017d659935e5f1df65` / `30b0eb9bc12dc9f40e1a33a2be8c87cf0846447b` (that tag's pins) |
| Build SDK | steamrt4, from `Makefile.in` |

## Changes to Proton's own files (commits in this repository)

| Change | Files |
|---|---|
| Optional low-latency DXVK / vkd3d-proton builds and their launcher switches | `extras/build-dxvk-low-latency.mk`, `extras/build-vkd3d-low-latency.mk`, `Makefile.in`, `proton` |
| Build name written into the `version` file | `Makefile.in` |
| protonfixes, Vulkan low-latency layer, `PROTON_FSR4_UPGRADE`, `PROTON_LOCAL_SHADER_CACHE` | `extras/build-protonfixes.mk`, `extras/build-low_latency_layer.mk`, `Makefile.in`, `proton` |
| Discord Rich Presence bridge: build (x86-64), copy into the prefix, register and start as a Wine service from `steam.exe`; `PROTON_DISCORD_BRIDGE=0` disables | `extras/build-discord-rpc-bridge.mk`, `Makefile.in`, `proton`, `steam_helper/steam.c` (based on Proton-GE's steam_helper patch by Stelios Tsampas) |
| `wine` submodule URL made absolute (Valve's is relative to its own GitHub account) | `.gitmodules` |

## Extra source trees (submodules under `extras/`)

| Path | Source | Licence | Used for |
|---|---|---|---|
| `extras/dxvk-low-latency` | netborg-afps/dxvk-low-latency `d533db09` | Zlib | `PROTON_DXVK_LOWLATENCY=1` |
| `extras/vkd3d-low-latency` | netborg-afps/vkd3d-low-latency `f4e0518c` | LGPL-2.1 | `PROTON_VKD3D_LOWLATENCY=1` |
| `extras/low_latency_layer` | Korthos-Software/low_latency_layer `4e7fe12b` | MIT | `LOW_LATENCY_LAYER=1` |
| `extras/Vulkan-Utility-Libraries` | KhronosGroup `b538fb5b` | Apache-2.0 | building the layer (not shipped) |
| `extras/Vulkan-Headers-layer` | KhronosGroup/Vulkan-Headers `36872f90` | Apache-2.0 / MIT | building the layer (newer than the base's pin; not shipped) |
| `extras/protonfixes` | open-wine-components/umu-protonfixes `28a02c25` | BSD-2-Clause | per-game fixes, FSR4 download, shader cache |
| `extras/discord-rpc-bridge` | enderice2/rpc-bridge `6aa60772` | MIT | Discord Rich Presence |

Pins are the ones Proton-GE uses (rpc-bridge: Proton-GE's master at the time).

## Patches to submodules (`patches/`, applied by `scripts/prepare.sh`)

| File | What it does | Source |
|---|---|---|
| `patches/wine/0001-ntdll-reuse-free-blocks-of-partially-used-lfh-groups.patch` | Heap: reuse free blocks of partially used low-fragmentation-heap groups. | Proton-GE `patches/wine-hotfixes/pending/` |
| `patches/wine/0002-ntdll-srwlock-skip-needless-shared-release-wake.patch` | SRW locks: skip a wake-up with no waiter to serve. | Proton-GE `patches/wine-hotfixes/pending/` |
| `patches/wine/0003-ntdll-reserve-top-down-space-for-large-address-aware-wow64.patch` | Top-down address reservation for large-address-aware 32-bit games. | Proton-GE `patches/wine-hotfixes/pending/` |
| `patches/wine/0004-ntdll-keep-nvidia-dlss-address-range-free.patch` | Keeps the address range DLSS needs free. | Proton-GE `patches/wine-hotfixes/pending/` |
| `patches/wine/0005-server-keep-owned-ntsync-mutex-until-owner-releases-or-dies.patch` | NTSync: owned-mutex fix. | Proton-GE `patches/wine-hotfixes/pending/` |
| `patches/wine/0006-ntdll-read-qpc-from-the-tsc-in-user-mode.patch` | `QueryPerformanceCounter` from the TSC, without a system call. x86-64 build only. | Proton-GE `patches/proton/` |
| `patches/wine/0007-ntdll-only-read-kernel-clocksource-for-qpc-at-start-up.patch` | Reads the clocksource for 0006 once at start-up. x86-64 build only. | Proton-GE `patches/proton/` |
| `patches/wine/0008-kernel32-refresh-power-status-asynchronously.patch` | Power status polled asynchronously. | Proton-GE `patches/wine-hotfixes/pending/` |
| `patches/extras__low_latency_layer/0001-use-relative-library-path.patch` | Layer manifest uses a relative library path. | Proton-GE |
| `patches/extras__discord-rpc-bridge/0001-remove-darwin-syscall.patch` | Drops the bridge's macOS system call path. | Proton-GE (regenerated for `git apply`) |

All Wine patches apply in order to the Wine pin above (checked with
`git apply`); CI is the compile check. Proton-GE source commit for the Wine
patches: `2b270a204beb7379efd8357462d3baa301e9dacd`.

## ARM64 build

- Leaves out Wine patches 0006 and 0007 (`patches/x86_64-only.list`).
- No Discord bridge (it makes x86-64 Linux system calls).
- `scripts/prepare.sh --target-arch arm64` fetches FEX's release tags, which
  the base's FEX build needs for `git describe`.
- CI builds with `-g0` instead of the x86-64 CI's `-s`: the ARM64 SDK's clang
  rejects `-s` in compile checks.

## Reviewed and not taken

| Item | From | Why not |
|---|---|---|
| `VK_NV_low_latency2` (Reflex) Wine patch, FSR fullscreen upscaling patch | Proton-GE | Do not apply to Valve's Wine; adapting them would be a rewrite. gamescope provides FSR upscaling. |
| Wayland driver HDR | Proton-GE / Proton-EM | About 300 Wine patches written against GE's tree. HDR goes through gamescope. |
| ntdll futex-queue patches | proton-cachyos | The first GE-based build with them did not start a game; it did after they were removed. |
| Replacing stock DXVK / vkd3d-proton with the low-latency forks | proton-cachyos | Would change frame pacing for every game; kept opt-in. |
| `-O3 -mno-avx` and other compiler flags | proton-cachyos | No measured benefit in any source. |
| gplasync for DXVK | DW-Proton / proton-cachyos | Can cause visual glitches; its author warns against it with anti-cheat. |
| Anti-cheat workarounds | DW-Proton | Not carried. |
| mimalloc, mod-loader overrides, AMD ray-tracing auto-tuning, Wayland/HDR auto-detection, OptiScaler bundling | suggestions | Declined. |

## History

- Overlay on Valve `proton-11.0-2e`, then on Proton-GE `GE-Proton11-12`, then on
  Proton Experimental `experimental-11.0-20261105c` (releases `EX-Proton1-1` and
  `EX-Proton1-1-aarch64`). The overlay repository's history is on the
  `overlay-archive` branch.
- The Proton-GE base was dropped because its video backend made Crimson Desert's
  pre-rendered videos lag; Valve's does not.
- Now: a fork of Valve's Proton at `experimental-11.0-20261123b`. That tag
  takes ONNX Runtime from Valve's own server, so the overlay's ONNX Runtime
  workaround for the ARM64 build is gone.

## Licences

- Wine patches are derivative works of Wine: LGPL-2.1-or-later.
- Proton: Valve's BSD-style licence (`LICENSE.proton`).
- Nothing is vendored from Frogging-Family/wine-tkg-git (no licence file).
