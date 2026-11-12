#!/usr/bin/env bash
#
# EX-Proton overlay preparation.
#
# Turns a fresh checkout of this repo into a buildable Proton tree:
#   1. init the pinned upstream Proton submodule (./proton) and its nested submodules
#   2. apply overrides.conf   (<path-inside-proton> <git-url> <40-char-sha>)
#   3. run Proton-GE's own patch script if the base has one (Proton-GE only)
#   4. apply patches/<component>/*.patch with `git apply` (patches/proton/ applies
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
git -C "$PROTON" submodule update --init --filter=tree:0 --recursive --jobs "$JOBS"

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

# --- 2b. extra source trees ---------------------------------------------------
# extras.conf: <new-path-inside-proton> <git-url> <40-char-sha>. Unlike an
# override this adds a source tree the upstream tree does not have (built by
# rules our patches/proton/ patches add).
EXTRAS="$ROOT/extras.conf"
n_extra=0
if [ -f "$EXTRAS" ]; then
    lineno=0
    while IFS= read -r line || [ -n "$line" ]; do
        lineno=$((lineno + 1))
        line="${line%$'\r'}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        case "$line" in ''|'#'*) continue ;; esac

        read -r epath eurl esha extra <<<"$line"
        [ -n "${epath:-}" ] && [ -n "${eurl:-}" ] && [ -n "${esha:-}" ] \
            || die "extras.conf:$lineno: expected '<path> <git-url> <sha>', got: $line"
        [ -z "${extra:-}" ] || die "extras.conf:$lineno: unexpected extra fields: $extra"
        [[ "$esha" =~ ^[0-9a-f]{40}$ ]] || die "extras.conf:$lineno: '$esha' is not a lowercase 40-char SHA"
        case "$epath" in
            /*|..|../*|*/..|*/../*) die "extras.conf:$lineno: bad path '$epath' (must be relative, inside proton)" ;;
        esac

        edir="$PROTON/$epath"
        [ ! -e "$edir" ] || die "extras.conf:$lineno: proton/$epath already exists (use overrides.conf to replace a component)"

        info "extra: proton/$epath <- $esha ($eurl)"
        mkdir -p "$edir"
        git -C "$edir" init -q
        git -C "$edir" fetch --no-tags "$eurl" "$esha" \
            || die "extras.conf:$lineno: fetch of $esha from $eurl failed"
        git -C "$edir" checkout -q --detach FETCH_HEAD \
            || die "extras.conf:$lineno: checkout failed in proton/$epath"
        [ "$(git -C "$edir" rev-parse HEAD)" = "$esha" ] \
            || die "extras.conf:$lineno: HEAD is not $esha after checkout"
        git -C "$edir" submodule update --init --recursive --jobs "$JOBS" \
            || die "extras.conf:$lineno: nested submodule update failed in proton/$epath"
        n_extra=$((n_extra + 1))
    done < "$EXTRAS"
else
    info "no extras.conf; skipping extra source trees"
fi

# --- 3. Proton-GE's own patch step (only when the base is Proton-GE) ----------
# GE applies its patch set to the submodules with this script (it resets each
# submodule to HEAD first, which is why overrides run before it). GE's CI runs
# it with `|| true`; here a rejected hunk is treated as an error unless
# EXPROTON_ALLOW_PREP_REJECTS=1, because an override can make GE's patches for
# that component stop applying.
GE_PREP="$PROTON/patches/protonprep-valve-staging.sh"
if [ -f "$GE_PREP" ]; then
    PREP_LOG="$ROOT/prepare-ge.log"
    info "running Proton-GE prep script (log: $PREP_LOG)"
    prep_status=0
    ( cd "$PROTON" && bash ./patches/protonprep-valve-staging.sh ) >"$PREP_LOG" 2>&1 || prep_status=$?
    tail -n 15 "$PREP_LOG"
    info "GE prep script exit status: $prep_status"
    if grep -nE "FAILED|can't find file to patch" "$PREP_LOG" >"$ROOT/prepare-ge.rejects" 2>/dev/null; then
        echo "prepare.sh: GE prep script reported problems:" >&2
        head -n 60 "$ROOT/prepare-ge.rejects" >&2
        if [ "${EXPROTON_ALLOW_PREP_REJECTS:-0}" != "1" ]; then
            die "GE patches did not apply cleanly (set EXPROTON_ALLOW_PREP_REJECTS=1 to continue anyway)"
        fi
    fi
    rejs="$(find "$PROTON" -name '*.rej' -not -path '*/.git/*' | head -n 20)"
    if [ -n "$rejs" ] && [ "${EXPROTON_ALLOW_PREP_REJECTS:-0}" != "1" ]; then
        echo "$rejs" >&2
        die "GE prep left .rej files behind"
    fi
else
    info "base tree has no Proton-GE prep script; skipping (Valve base)"
fi

# --- 4. our patches ---------------------------------------------------------
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

info "done: $n_over override(s), $n_extra extra tree(s), $n_patch patch(es) applied"
