ARM64 build of EX-Proton1-1, for ARM64 Linux machines. Published separately from the x86-64 release; on a normal x86-64 PC, use [EX-Proton1-1](https://github.com/ethanxiang6/EX-Proton/releases/tag/EX-Proton1-1) instead.

**Untested.** This build compiles, but it has not been run on any ARM64 hardware. Treat it as experimental.

**Base:** ValveSoftware/Proton `experimental-11.0-20261105c`, built with Valve's own ARM64 target (`--target-arch=arm64`). Windows games are x86 / x86-64; they run through FEX, the x86-to-ARM translator that Valve's ARM64 Proton bundles. Expect lower CPU performance than on an x86-64 machine with similar hardware.

## Same as EX-Proton1-1, except

- The two `QueryPerformanceCounter`-from-TSC Wine patches are left out: they read an x86-only CPU counter. The other six Wine patches are included.
- Everything else matches the x86-64 release: protonfixes, and the optional switches `PROTON_DXVK_LOWLATENCY`, `PROTON_VKD3D_LOWLATENCY`, `LOW_LATENCY_LAYER`, `PROTON_FSR4_UPGRADE` and `PROTON_LOCAL_SHADER_CACHE`. None of them has been tested on ARM64.

## Requirements

- An ARM64 Linux machine running the ARM64 Steam client, with a working Vulkan driver for its GPU.
- It cannot be used by x86 Steam running under an emulator.
- Games with kernel-level or strict anti-cheat are unlikely to work.

## Install

On the ARM64 Linux machine, extract with `tar` (not a graphical archive tool):

```
tar -xf EX-Proton1-1-aarch64.tar.gz -C ~/.steam/root/compatibilitytools.d/
```

Restart Steam, then pick `EX-Proton1-1-aarch64` under the game's Properties, Compatibility.

Sources and provenance of every component: see `PATCHES.md`.
