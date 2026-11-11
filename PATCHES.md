# EXProton patch provenance

Nothing listed here has been built or benchmarked. The only check performed is `git apply --check` (in series) against the pinned upstream trees. A clean apply does not prove that the result compiles or helps.

## Base

| Item | Pin |
|---|---|
| Proton | ValveSoftware/Proton tag `proton-11.0-2e`, commit `bc896217ffcd67f892f952b010f898fe7bd0f0a1` |
| wine | ValveSoftware/wine `e60892cc2398b0a83c332a2078c7b85e47bdb42b` |
| dxvk | doitsujin/dxvk `a6764047e587178283fcde4073ae6e1410af594f` (meson version 2.7.1; 498 commits after tag v2.7.1) |
| vkd3d-proton | HansKristian-Work/vkd3d-proton `212991fc2c266bc0d59f4c4ce8f80f7126508d71` (meson version 3.0) |
| dxvk-nvapi | jp7677/dxvk-nvapi `f9fdf268e888d17ae9875a4f01908164ff05f740` |
| Build SDK | steamrt4 `registry.gitlab.steamos.cloud/proton/steamrt4/sdk/x86_64:4.0.20260331.220802-0` (from `proton/Makefile.in`) |

## Integrated

All are Wine patches in `patches/wine/` (applied with `git apply` -p1 inside `proton/wine`, in this order).
Source repo for every row: https://github.com/GloriousEggroll/proton-ge-custom at master commit `2b270a204beb7379efd8357462d3baa301e9dacd` (fetched as raw bytes with curl from raw.githubusercontent.com at that commit; each file's `git hash-object` equals the blob SHA GitHub reports for the upstream path, so the bytes are unmodified).
Verification status for every row: applies cleanly; not built, not benchmarked.

| File (patches/wine/) | What it does | Goal | Upstream path in source repo | Enabled |
|---|---|---|---|---|
| `0001-ntdll-reuse-free-blocks-of-partially-used-lfh-groups.patch` | Low Fragmentation Heap reuses free blocks of partly used groups instead of growing the heap (WineHQ bug 60589, MR 12472). | performance (memory growth) | `patches/wine-hotfixes/pending/ntdll-heap-reuse-free-blocks-of-partially-used-lfh-groups.patch` | always on |
| `0002-ntdll-srwlock-skip-needless-shared-release-wake.patch` | `RtlReleaseSRWLockShared` no longer takes the futex queue lock when there are no exclusive waiters. Its commit message cites a perf profile of MSFS 2024; not reproduced here. | performance | `patches/wine-hotfixes/pending/ntdll-srwlock-skip-needless-shared-release-wake.patch` | always on |
| `0003-ntdll-reserve-top-down-space-for-large-address-aware-wow64.patch` | Reserves top-down address space for large-address-aware WoW64 processes (WineHQ bug 58698; by Alexandre Julliard). | compatibility (address space) | `patches/wine-hotfixes/pending/ntdll-reserve-top-down-space-for-large-address-aware-wow64.patch` | acts on LAA processes; Proton enables LAA by default (`PROTON_FORCE_LARGE_ADDRESS_AWARE`, disabled by `noforcelgadd`) |
| `0004-ntdll-keep-nvidia-dlss-address-range-free.patch` | Keeps 0x200000000-0x300200000 free so the NVIDIA driver can map what DLSS needs when bottom-up allocation is in use. | compatibility (DLSS) | `patches/wine-hotfixes/pending/ntdll-keep-nvidia-dlss-address-range-free.patch` | always on (64-bit); only matters with bottom-up allocation |
| `0005-server-keep-owned-ntsync-mutex-until-owner-releases-or-dies.patch` | Abandons an ntsync mutex whose handle was closed while owned, instead of leaving waiters blocked forever. | compatibility / stability under NTSync | `patches/wine-hotfixes/pending/server-keep-owned-ntsync-mutex-until-owner-releases-or-dies.patch` | active when ntsync is in use (`PROTON_NO_NTSYNC` documented in proton README to turn it off) |
| `0006-ntdll-read-qpc-from-the-tsc-in-user-mode.patch` | `QueryPerformanceCounter` served from the TSC in user mode when the kernel clocksource is TSC (commit message reports 39 -> 62 FPS in DCS World; not reproduced here). | performance | `patches/proton/0001-ntdll-Read-QueryPerformanceCounter-from-the-TSC-in-us.patch` | always on; `WINE_DISABLE_QPC_TSC=1` disables, `WINE_ENABLE_QPC_TSC=1` forces |
| `0007-ntdll-only-read-kernel-clocksource-for-qpc-at-start-up.patch` | Follow-up to 0006: read the kernel clocksource only at start-up (avoids re-entering hooked file I/O; Persona 5 Royal mod crash). Must stay after 0006. | compatibility | `patches/proton/0002-ntdll-Only-read-the-kernel-clocksource-for-QPC-at-start-up.patch` | always on, same env vars as 0006. Upstream says this change alone has not been runtime-tested. |
| `0008-kernel32-refresh-power-status-asynchronously.patch` | `GetSystemPowerStatus` returns a cached snapshot refreshed on a worker, so slow sysfs battery reads no longer stall the calling thread (Diablo IV stalls on a handheld). Includes a test. | stutter | `patches/wine-hotfixes/pending/kernel32-refresh-power-status-asynchronously.patch` | always on |

Notes:
- GE's `protonprep-valve-staging.sh` runs `patch -Np1` for every patch (including the ones in its `patches/proton/` directory) inside the `wine` directory, so those two QPC patches belong under `patches/wine/` here.
- 0005's commit message refers to an earlier Wine commit (934514db7c2, "server: Keep owned mutex syncs alive until abandoned"). That commit is an ancestor of our wine pin (checked with `git merge-base --is-ancestor`), and the patch only touches `server/inproc_sync.c`, so it stands on its own. Its companion patch (below) was rejected, so only the first half of GE's mutex fix is present: a mutex closed while owned is covered, a mutex closed while merely in use is not.
- CI only: `.github/patches/0001-build-strip-binaries-early.patch` changes `-ggdb` to `-s` in Proton's `Makefile.in` to save runner disk. It is our own one-line patch against the 11.0-2e `Makefile.in`, equivalent to Proton-GE's `.github/patches/0001-build-strip-binaries-early.patch` (GE's file itself does not apply to this base). The workflow applies it; `scripts/prepare.sh` does not, so local builds keep debug info.

## Overrides (`overrides.conf`)

| Submodule | Fork / commit | State | Fork base vs ours | Note |
|---|---|---|---|---|
| `dxvk` | https://github.com/netborg-afps/dxvk-low-latency `0ccdd368e9117fa6c67d4d6edc5319573c84ddd9` (tag `low-latency-framepacing-2.7.1-3-521`, 2026-04-01) | **enabled** | fork reports 2.7.1, ours is 2.7.1 (+498 commits). Common ancestor is upstream master of 2026-02-09 (`3731c2f`); our pin has 47 commits the fork lacks, the fork has 135. | Low-latency frame pacing is the fork's default (per its README), so this changes D3D9/10/11 behaviour for every title; the README says `dxvk.framePace = "max-frame-latency"` with `dxvk.latencySleep = Auto` restores upstream behaviour. Its `subprojects/dxbc-spirv` gitlink (`ca8e29e`) differs from our pin's (`fe5a4ef`). Other nested submodules (Vulkan-Headers, SPIRV-Headers, libdisplay-info, mingw-directx-headers) have the same commits as our pin. Licence Zlib. Not built. Comment this line out if a build fails or always-on pacing is unwanted. |
| `vkd3d-proton` | https://github.com/netborg-afps/vkd3d-low-latency `f4e0518cdd35fee0629e25367422bcbc17cbc122` (tag `low-latency-3.0.1-2`, 2026-10-02; the commit CachyOS pins) | commented out | fork meson version 3.1.0, ours 3.0; 499 commits past common ancestor `c8c8ab5` (2026-04-10), our pin is 6 commits past it. All fork releases checked (initial-release 285 commits, 3.0.1-2, 3.1, 3.1-2) are on the 3.1.0 line. | No fork release on our 3.0 line exists. Licence LGPL-2.1. |
| `dxvk` (alternative) | same repo, `d533db09df35453ed1baa1b0c7d86de2b67bf504` (CachyOS' pin) | commented out | fork reports 3.1.1 vs our 2.7.1 | Major-version jump. |

How CachyOS wires these (branch `cachyos_11.0_20261001/main`, commit `cffffad374a5ed5b40ebe3aea6d6c2b5a0cfed23`): they are separate submodules `extras/dxvk-low-latency` and `extras/vkd3d-low-latency`, built beside stock DXVK/vkd3d-proton (`extras/build-*-low-latency.mk`, included from `Makefile.in`), and selected at run time by `PROTON_DXVK_LOWLATENCY` / `PROTON_VKD3D_LOWLATENCY` in the `proton` script. EXProton's layout has no side-by-side mechanism, so the override replaces the stock component instead (see Deferred).

## Rejected (did not apply)

Each was tested with `git apply --cached --check` on the pinned tree (in series, and again alone against the pristine pin where noted). All fail because GE's patches are written against GE's already-patched Wine (or vkd3d-proton) tree; the missing context was not reconstructed (no hand-rebasing).

| Upstream path (GE master `2b270a2`) | Error |
|---|---|
| `patches/wine-hotfixes/pending/ntdll-remove-redundant-packed-split-lock.patch` | `error: patch failed: dlls/ntdll/unix/loader.c:2244` / `patch does not apply` (also fails on pristine pin) |
| `patches/wine-hotfixes/pending/ntdll-take-in-flight-alert-when-wait-on-address-times-out.patch` | `error: patch failed: dlls/ntdll/sync.c:915` / `patch does not apply` (also fails on pristine pin) |
| `patches/wine-hotfixes/pending/server-keep-in-process-mutex-closed-while-in-use.patch` | `error: patch failed: server/protocol.def:4558` (alone on the pin: also `server/inproc_sync.c:107`) |
| `patches/proton/0001-fshack-Implement-AMD-FSR-upscaler-for-fullscreen-hac.patch` | `error: patch failed: dlls/win32u/sysparams.c:2335`, `error: patch failed: dlls/win32u/vulkan.c:43` |
| `patches/proton/83-nv_low_latency_wine.patch` (VK_NV_low_latency2) | `error: patch failed: dlls/win32u/vulkan.c:2975`, `error: patch failed: include/wine/vulkan_driver.h:222`. It builds on the FSR patch above, which is also rejected. |
| `patches/wine-hotfixes/pending/ntdll-free-teb-and-stacks-of-killed-threads.patch` | `error: patch failed: dlls/ntdll/unix/unix_private.h:118` (also fails on pristine pin) |
| GE `patches/vkd3d-proton/0001-vkd3d-bound-present-waits-during-swapchain-drain.patch` (checked against vkd3d-proton pin) | `error: patch failed: libs/vkd3d/swapchain.c:543` |

Applied cleanly but deliberately excluded, because they only test a fix that was rejected:
`ntdll-tests-wait-on-address-wake-racing-timeout.patch` (tests the rejected WaitOnAddress fix), `kernel32-tests-abandon-mutex-acquired-after-close.patch` (tests the rejected in-process mutex patch), `kernel32-tests-killed-thread-stack-freed.patch` (tests the rejected TEB patch).

## Deferred (not attempted or not included)

| Item | Reason |
|---|---|
| wine-staging wholesale | Too large to verify without a build. |
| Wayland driver set (GE `wine-wayland`, `winewayland-*`, wineland child rendering) | Too large to verify without a build. |
| Game-specific patches (GE `game-patches`, Le Mans Ultimate, Helldivers/Diablo/Forza/Path of Exile/Hades items, etc.) | Out of scope. |
| Anti-cheat stubs and host-block hacks (`wine_host_block_envvar.patch`, EAC related) | Out of scope. |
| protonfixes / umu integration | Too large to verify without a build. |
| Other GE `wine-hotfixes/pending` patches not named in this file (crypt32, d2d1, secur32, winebus, winepulse, winex11, ws2_32, etc.) | Not stutter/latency/perf; not evaluated. |
| `ntdll-block-apcs-until-process-exit-state-is-set`, `ntdll-retry-native-view-allocation-with-effective-range`, `rtworkq-dont-hold-queues-section...`, `xinput-dont-wait-for-update-thread-under-loader-lock`, `win32u-release-images-presented-to-hidden-windows`, `win32u-share-*-cursors-*` | Single-game or Wayland-specific compatibility fixes, not perf/latency; downloaded and read but not included, not applied in series. |
| GE `patches/proton/` HACK patches (OptiScaler, Streamline redirect, DLSS/XeSS overrides) | Not perf; not evaluated. |
| GE `patches/dxvk/*` (fullscreen focus, HDR, StarCraft II, overlay) | Built against GE's newer DXVK and mostly game-specific; not tested against our DXVK pin (and the enabled DXVK override would change the base anyway). |
| GE `patches/low_latency_layer` and `vklayers/low_latency_layer` (Vulkan layer) | Needs a submodule not in Proton 11.0 plus Makefile integration; cannot be verified without a build. |
| Side-by-side low-latency DXVK/vkd3d with `PROTON_DXVK_LOWLATENCY` / `PROTON_VKD3D_LOWLATENCY` (CachyOS `Makefile.in`, `extras/*.mk`, `proton` script) | Requires new submodules, build rules and a `proton` script edit; CachyOS carries these as direct commits, not as small patches, so no `patches/proton/` patch exists and writing one would mean hand-authoring hunks. |
| `patches/proton/` (top-level Proton tree) | No GE or CachyOS file exists as a patch against the Proton root, so nothing was checked with `git -C proton apply --check`. |
| Frogging-Family/wine-tkg-git equivalents (e.g. TKG's sync/timing/fsync-related patches) | not vendored (no licence). |

## Already in the base (nothing to patch)

Verified in the `proton` checkout at `proton-11.0-2e`:

- **fsync**: `proton` script sets `WINEFSYNC=1` unless `nofsync` is in the compat config (line ~1781). `PROTON_NO_FSYNC` is read there and documented in `README.md` (line 325).
- **esync**: obsolete in Proton 11.0 per `README.md` line 347 (`PROTON_NO_ESYNC` "Obsoleted in Proton 11.0"); the `proton` script still adds `noesync` for some app IDs.
- **NTSync**: `README.md` line 326 documents `PROTON_NO_NTSYNC` ("Do not use ntsync"). The `proton` script has no `ntsync` string; `vrclient_x64/unix_vrapplications_manual.cpp:39` lists the variable. I did not trace where Wine consumes it (Wine submodule not initialised), so only the documented option is confirmed.
- **Large address aware default**: `proton` script (line ~1547-1549) adds `forcelgadd` unless `noforcelgadd`, and sets `WINE_LARGE_ADDRESS_AWARE=1`; `README.md` line 330 says "Enabled by default".
- **DXVK graphics pipeline library**: not visible in the proton checkout (grep of `proton`, `README.md`, `Makefile.in` finds nothing; DXVK is an uninitialised submodule). Checked instead at the pinned DXVK commit: `src/dxvk/dxvk_options.cpp` reads `dxvk.enableGraphicsPipelineLibrary` as a Tristate defaulting to Auto, and `dxvk.conf` lists `# dxvk.enableGraphicsPipelineLibrary = Auto`. Note that the enabled DXVK override replaces this tree; I did not re-check the fork.

## Verification

Command (run from a blobless no-checkout clone of ValveSoftware/wine outside this repo, with a scratch index):

```
git read-tree e60892cc2398b0a83c332a2078c7b85e47bdb42b
# for each file in patches/wine in lexicographic order:
git apply --cached --check <patch> ; git apply --cached <patch>
```

Result: all 8 patches pass in order with 0 failures (final cumulative diff touches 7 files, +521/-30). No dxvk or vkd3d-proton patches are included, so none were checked beyond the rejected vkd3d-proton one above. Not built, not benchmarked.

## Licences

- Wine patches are derivative works of Wine and are LGPL-2.1-or-later (https://gitlab.winehq.org/wine/wine/-/blob/master/LICENSE). Authors are noted in each patch header (e.g. Alexandre Julliard, Grigory Romodanovskiy, Sebastian Matkovich, Haeris31, Jason Eggleston, GloriousEggroll).
- GE's repo (https://github.com/GloriousEggroll/proton-ge-custom): its `LICENSE` defers to `LICENSE.proton`, a Valve BSD-style licence (the GitHub API reports `NOASSERTION`, so the BSD-3-Clause identification rests on reading that file). Patch contents keep the licence of the code they modify.
- DXVK fork https://github.com/netborg-afps/dxvk-low-latency: Zlib. vkd3d fork https://github.com/netborg-afps/vkd3d-low-latency: LGPL-2.1 (as reported by GitHub).
- CachyOS reference: https://github.com/CachyOS/proton-cachyos (no files vendored from it).
- Frogging-Family/wine-tkg-git: no licence, nothing vendored.
