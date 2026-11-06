#!/usr/bin/env bash
# Shared helpers: logging and small filesystem predicates.
# Sourced by install.sh, component setup scripts, and scripts/restore.sh.
# Must stay compatible with macOS's default Bash 3.2.

[ -n "${_DOTFILES_UTILS_LOADED:-}" ] && return 0
_DOTFILES_UTILS_LOADED=1

# Colors only when writing to a terminal, and never when NO_COLOR is set.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    _C_BLUE=$'\033[34m'
    _C_YELLOW=$'\033[33m'
    _C_RED=$'\033[31m'
    _C_GREEN=$'\033[32m'
    _C_BOLD=$'\033[1m'
    _C_RESET=$'\033[0m'
else
    _C_BLUE='' _C_YELLOW='' _C_RED='' _C_GREEN='' _C_BOLD='' _C_RESET=''
fi

log_info()    { printf '%s[INFO]%s    %s\n' "$_C_BLUE" "$_C_RESET" "$*"; }
log_warn()    { printf '%s[WARN]%s    %s\n' "$_C_YELLOW" "$_C_RESET" "$*" >&2; }
log_error()   { printf '%s[ERROR]%s   %s\n' "$_C_RED" "$_C_RESET" "$*" >&2; }
log_success() { printf '%s[SUCCESS]%s %s\n' "$_C_GREEN" "$_C_RESET" "$*"; }
log_header()  { printf '\n%s==> %s%s\n' "$_C_BOLD" "$*" "$_C_RESET"; }

die() {
    log_error "$*"
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# True if the path exists in any form, including a broken symlink
# ([ -e ] alone is false for broken symlinks).
path_exists() {
    [ -e "$1" ] || [ -L "$1" ]
}

# True if $1 is a symlink that resolves to the same file as $2.
is_link_to() {
    [ -L "$1" ] && [ "$1" -ef "$2" ]
}

# Ask a yes/no question on stdin; anything but an explicit yes (including EOF)
# means no.
confirm() {
    local reply=''
    printf '%s [y/N] ' "$1"
    read -r reply || true
    case "$reply" in
        y|Y|yes|YES|Yes) return 0 ;;
        *) return 1 ;;
    esac
}
