# EX-Proton: what is integrated and where it comes from

Nothing listed here has been benchmarked. "Builds" means the CI build completed;
it does not mean the change was tested in a game.

## Base

| Item | Pin |
|---|---|
| Upstream tree | ValveSoftware/Proton tag `experimental-11.0-20261105c`, commit `0764d2920a128cee74555afcab0819919ddf416d` (Proton Experimental) |
| Wine | ValveSoftware/wine `e8ca5806eec488f5916e83d655ffc5349b6b1702` (that tag's pin) |
| DXVK / vkd3d-proton | `cf0a0d90f8965147741ad17dcd0b263817572ab3` / `563eb6caaa8fb1386cbc629e7527c6522f5bfde8` (that tag's pins) |
| Build SDK | steamrt4, from the base's `Makefile.in` |

Video playback (Media Foundation, codecs) is the base's own winegstreamer +
GStreamer stack and is not touched here.

## Overrides (`overrides.conf`)

None enabled.

## Extra source trees (`extras.conf`)

Built beside the stock components and off unless the environment variable is
set for a game.

| Path | Source | Enabled with | Notes |
|---|---|---|---|
| `extras/dxvk-low-latency` | https://github.com/netborg-afps/dxvk-low-latency `d533db09df35453ed1baa1b0c7d86de2b67bf504` (release "3.1.1-low-latency"). Zlib. | `PROTON_DXVK_LOWLATENCY=1` | D3D8-11. Low-latency frame pacing is this fork's default mode. Also sets `dxvk.numCompilerThreads` to leave two cores free (one on 3-4 core machines), as proton-cachyos does. |
| `extras/vkd3d-low-latency` | https://github.com/netborg-afps/vkd3d-low-latency `f4e0518cdd35fee0629e25367422bcbc17cbc122`. LGPL-2.1. | `PROTON_VKD3D_LOWLATENCY=1` | D3D12. Its README lists Intel GPUs, AMD Anti-Lag 2 and frame generation as unsupported. |

| `extras/low_latency_layer` | https://github.com/Korthos-Software/low_latency_layer `4e7fe12b797d89be07919acf3d2df5cda3f4d89f` (Proton-GE's pin). MIT. | `LOW_LATENCY_LAYER=1` | Vulkan implicit layer. `patches/extras__low_latency_layer/0001-use-relative-library-path.patch` is Proton-GE's patch for it. |
| `extras/Vulkan-Utility-Libraries` | https://github.com/KhronosGroup/Vulkan-Utility-Libraries `b538fb5b08513aa78346cd414ad5e576a2a3e920` (Proton-GE's pin). Apache-2.0. | build-time only | Needed to build the layer; not shipped. |
| `extras/Vulkan-Headers-layer` | https://github.com/KhronosGroup/Vulkan-Headers `36872f9062b17b1a30b8ed1d81ca5ea6bb608a72` (Proton-GE's pin). Apache-2.0 / MIT. | build-time only | Newer headers than the base pins, used only to build the layer. |
| `extras/protonfixes` | https://github.com/open-wine-components/umu-protonfixes `28a02c25e4b895131c9ebdeda411ec3646b38151` (Proton-GE's pin, without GE's three patches to it). BSD-2-Clause. | always on (`PROTONFIXES_DISABLE=1` disables) | Per-game fixes, bundled winetricks. With `PROTON_FSR4_UPGRADE=1` it downloads AMD's `amdxcffx64.dll` at run time (URL list from `loathingkernel.github.io/proton-upscalers`) and sets `FSR4_UPGRADE=1` for the base Wine's own `amdxc64`. Its DLSS / XeSS / OptiScaler upgrades need Wine patches this build does not have and are not wired up. |

Latency benefits are the fork author's claims; nothing has been measured here.

## Patches (`patches/`)

The Wine patches are taken unchanged from Proton-GE
(GloriousEggroll/proton-ge-custom, commit `2b270a204beb7379efd8357462d3baa301e9dacd`;
the source paths below are inside that repository). All apply with `git apply`
to the Wine pin above, in this order. Apply-checked; CI is the compile check.

| File | What it does | Source in Proton-GE |
|---|---|---|
| `patches/wine/0001-ntdll-reuse-free-blocks-of-partially-used-lfh-groups.patch` | Heap: reuse free blocks of partially used low-fragmentation-heap groups. | `patches/wine-hotfixes/pending/ntdll-heap-reuse-free-blocks-of-partially-used-lfh-groups.patch` |
| `patches/wine/0002-ntdll-srwlock-skip-needless-shared-release-wake.patch` | SRW locks: skip a wake-up that has no waiter to serve. | `patches/wine-hotfixes/pending/ntdll-srwlock-skip-needless-shared-release-wake.patch` |
| `patches/wine/0003-ntdll-reserve-top-down-space-for-large-address-aware-wow64.patch` | Top-down address reservation for large-address-aware 32-bit games. | `patches/wine-hotfixes/pending/ntdll-reserve-top-down-space-for-large-address-aware-wow64.patch` |
| `patches/wine/0004-ntdll-keep-nvidia-dlss-address-range-free.patch` | Keeps the address range DLSS needs free. | `patches/wine-hotfixes/pending/ntdll-keep-nvidia-dlss-address-range-free.patch` |
| `patches/wine/0005-server-keep-owned-ntsync-mutex-until-owner-releases-or-dies.patch` | NTSync: fix for owned mutexes. | `patches/wine-hotfixes/pending/server-keep-owned-ntsync-mutex-until-owner-releases-or-dies.patch` |
| `patches/wine/0006-ntdll-read-qpc-from-the-tsc-in-user-mode.patch` | `QueryPerformanceCounter` read from the TSC in user mode (no system call). | `patches/proton/0001-ntdll-Read-QueryPerformanceCounter-from-the-TSC-in-us.patch` |
| `patches/wine/0007-ntdll-only-read-kernel-clocksource-for-qpc-at-start-up.patch` | Reads the kernel clocksource for the above once at start-up. Needs 0006. | `patches/proton/0002-ntdll-Only-read-the-kernel-clocksource-for-QPC-at-start-up.patch` |
| `patches/wine/0008-kernel32-refresh-power-status-asynchronously.patch` | Power status polled asynchronously, so games that query it every frame do not block. | `patches/wine-hotfixes/pending/kernel32-refresh-power-status-asynchronously.patch` |

| File | What it does | Source |
|---|---|---|
| `patches/proton/0001-ex-proton-optional-low-latency-dxvk-and-vkd3d-builds.patch` | Build rules for the two extra trees (`extras/build-*.mk`, mirroring the stock DXVK / vkd3d-proton rules) and the launcher-script switches. | this repository |
| `patches/proton/0002-ex-proton-write-build-name-into-version-file.patch` | Writes the build name into the `version` file (the base's `git describe` yields nothing in this overlay build). | this repository |
| `patches/proton/0003-ex-proton-protonfixes-low-latency-layer-fsr4.patch` | Build rules for protonfixes and the low-latency layer (following Proton-GE's) and the launcher hooks for them and `PROTON_FSR4_UPGRADE`. A protonfixes error is logged and never stops the launch. | this repository |

## Reviewed and not taken

| Item | From | Why not |
|---|---|---|
| `VK_NV_low_latency2` (Reflex) Wine patch, FSR fullscreen upscaling patch | Proton-GE | Do not apply to Valve's Wine; adapting them would be a rewrite. gamescope provides FSR upscaling outside Wine. |
| Wayland driver HDR (`PROTON_ENABLE_WAYLAND` / `PROTON_ENABLE_HDR`) | Proton-GE / Proton-EM | About 300 Wine patches written against GE's tree. On this base HDR goes through gamescope with `DXVK_HDR=1`. |
| ntdll futex-queue patches (adaptive spinlock, 1024 queues, hashed queue selection) | proton-cachyos | Carried in the first GE-based build, which did not start a game; the build started one after they were removed. Cause not otherwise confirmed. |
| Replacing the stock DXVK / vkd3d-proton outright with the low-latency forks | proton-cachyos | Would change frame pacing for every game. Taken as opt-in extras instead. |
| `-O3 -mno-avx` and other compiler flag changes | proton-cachyos | No measured benefit in any source. |
| gplasync (asynchronous shader compilation) for DXVK | DW-Proton / proton-cachyos | Can cause visual glitches and its author warns against use in games with anti-cheat. |
| Anti-cheat driver emulation, signature and connection workarounds | DW-Proton | Not carried. |
| mimalloc, mod-loader overrides, AMD ray-tracing auto-tuning, Wayland/HDR auto-detection, OptiScaler bundling | suggestions | Declined. |

## History

- `95893dd`: Valve `proton-11.0-2e` with the eight Wine patches and a DXVK
  low-latency override. Compiled; replaced to get Proton-GE's media stack.
- Proton-GE `GE-Proton11-12` base: started games once the futex patches were
  removed, but pre-rendered video in Crimson Desert was laggy (GE replaced
  Valve's GStreamer video path with its own FFmpeg-based one). Two video
  threading patches written here did not fix it.
- Current: Proton Experimental, whose video path plays those videos smoothly.

## Licences

- Wine patches are derivative works of Wine: LGPL-2.1-or-later.
- Proton: Valve's BSD-style licence (`proton/LICENSE.proton`).
- Nothing is vendored from Frogging-Family/wine-tkg-git (no licence file).
