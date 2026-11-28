EX-Proton is now a fork of Valve's Proton, updated to the newest Proton Experimental, with Discord Rich Presence support.

**Untested.** This build compiles, but it has not been run in a game yet. If something breaks, [EX-Proton1-1](https://github.com/ethanxiang6/EX-Proton/releases/tag/EX-Proton1-1) is the last tested release.

**Base:** ValveSoftware/Proton `experimental-11.0-20261123b` (newer Wine, DXVK, vkd3d-proton and FEX than 1-1). Video playback is Valve's own, unchanged.

## New in 1-2

- **Discord:** games with Discord Rich Presence can now reach the Linux Discord client (also Flatpak, Snap and Vesktop). On by default; start Discord before the game. `PROTON_DISCORD_BRIDGE=0` turns it off. For games without Rich Presence, Discord's "Playing ..." status comes from Discord's own process detection; adding the game under Discord's Registered Games helps.
- **Newer base:** Proton Experimental `20261123b` instead of `20261105c`.
- **Repository:** EX-Proton is now a direct fork of Valve's Proton (Valve's history plus EX-Proton's commits) instead of a patch overlay.

## Same as 1-1

- Eight Wine performance patches from Proton-GE (faster `QueryPerformanceCounter`, heap and lock fixes, NTSync mutex fix, DLSS address range, asynchronous power status).
- protonfixes, run automatically (`PROTONFIXES_DISABLE=1` turns it off).
- Optional switches, off by default (in the game's Steam launch options, before `%command%`):

| Variable | Effect |
|---|---|
| `PROTON_DXVK_LOWLATENCY=1` | Low-latency DXVK build (D3D8-11). |
| `PROTON_VKD3D_LOWLATENCY=1` | Low-latency vkd3d-proton build (D3D12). Its author lists Intel GPUs, AMD Anti-Lag 2 and frame generation as unsupported. |
| `LOW_LATENCY_LAYER=1` | Korthos Vulkan low-latency layer. |
| `PROTON_FSR4_UPGRADE=1` | Downloads AMD's FSR4 DLL into the prefix at first launch and upgrades FSR 3.1 games to FSR4. |
| `PROTON_LOCAL_SHADER_CACHE=1` | Per-game shader cache, for use with Steam's shader pre-caching off. |

Nothing has been benchmarked; no performance or latency gain is claimed. HDR and fullscreen FSR upscaling go through gamescope.

## Install

Extract on the Linux machine with `tar` (not a graphical archive tool):

```
tar -xf EX-Proton1-2.tar.gz -C ~/.steam/root/compatibilitytools.d/
```

Restart Steam, then pick `EX-Proton1-2` under the game's Properties, Compatibility. It appears beside 1-1 as a separate tool.

Sources and provenance of every component: see `PATCHES.md`.
