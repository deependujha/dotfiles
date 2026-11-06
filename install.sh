#!/usr/bin/env bash
# dotfiles installer — public entry point.
#
#   bash install.sh                 # install the default components
#   bash install.sh vim             # install only the listed components
#   bash <(curl -fsSL https://raw.githubusercontent.com/deependujha/dotfiles/main/install.sh)
#
# When run from a downloaded copy (process substitution or a pipe) there is no
# repository next to the script, so it first clones/updates the repository to
# $DOTFILES_DIR (default ~/.local/share/dotfiles) and re-executes the copy there.
#
# Environment overrides:
#   DOTFILES_DIR          where to clone the repo when bootstrapping
#   DOTFILES_REPO         git URL to clone (default: GitHub over HTTPS)
#   DOTFILES_BRANCH       branch to clone (default: main)
#   DOTFILES_BACKUP_ROOT  where backups go (default: ~/dotfiles_backup)

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/deependujha/dotfiles.git}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

# Installed when no component is named. Adding a tool = create <tool>/setup.sh
# and (optionally) append it here.
DEFAULT_COMPONENTS="vim zellij"

# Re-use the running interpreter for children so `/bin/bash install.sh`
# really exercises Bash 3.2 end to end.
BASH_BIN="${BASH:-bash}"

# ---------------------------------------------------------------------------
# Bootstrap (runs before common/utils.sh is available, so it logs on its own)
# ---------------------------------------------------------------------------

_boot_info()  { printf '[INFO]    %s\n' "$*"; }
_boot_warn()  { printf '[WARN]    %s\n' "$*" >&2; }
_boot_die()   { printf '[ERROR]   %s\n' "$*" >&2; exit 1; }

# Prints the repository root if this script is a file inside a checkout.
# Under `bash <(curl ...)` BASH_SOURCE is /dev/fd/NN (a pipe, not a regular
# file); under `curl ... | bash` it is empty. Both mean "no local repo".
find_local_repo() {
    local src="${BASH_SOURCE[0]:-}" dir
    [ -n "$src" ] && [ -f "$src" ] || return 1
    case "$src" in /dev/fd/*|/proc/*) return 1 ;; esac
    dir="$(cd -P "$(dirname "$src")" 2>/dev/null && pwd)" || return 1
    [ -f "$dir/common/utils.sh" ] && [ -f "$dir/install.sh" ] || return 1
    printf '%s\n' "$dir"
}

bootstrap() {
    local target="${DOTFILES_DIR:-$HOME/.local/share/dotfiles}"

    # Guard against an exec loop if the clone somehow isn't recognised.
    [ -z "${DOTFILES_BOOTSTRAPPED:-}" ] || _boot_die "Bootstrap re-entered; '$target' does not look like the dotfiles repository."
    command -v git >/dev/null 2>&1 || _boot_die "git is required to bootstrap. Install git and re-run."

    if [ -e "$target/.git" ]; then
        _boot_info "Using existing repository at $target"
        if [ -n "$(git -C "$target" status --porcelain 2>/dev/null)" ]; then
            _boot_warn "Local changes in $target; skipping update (commit or stash them to update)."
        elif git -C "$target" pull --ff-only --quiet; then
            _boot_info "Repository updated."
        else
            _boot_warn "Could not fast-forward $target; continuing with the existing checkout."
        fi
    elif [ -e "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
        _boot_die "$target exists and is not a git repository. Move it away or set DOTFILES_DIR."
    else
        _boot_info "Cloning $DOTFILES_REPO ($DOTFILES_BRANCH) into $target"
        mkdir -p "$(dirname "$target")"
        git clone --quiet --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$target" \
            || _boot_die "git clone failed (network problem or wrong DOTFILES_REPO?)."
    fi

    [ -f "$target/install.sh" ] || _boot_die "$target/install.sh not found."
    DOTFILES_BOOTSTRAPPED=1 exec "$BASH_BIN" "$target/install.sh" "$@"
}

# ---------------------------------------------------------------------------
# Installer
# ---------------------------------------------------------------------------

usage() {
    cat <<EOF
Usage: install.sh [component ...]

Components available: $(list_components "$1")
Default:              $DEFAULT_COMPONENTS

Restore a previous configuration with: bash scripts/restore.sh
EOF
}

# A component is any top-level directory with a setup.sh.
list_components() {
    local repo="$1" d out=''
    for d in "$repo"/*/setup.sh; do
        [ -f "$d" ] || continue
        d="${d%/setup.sh}"
        out="$out ${d##*/}"
    done
    printf '%s\n' "${out# }"
}

main() {
    local repo
    if ! repo="$(find_local_repo)"; then
        bootstrap "$@"
    fi

    # shellcheck source=common/utils.sh
    . "$repo/common/utils.sh"
    # shellcheck source=common/backup.sh
    . "$repo/common/backup.sh"

    # Parse and validate arguments. Space-separated strings rather than arrays:
    # empty arrays + `set -u` break on Bash 3.2.
    local requested='' arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help) usage "$repo"; exit 0 ;;
            -*) usage "$repo" >&2; die "Unknown option: $arg" ;;
        esac
        case "$arg" in
            *[!a-z0-9_-]*) die "Invalid component name: $arg" ;;
        esac
        [ -f "$repo/$arg/setup.sh" ] || die "Unknown component '$arg'. Available: $(list_components "$repo")"
        case " $requested " in *" $arg "*) continue ;; esac
        requested="$requested $arg"
    done
    requested="${requested# }"
    [ -n "$requested" ] || requested="$DEFAULT_COMPONENTS"

    export DOTFILES_DIR="$repo"
    # One backup session shared by every component in this run.
    DOTFILES_BACKUP_SESSION="$(backup_new_session_path "")"
    export DOTFILES_BACKUP_SESSION DOTFILES_BACKUP_ROOT

    log_info "Repository: $repo"
    log_info "Components: $requested"

    local ok='' failed='' c
    for c in $requested; do
        log_header "Installing $c"
        if "$BASH_BIN" "$repo/$c/setup.sh"; then
            ok="$ok $c"
        else
            failed="$failed $c"
        fi
    done

    log_header "Summary"
    [ -z "$ok" ]     || log_success "Installed:${ok}"
    [ -z "$failed" ] || log_error   "Failed:${failed}"
    log_info "Repository: $repo"
    if [ -d "$DOTFILES_BACKUP_SESSION" ]; then
        log_info "Backup:     $DOTFILES_BACKUP_SESSION"
        log_info "Restore:    bash \"$repo/scripts/restore.sh\""
    else
        log_info "Backup:     none needed (nothing was replaced)"
    fi

    [ -z "$failed" ]
}

main "$@"
