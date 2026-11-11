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

## Patches (`patches/`)

None.

## Candidates under review

Changes from proton-cachyos, Proton-EM and DW-Proton that Proton-GE does not
already carry are being evaluated. Anything adopted is listed above with its
source, commit and verification status.

## History

- Earlier base: Valve `proton-11.0-2e` with 8 Wine patches from Proton-GE and
  the netborg-afps DXVK low-latency fork at its 2.7.1 release. That build
  compiled in CI but was replaced because Valve's base lacks GE's media stack.

## Licences

- Wine patches are derivative works of Wine: LGPL-2.1-or-later.
- Proton-GE: its `LICENSE` defers to `LICENSE.proton` (Valve's BSD-style
  licence).
- Nothing is vendored from Frogging-Family/wine-tkg-git (no licence file).
