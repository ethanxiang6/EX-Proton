#!/usr/bin/env bash
#
# EX-Proton build preparation.
#
# EX-Proton is a fork of Valve's Proton: changes to Proton's own files are
# committed in this repository. Changes to submodules (Wine and a few extra
# components) are kept as patch files and applied here, before building:
#   1. initialise all submodules
#   2. arm64 only: fetch FEX's release tags (its build runs `git describe`)
#   3. apply patches/<component>/*.patch with `git apply`, in lexicographic
#      order, inside <component> ("__" in the directory name stands for "/",
#      so patches/extras__foo applies in extras/foo)
#
# Usage: scripts/prepare.sh [--jobs N] [--target-arch x86_64|arm64]
#   --jobs N          parallel submodule clones (default: nproc)
#   --target-arch A   build target (default x86_64). Patches listed in
#                     patches/x86_64-only.list are skipped for arm64, and those
#                     in patches/arm64-only.list (if present) for x86_64.

set -euo pipefail

die() { echo "prepare.sh: ERROR: $*" >&2; exit 1; }
info() { echo "prepare.sh: $*"; }

JOBS="${EXPROTON_JOBS:-}"
TARGET_ARCH=x86_64
while [ $# -gt 0 ]; do
    case "$1" in
        --jobs)   [ $# -ge 2 ] || die "--jobs needs a value"; JOBS="$2"; shift 2 ;;
        --jobs=*) JOBS="${1#--jobs=}"; shift ;;
        --target-arch)   [ $# -ge 2 ] || die "--target-arch needs a value"; TARGET_ARCH="$2"; shift 2 ;;
        --target-arch=*) TARGET_ARCH="${1#--target-arch=}"; shift ;;
        -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done
[ -n "$JOBS" ] || JOBS="$(nproc 2>/dev/null || echo 4)"
case "$JOBS" in ''|*[!0-9]*|0) die "--jobs must be a positive integer, got '$JOBS'" ;; esac
case "$TARGET_ARCH" in x86_64|arm64) ;; *) die "--target-arch must be x86_64 or arm64" ;; esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$ROOT is not a git work tree"

# Refuse to patch submodules that already have changes (patches would be
# applied twice or onto unknown code).
dirty="$(git submodule foreach --quiet --recursive 'git status --porcelain | head -n 1 | sed "s#^#$displaypath: #"' 2>/dev/null || true)"
[ -z "$dirty" ] || { echo "$dirty" >&2; die "submodules have local changes; use a fresh clone"; }

# --- 1. submodules ----------------------------------------------------------
info "initialising submodules (jobs=$JOBS); this downloads a lot"
git submodule sync --recursive
git submodule update --init --filter=tree:0 --recursive --jobs "$JOBS"

# --- 2. arm64: FEX release tags ----------------------------------------------
if [ "$TARGET_ARCH" = arm64 ]; then
    info "arm64: fetching FEX release tags"
    git -C FEX fetch -q --filter=tree:0 --tags origin || die "fetching FEX tags failed"
    git -C FEX describe --abbrev=7 || die "git describe fails in FEX"
fi

# --- 3. patches ---------------------------------------------------------------
in_list() {
    local list="$1" rel="$2"
    [ -f "$list" ] || return 1
    tr -d '\r' < "$list" | grep -v '^[[:space:]]*\(#\|$\)' | grep -qxF -- "$rel"
}
skip_for_arch() {
    if [ "$TARGET_ARCH" != x86_64 ] && in_list "$ROOT/patches/x86_64-only.list" "$1"; then return 0; fi
    if [ "$TARGET_ARCH" != arm64 ] && in_list "$ROOT/patches/arm64-only.list" "$1"; then return 0; fi
    return 1
}

info "target architecture: $TARGET_ARCH"
n_patch=0
n_skip=0
for pdir in "$ROOT"/patches/*/; do
    [ -d "$pdir" ] || continue
    component="$(basename "$pdir")"
    target="$ROOT/${component//__//}"
    mapfile -t patches < <(find "$pdir" -maxdepth 1 -type f -name '*.patch' | LC_ALL=C sort)
    [ "${#patches[@]}" -gt 0 ] || continue
    [ -e "$target/.git" ] || die "patches/$component: $target is not a submodule checkout"
    for patch in "${patches[@]}"; do
        rel="$component/$(basename "$patch")"
        if skip_for_arch "$rel"; then
            info "skipping patches/$rel (not for $TARGET_ARCH)"
            n_skip=$((n_skip + 1))
            continue
        fi
        info "applying patches/$rel"
        git -C "$target" apply --whitespace=nowarn "$patch" || die "patch failed to apply: patches/$rel"
        n_patch=$((n_patch + 1))
    done
done

info "done: $n_patch patch(es) applied, $n_skip skipped for $TARGET_ARCH"
