First release of EX-Proton: Valve's Proton Experimental with a few Wine performance patches and optional low-latency components.

**Base:** ValveSoftware/Proton `experimental-11.0-20261105c`. Video playback is Valve's own (winegstreamer + GStreamer), unchanged.

## Added on top of Proton Experimental

- Eight Wine patches from Proton-GE: `QueryPerformanceCounter` from the TSC (two patches), heap block reuse, SRW lock wake-up fix, asynchronous power status, NTSync owned-mutex fix, top-down address reservation for large-address-aware games, DLSS address range.
- protonfixes (umu-protonfixes): per-game fixes, run automatically. `PROTONFIXES_DISABLE=1` turns it off.
- Optional switches, all off by default (set in the game's Steam launch options before `%command%`):

| Variable | Effect |
|---|---|
| `PROTON_DXVK_LOWLATENCY=1` | Low-latency DXVK build (D3D8-11). |
| `PROTON_VKD3D_LOWLATENCY=1` | Low-latency vkd3d-proton build (D3D12). Its author lists Intel GPUs, AMD Anti-Lag 2 and frame generation as unsupported. |
| `LOW_LATENCY_LAYER=1` | Korthos Vulkan low-latency layer. |
| `PROTON_FSR4_UPGRADE=1` | Downloads AMD's FSR4 DLL into the prefix at first launch and upgrades FSR 3.1 games to FSR4. |
| `PROTON_LOCAL_SHADER_CACHE=1` | Per-game shader cache, for use with Steam's shader pre-caching off. |

## Status

Tested by the maintainer in one game (Crimson Desert, AMD GPU): it launches and pre-rendered videos play smoothly. Nothing has been benchmarked; no performance or latency gain is claimed. Not every switch has been tested.

Not included: Proton-GE's FSR fullscreen upscaling, its Wayland/HDR work, and the NVIDIA Reflex Wine patch. gamescope provides HDR and FSR upscaling on this base.

## Install

Extract on the Linux machine with `tar` (not a graphical archive tool):

```
tar -xf EX-Proton1-1.tar.gz -C ~/.steam/root/compatibilitytools.d/
```

Restart Steam, then pick `EX-Proton1-1` under the game's Properties, Compatibility.

Sources and provenance of every component: see `PATCHES.md`. Requires the Steam Linux Runtime 4.0, like the base.
