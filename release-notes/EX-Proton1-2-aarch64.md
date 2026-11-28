ARM64 build of EX-Proton1-2, for ARM64 Linux machines. On a normal x86-64 PC, use [EX-Proton1-2](https://github.com/ethanxiang6/EX-Proton/releases/tag/EX-Proton1-2) instead.

**Untested.** This build compiles, but it has not been run on any ARM64 hardware. Treat it as experimental.

**Base:** ValveSoftware/Proton `experimental-11.0-20261123b`, built with Valve's own ARM64 target. Windows games are x86 / x86-64; they run through FEX (`FEX-2611-79`), which Valve's ARM64 Proton bundles. Expect lower CPU performance than on an x86-64 machine with similar hardware.

## Same as EX-Proton1-2, except

- No Discord bridge: it makes x86-64 Linux system calls, which do not work from translated code.
- The two `QueryPerformanceCounter`-from-TSC Wine patches are left out (x86-only CPU counter). The other six Wine patches are included.
- protonfixes and the optional switches `PROTON_DXVK_LOWLATENCY`, `PROTON_VKD3D_LOWLATENCY`, `LOW_LATENCY_LAYER`, `PROTON_FSR4_UPGRADE` and `PROTON_LOCAL_SHADER_CACHE` are included, all untested on ARM64.

## Requirements

- An ARM64 Linux machine running the ARM64 Steam client, with a working Vulkan driver for its GPU.
- It cannot be used by x86 Steam running under an emulator.
- Games with kernel-level or strict anti-cheat are unlikely to work.

## Install

On the ARM64 Linux machine, extract with `tar`:

```
tar -xf EX-Proton1-2-aarch64.tar.gz -C ~/.steam/root/compatibilitytools.d/
```

Restart Steam, then pick `EX-Proton1-2-aarch64` under the game's Properties, Compatibility.

Sources and provenance of every component: see `PATCHES.md`.
