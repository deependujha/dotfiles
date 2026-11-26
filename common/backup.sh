#!/usr/bin/env bash
# The snapshot: one backup of whatever the last run replaced in $HOME.
#
# Layout (inside the repository, ignored by git):
#   snapshot/.run                    id of the run that wrote it
#   snapshot/<component>/<name>      the previous file or directory
#   snapshot/<component>/manifest    "<name><TAB><original absolute path>" lines
#
# There is only ever one snapshot. The first thing a run backs up deletes the
# previous snapshot; a run that replaces nothing leaves it alone. History of
# the configs themselves lives in git, so the snapshot only has to cover the
# files in $HOME that were there before a run changed them.

[ -n "${_DOTFILES_BACKUP_LOADED:-}" ] && return 0
_DOTFILES_BACKUP_LOADED=1

_DOTFILES_REPO="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_SNAPSHOT_DIR="$_DOTFILES_REPO/snapshot"

# Where the bootstrap used to clone the repository. Symlinks pointing there
# are replaced without a backup: they hold no data.
DOTFILES_LEGACY_DIR="$HOME/.local/share/dotfiles"

# install.sh exports the run id so every component in one run shares a
# snapshot; a setup script run on its own gets its own id.
DOTFILES_RUN_ID="${DOTFILES_RUN_ID:-$(date +%Y-%m-%d_%H%M%S)_$$}"
export DOTFILES_RUN_ID

# True if this run has already written to the snapshot.
snapshot_is_current() {
    [ -f "$DOTFILES_SNAPSHOT_DIR/.run" ] \
        && [ "$(cat "$DOTFILES_SNAPSHOT_DIR/.run")" = "$DOTFILES_RUN_ID" ]
}

# Start this run's snapshot, replacing the previous one.
_snapshot_begin() {
    snapshot_is_current && return 0
    if path_exists "$DOTFILES_SNAPSHOT_DIR"; then
        rm -rf -- "$DOTFILES_SNAPSHOT_DIR" || return 1
        log_info "Replacing the previous snapshot."
    fi
    mkdir -p "$DOTFILES_SNAPSHOT_DIR" || return 1
    printf '%s\n' "$DOTFILES_RUN_ID" >"$DOTFILES_SNAPSHOT_DIR/.run"
}

# backup_item <component> <name> <path> <move|copy>
#   move: the original is moved into the snapshot (use when it is about to be
#         replaced, e.g. ~/.vimrc). Symlinks are moved as symlinks.
#   copy: a copy is saved and the original stays in place (use for files that
#         are edited in place, e.g. ~/.bashrc). A symlink to a directory is
#         followed at the top level so the contents are captured.
backup_item() {
    local component="$1" name="$2" src="$3" mode="$4"
    local dir dest

    _snapshot_begin || return 1
    dir="$DOTFILES_SNAPSHOT_DIR/$component"
    dest="$dir/$name"

    if path_exists "$dest"; then
        log_error "Snapshot target already exists, refusing to overwrite: $dest"
        return 1
    fi
    mkdir -p "$dir" || return 1

    case "$mode" in
        move) mv "$src" "$dest" || return 1 ;;
        copy) cp -RpH "$src" "$dest" || return 1 ;;
        *)    log_error "backup_item: unknown mode '$mode'"; return 1 ;;
    esac

    printf '%s\t%s\n' "$name" "$src" >>"$dir/manifest"
    log_info "Saved $src -> $dest"
}

# True if $1 is a symlink to where $2 (a path in this repository) lived in the
# old clone location.
is_legacy_link() {
    [ -L "$1" ] && [ "$(readlink "$1")" = "$DOTFILES_LEGACY_DIR/${2#"$_DOTFILES_REPO"/}" ]
}

# link_config <component> <name> <repo source> <target>
# Make <target> a symlink to <repo source>. Whatever was there before goes
# into the snapshot under <name>.
link_config() {
    local component="$1" name="$2" src="$3" target="$4"

    if is_link_to "$target" "$src"; then
        log_info "Already linked: $target"
        return 0
    fi
    if is_legacy_link "$target" "$src"; then
        rm -- "$target" || return 1
        log_info "Removed the link into the old clone ($DOTFILES_LEGACY_DIR)."
    elif path_exists "$target"; then
        backup_item "$component" "$name" "$target" move || return 1
    fi
    mkdir -p "$(dirname "$target")" || return 1
    ln -s "$src" "$target" || return 1
    log_success "Linked $target -> $src"
}

# Prints the snapshot dir if this run wrote to it, else nothing.
backup_session_if_used() {
    if snapshot_is_current; then
        printf '%s\n' "$DOTFILES_SNAPSHOT_DIR"
    fi
}
