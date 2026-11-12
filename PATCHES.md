# EX-Proton: what is integrated and where it comes from

Nothing listed here has been benchmarked. "Builds" means the CI build completed;
it does not mean the change was tested in a game.

## Base

| Item | Pin |
|---|---|
| Upstream tree | GloriousEggroll/proton-ge-custom tag `GE-Proton11-12`, commit `f85547f0ea51ac356ab42b4de57b927b0044cc85` |
| Components | Whatever that tag pins as submodules (Valve bleeding-edge Wine + wine-staging, DXVK, vkd3d-proton, dxvk-nvapi, FFmpeg, GStreamer, protonfixes, ...) |
| GE patch set | Applied by the base's own `patches/protonprep-valve-staging.sh`, run by `scripts/prepare.sh` |
| Build SDK | steamrt4, from the base's `Makefile.in` |

## What the base already provides

These come from Proton-GE and need nothing from this repository:

- Media: FFmpeg built with decoders, encoders and demuxers enabled, and GE's
  Media Foundation / DirectShow rework (`patches/ge-video-rework/`).
- Sync: fsync and NTSync (`PROTON_NO_NTSYNC` disables), including GE's NTSync
  mutex fixes.
- The eight Wine patches EX-Proton carried on its earlier Valve base (LFH block
  reuse, SRW lock wake, LAA top-down reservation, DLSS address range, NTSync
  owned-mutex fix, QPC from TSC, QPC clocksource at start-up, asynchronous power
  status). GE's prep script applies all of them, so they were dropped here.
- The patches that did not apply to Valve's stable Wine earlier: FSR fullscreen
  upscaling, `VK_NV_low_latency2` (Reflex), the rest of the NTSync mutex series.
- A Vulkan low-latency layer (`LOW_LATENCY_LAYER`, see the base's README).
- Wayland driver and HDR (`PROTON_ENABLE_WAYLAND`, `PROTON_ENABLE_HDR`),
  protonfixes, and the DLSS / FSR4 / XeSS upgrade switches.

## Overrides (`overrides.conf`)

None enabled.

## Extra source trees (`extras.conf`)

Built beside the stock components and off unless the environment variable is
set for a game. The side-by-side approach is the one proton-cachyos and
DW-Proton use; both pin the same two commits.

| Path | Source | Enabled with | Notes |
|---|---|---|---|
| `extras/dxvk-low-latency` | https://github.com/netborg-afps/dxvk-low-latency `d533db09df35453ed1baa1b0c7d86de2b67bf504` (release "3.1.1-low-latency", 2026-09-24). Zlib. | `PROTON_DXVK_LOWLATENCY=1` | D3D8-11. Low-latency frame pacing is this fork's default mode. It is 153 commits behind the DXVK that GE pins, which is why it is opt-in rather than a replacement. Also sets `dxvk.numCompilerThreads` to leave two cores free (one on 3-4 core machines), as proton-cachyos does. |
| `extras/vkd3d-low-latency` | https://github.com/netborg-afps/vkd3d-low-latency `f4e0518cdd35fee0629e25367422bcbc17cbc122` (2026-10-02). LGPL-2.1. | `PROTON_VKD3D_LOWLATENCY=1` | D3D12. Its README lists Intel GPUs, AMD Anti-Lag 2 and frame generation as unsupported. GE's three vkd3d-proton patches are not applied to it (one of them does not apply to this fork). |

Latency benefits are the fork author's claims; nothing has been measured here.

## Patches (`patches/`)

Applied after Proton-GE's own patch script.

| File | What it does | Source | Check |
|---|---|---|---|
| `patches/wine/0001-winedmo-thread-hevc-vp9-av1-decoders.patch` | GE's video backend (winedmo + FFmpeg) decodes only H.264 multi-threaded; HEVC, VP9 and AV1 used one thread. Gives them the same bounded thread count. Aimed at slow pre-rendered video that plays smoothly on Valve's Proton. | this repository (one-line change to the code added by GE's `ge-video-rework/0076`) | Not confirmed to fix any game: which codec the affected videos use is unknown. |
| `patches/proton/0001-ex-proton-optional-low-latency-dxvk-and-vkd3d-builds.patch` | Adds build rules for the two extra trees above (`extras/build-*.mk`, modelled on the stock DXVK / vkd3d-proton rules and proton-cachyos' extras) and the launcher-script switches. Written for EX-Proton. | this repository | Applies with `git apply` to the base tree. |

## Reviewed and not taken

From the comparison of proton-cachyos (`cachyos_11.0_20261014`), Proton-EM
(`em-11`) and DW-Proton (`dwproton-11.0-16`) against GE-Proton11-12:

| Item | From | Why not |
|---|---|---|
| Wayland driver, HDR, FSR4/MLFG, keyboard and input work | Proton-EM | Already in the base: GE imports it as about 300 patches. |
| NtDelayExecution via QPC, `WINE_ENABLE_HARDWARE_SCHEDULING`, avoiding `CLOCK_REALTIME_COARSE`, top-down allocation for LAA | proton-cachyos / Proton-EM | Already in the base (GE's `wine-wayland/0163`, `0143`, `0082` and `pending/`). |
| Replacing GE's DXVK / vkd3d-proton outright with the low-latency forks | proton-cachyos | Would change pacing for every game and drop GE's newer commits; one GE vkd3d patch does not apply to the fork. Taken as opt-in extras instead. |
| Small Wayland-only fixes newer than GE's import (leak fixes, popup guard, a keyboard layout fix, FSR4 init-once) | Proton-EM | Low value for the goals here and not checkable against GE's heavily patched Wayland driver without a build. Candidates for later. |
| `-O3 -mno-avx` and other compiler flag changes | proton-cachyos | No measured benefit in any source. |
| gplasync (asynchronous shader compilation) for DXVK | DW-Proton / proton-cachyos | Can cause visual glitches and its author warns against use in games with anti-cheat. |
| Anti-cheat driver emulation, signature and connection workarounds | DW-Proton | Not carried. |
| GStreamer-path media patches | DW-Proton / proton-cachyos | GE replaced that media backend. |
| ntdll futex-queue patches (adaptive spinlock, 1024 queues, hashed queue selection; wine-cachyos `3653b6d3`, `276ba28d`, `324f95f1`) | proton-cachyos | Carried in the first GE-based build, which did not start a game that official GE-Proton11-12 starts. They were the only always-on run-time difference from GE, so they were removed. Not proven to be the cause. |
| `low_latency_layer` one-commit bump, vkBasalt patches, dxvk-sarek, ZLUDA, PipeWire driver, game-specific protonfixes | various | Little or no bearing on the goals here. |

## History

- Earlier base: Valve `proton-11.0-2e` with 8 Wine patches from Proton-GE and
  the netborg-afps DXVK low-latency fork at its 2.7.1 release. That build
  compiled in CI but was replaced because Valve's base lacks GE's media stack.

## Licences

- Wine patches are derivative works of Wine: LGPL-2.1-or-later.
- Proton-GE: its `LICENSE` defers to `LICENSE.proton` (Valve's BSD-style
  licence).
- Nothing is vendored from Frogging-Family/wine-tkg-git (no licence file).
