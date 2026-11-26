#!/usr/bin/env bash
# Put back what the last `make update` replaced, from snapshot/.
#
#   make restore        (or: bash scripts/restore.sh)
#
# Nothing is lost: whatever is currently in place becomes the new snapshot
# (symlinks into this repository are simply removed, they hold no data).
# `make update` applies the repository again.

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../common/utils.sh
. "$REPO_DIR/common/utils.sh"
# shellcheck source=../common/backup.sh
. "$REPO_DIR/common/backup.sh"

# The snapshot being restored is parked here while the new one is written.
OLD="$DOTFILES_SNAPSHOT_DIR.restoring"

# True if $1 is a symlink pointing somewhere inside this repository.
is_repo_link() {
    local target
    [ -L "$1" ] || return 1
    target="$(readlink "$1")"
    case "$target" in "$REPO_DIR"/*) return 0 ;; esac
    return 1
}

# Print what will happen for every item, so the user confirms a concrete plan.
show_plan() {
    local dir="$1" manifest component name target
    printf '\nRestore plan:\n'
    for manifest in "$dir"/*/manifest; do
        component="$(basename "$(dirname "$manifest")")"
        while IFS="$(printf '\t')" read -r name target; do
            [ -n "$name" ] || continue
            printf '  [%s] %s\n' "$component" "$target"
            if is_repo_link "$target"; then
                printf '      - remove the current symlink into the dotfiles repo\n'
            elif path_exists "$target"; then
                printf '      - move the current version into the new snapshot\n'
            fi
            printf '      - copy back from snapshot/%s/%s\n' "$component" "$name"
        done <"$manifest"
    done
    printf '\n'
}

restore_from() {
    local dir="$1" manifest component name target src
    for manifest in "$dir"/*/manifest; do
        component="$(basename "$(dirname "$manifest")")"
        while IFS="$(printf '\t')" read -r name target; do
            [ -n "$name" ] || continue
            src="$dir/$component/$name"
            if ! path_exists "$src"; then
                log_warn "Missing from the snapshot, skipping: $src"
                continue
            fi

            if is_repo_link "$target"; then
                rm -- "$target"           # a symlink only; the repo file is untouched
            elif path_exists "$target"; then
                backup_item "$component" "$name" "$target" move
            fi

            mkdir -p "$(dirname "$target")"
            # -P keeps symlinks as symlinks (e.g. a previous ~/.vimrc link).
            cp -RpP "$src" "$target"
            log_success "Restored $target"
        done <"$manifest"
    done
}

main() {
    if path_exists "$OLD"; then
        die "$OLD exists: an earlier restore was interrupted. It holds the snapshot that was being restored; check it, then move it back to $DOTFILES_SNAPSHOT_DIR or delete it."
    fi
    if ! ls "$DOTFILES_SNAPSHOT_DIR"/*/manifest >/dev/null 2>&1; then
        log_info "No snapshot in $DOTFILES_SNAPSHOT_DIR."
        log_info "One is only written when 'make update' replaces something in your home directory."
        exit 0
    fi

    show_plan "$DOTFILES_SNAPSHOT_DIR"
    confirm "Proceed with the restore?" || { log_info "Aborted; nothing was changed."; exit 0; }

    mv "$DOTFILES_SNAPSHOT_DIR" "$OLD"
    restore_from "$OLD"

    if snapshot_is_current; then
        rm -rf -- "$OLD"
        log_info "What was in place before is now the snapshot."
    else
        # Nothing had to be moved aside, so the restored snapshot stays as it was.
        mv "$OLD" "$DOTFILES_SNAPSHOT_DIR"
    fi
    log_success "Restore complete. Run 'make update' to apply the repository again."
}

main "$@"
