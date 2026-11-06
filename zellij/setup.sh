#!/usr/bin/env bash
# Zellij component: symlink ~/.config/zellij/config.kdl to this repository.
#
# Normally run by install.sh, but safe to run directly:  bash zellij/setup.sh
#
# Only config.kdl is linked, not the whole directory: Zellij writes
# config.kdl.bak* files next to it when it rewrites the config, and those
# shouldn't land in the repository. layouts/ and themes/ stay untouched.

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../common/utils.sh
. "$REPO_DIR/common/utils.sh"
# shellcheck source=../common/detect_os.sh
. "$REPO_DIR/common/detect_os.sh"
# shellcheck source=../common/backup.sh
. "$REPO_DIR/common/backup.sh"

COMPONENT="zellij"
CONFIG_SOURCE="$SCRIPT_DIR/config.kdl"
CONFIG_DIR="${ZELLIJ_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zellij}"
CONFIG_TARGET="$CONFIG_DIR/config.kdl"

HAVE_ZELLIJ=0

# ---------------------------------------------------------------------------

check_prerequisites() {
    local os
    os="$(detect_os)"
    [ "$os" != unsupported ] || die "Unsupported OS: $(uname -s). Only macOS and Linux are supported."
    log_info "Detected OS: $os"

    # The config is just a file, so it can be linked before Zellij is
    # installed; it'll be picked up on first launch.
    if command_exists zellij; then
        HAVE_ZELLIJ=1
        log_info "Using $(command -v zellij) ($(zellij --version 2>/dev/null || echo 'unknown version'))"
    else
        log_warn "'zellij' is not installed; linking the config anyway. Install it with:  $(install_hint zellij)"
    fi
}

# Refuse to link a config Zellij can't parse. Runs before anything in $HOME
# is touched, so a broken config.kdl leaves the existing setup alone.
validate_config() {
    [ -f "$CONFIG_SOURCE" ] || die "$CONFIG_SOURCE not found. Nothing was changed."
    [ "$HAVE_ZELLIJ" -eq 1 ] || return 0
    local out
    if ! out="$(zellij --config "$CONFIG_SOURCE" setup --check 2>&1 </dev/null)"; then
        log_error "Zellij rejected $CONFIG_SOURCE:"
        printf '%s\n' "$out" | sed 's/^/    /' >&2
        die "Nothing was changed."
    fi
    log_success "Config is valid."
}

config_is_managed() {
    is_link_to "$CONFIG_TARGET" "$CONFIG_SOURCE"
}

backup_existing() {
    if config_is_managed; then
        log_info "$CONFIG_TARGET already links to this repository; no backup needed."
        return 0
    fi
    # ~/.config/zellij itself as a broken symlink or a plain file can't hold
    # config.kdl; move it aside so the directory can be created.
    if path_exists "$CONFIG_DIR" && [ ! -d "$CONFIG_DIR" ]; then
        backup_item "$COMPONENT" zellij-directory "$CONFIG_DIR" move
    fi
    if path_exists "$CONFIG_TARGET"; then
        backup_item "$COMPONENT" config.kdl "$CONFIG_TARGET" move
    fi
}

link_config() {
    if config_is_managed; then
        log_info "Symlink already correct: $CONFIG_TARGET -> $CONFIG_SOURCE"
        return 0
    fi
    mkdir -p "$CONFIG_DIR"
    path_exists "$CONFIG_TARGET" && die "$CONFIG_TARGET still exists; refusing to overwrite it."
    ln -s "$CONFIG_SOURCE" "$CONFIG_TARGET"
    log_success "Linked $CONFIG_TARGET -> $CONFIG_SOURCE"
}

main() {
    check_prerequisites
    validate_config
    backup_existing
    link_config

    local session
    session="$(backup_session_if_used)"
    [ -z "$session" ] || log_info "Backup of previous Zellij config: $session/$COMPONENT"

    log_success "Zellij is ready."
}

main "$@"
