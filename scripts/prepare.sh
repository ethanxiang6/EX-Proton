#!/usr/bin/env bash
#
# EXProton overlay preparation (UNTESTED - authored without a Linux environment).
#
# Turns a fresh checkout of this repo into a buildable Proton tree:
#   1. init the pinned Valve Proton submodule (./proton) and its nested submodules
#   2. apply overrides.conf   (<path-inside-proton> <git-url> <40-char-sha>)
#   3. apply patches/<component>/*.patch with `git apply` (patches/proton/ applies
#      at the proton root; any other directory applies in proton/<component>)
#
# Usage: scripts/prepare.sh [--jobs N]
#   --jobs N   parallel submodule clones (default: $EXPROTON_JOBS, else nproc, else 4)

set -euo pipefail

die() { echo "prepare.sh: ERROR: $*" >&2; exit 1; }
info() { echo "prepare.sh: $*"; }

JOBS="${EXPROTON_JOBS:-}"
while [ $# -gt 0 ]; do
    case "$1" in
        --jobs)   [ $# -ge 2 ] || die "--jobs needs a value"; JOBS="$2"; shift 2 ;;
        --jobs=*) JOBS="${1#--jobs=}"; shift ;;
        -h|--help) sed -n '2,15p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done
if [ -z "$JOBS" ]; then
    JOBS="$(nproc 2>/dev/null || echo 4)"
fi
case "$JOBS" in
    ''|*[!0-9]*|0) die "--jobs must be a positive integer, got '$JOBS'" ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTON="$ROOT/proton"
cd "$ROOT"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "$ROOT is not a git work tree"
[ -f "$ROOT/.gitmodules" ] || die "$ROOT/.gitmodules not found; is the proton submodule registered?"

# --- refuse to run on a modified proton tree --------------------------------
check_clean() {
    local where="$1" dirty
    dirty="$(git -C "$PROTON" status --porcelain --ignore-submodules=none)" || die "git status failed in proton"
    if [ -n "$dirty" ]; then
        echo "$dirty" | head -n 20 >&2
        die "the proton tree has local modifications ($where). Refusing to continue: this script must run on a pristine checkout (use a fresh clone, or: git -C proton reset --hard && git -C proton submodule foreach --recursive 'git reset --hard && git clean -fdx' )"
    fi
}

if [ -e "$PROTON/.git" ]; then
    check_clean "before update"
fi

# --- 1. submodules ----------------------------------------------------------
# No --depth: pinned SHAs are not guaranteed to be at the tip of a branch, and
# shallow fetches of an arbitrary SHA are not reliable across all remotes.
info "initialising proton submodule"
git submodule update --init proton
[ -e "$PROTON/.git" ] || die "proton submodule did not initialise"
check_clean "after top-level init"

info "initialising nested submodules (jobs=$JOBS); this downloads a lot"
git -C "$PROTON" submodule update --init --recursive --jobs "$JOBS"

# --- 2. overrides -----------------------------------------------------------
OVERRIDES="$ROOT/overrides.conf"
n_over=0
if [ -f "$OVERRIDES" ]; then
    lineno=0
    while IFS= read -r line || [ -n "$line" ]; do
        lineno=$((lineno + 1))
        line="${line%$'\r'}"
        # strip leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        case "$line" in ''|'#'*) continue ;; esac

        read -r opath ourl osha extra <<<"$line"
        [ -n "${opath:-}" ] && [ -n "${ourl:-}" ] && [ -n "${osha:-}" ] \
            || die "overrides.conf:$lineno: expected '<path> <git-url> <sha>', got: $line"
        [ -z "${extra:-}" ] || die "overrides.conf:$lineno: unexpected extra fields: $extra"
        [[ "$osha" =~ ^[0-9a-fA-F]{40}$ ]] || die "overrides.conf:$lineno: '$osha' is not a 40-char SHA"
        case "$opath" in
            /*|..|../*|*/..|*/../*) die "overrides.conf:$lineno: bad path '$opath' (must be relative, inside proton)" ;;
        esac

        odir="$PROTON/$opath"
        [ -d "$odir" ] || die "overrides.conf:$lineno: proton/$opath does not exist"
        [ -e "$odir/.git" ] || die "overrides.conf:$lineno: proton/$opath is not a git checkout (not a submodule?)"

        info "override: proton/$opath -> $osha ($ourl)"
        git -C "$odir" fetch --no-tags "$ourl" "$osha" \
            || die "overrides.conf:$lineno: fetch of $osha from $ourl failed"
        git -C "$odir" checkout --detach "$osha" \
            || die "overrides.conf:$lineno: checkout of $osha in proton/$opath failed"
        head_sha="$(git -C "$odir" rev-parse HEAD)"
        [ "$head_sha" = "$(echo "$osha" | tr 'A-F' 'a-f')" ] \
            || die "overrides.conf:$lineno: HEAD is $head_sha after checkout, expected $osha"

        git -C "$odir" submodule sync --recursive \
            || die "overrides.conf:$lineno: submodule sync failed in proton/$opath"
        git -C "$odir" submodule update --init --recursive --jobs "$JOBS" \
            || die "overrides.conf:$lineno: nested submodule update failed in proton/$opath"
        n_over=$((n_over + 1))
    done < "$OVERRIDES"
else
    info "no overrides.conf; skipping overrides"
fi

# --- 3. patches -------------------------------------------------------------
n_patch=0
if [ -d "$ROOT/patches" ]; then
    for pdir in "$ROOT"/patches/*/; do
        [ -d "$pdir" ] || continue
        component="$(basename "$pdir")"
        if [ "$component" = "proton" ]; then
            target="$PROTON"
        else
            target="$PROTON/$component"
        fi

        mapfile -t patches < <(find "$pdir" -maxdepth 1 -type f -name '*.patch' | LC_ALL=C sort)
        [ "${#patches[@]}" -gt 0 ] || continue

        [ -d "$target" ] || die "patches/$component has patches but $target does not exist"
        [ -e "$target/.git" ] || die "patches/$component: $target is not a git checkout"

        for patch in "${patches[@]}"; do
            name="patches/$component/$(basename "$patch")"
            info "applying $name"
            if ! git -C "$target" apply --whitespace=nowarn "$patch"; then
                die "patch failed to apply: $name"
            fi
            n_patch=$((n_patch + 1))
        done
    done
else
    info "no patches/ directory; skipping patches"
fi

info "done: $n_over override(s), $n_patch patch(es) applied"
