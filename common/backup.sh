#!/usr/bin/env bash
# Timestamped backups.
#
# Layout:
#   $DOTFILES_BACKUP_ROOT/<YYYY-MM-DD_HHMMSS>/<component>/<name>
#   $DOTFILES_BACKUP_ROOT/<YYYY-MM-DD_HHMMSS>/<component>/manifest
#
# The manifest has one "<name><TAB><original absolute path>" line per item,
# which is all scripts/restore.sh needs to put things back.
#
# A session directory is only created when something is actually backed up,
# so re-running an installer that has nothing to change leaves no empty dirs.

[ -n "${_DOTFILES_BACKUP_LOADED:-}" ] && return 0
_DOTFILES_BACKUP_LOADED=1

# Lives outside the repository on purpose: deleting the repo keeps backups.
DOTFILES_BACKUP_ROOT="${DOTFILES_BACKUP_ROOT:-$HOME/dotfiles_backup}"

# Prints a session path that does not exist yet. Never reuses an existing one.
# Optional $1 is appended to the name (e.g. "pre-restore").
backup_new_session_path() {
    local stamp candidate n=1 suffix="${1:+_$1}"
    stamp="$(date +%Y-%m-%d_%H%M%S)"
    candidate="$DOTFILES_BACKUP_ROOT/$stamp$suffix"
    while path_exists "$candidate"; do
        n=$((n + 1))
        candidate="$DOTFILES_BACKUP_ROOT/$stamp${suffix}_$n"
    done
    printf '%s\n' "$candidate"
}

# install.sh exports DOTFILES_BACKUP_SESSION so every component in one run
# shares a session; a setup script run on its own picks its own.
_backup_ensure_session() {
    if [ -z "${DOTFILES_BACKUP_SESSION:-}" ]; then
        DOTFILES_BACKUP_SESSION="$(backup_new_session_path "")"
        export DOTFILES_BACKUP_SESSION
    fi
}

# backup_item <component> <name> <path> <move|copy>
#   move: the original is moved into the backup (use when it is about to be
#         replaced, e.g. ~/.vimrc). Symlinks are moved as symlinks.
#   copy: a snapshot is copied and the original stays in place (use for
#         directories we only add to, e.g. ~/.vim). A symlink to a directory
#         is followed at the top level so the contents are captured.
backup_item() {
    local component="$1" name="$2" src="$3" mode="$4"
    local dir dest

    _backup_ensure_session
    dir="$DOTFILES_BACKUP_SESSION/$component"
    dest="$dir/$name"

    if path_exists "$dest"; then
        log_error "Backup target already exists, refusing to overwrite: $dest"
        return 1
    fi
    mkdir -p "$dir" || return 1

    case "$mode" in
        move) mv "$src" "$dest" || return 1 ;;
        copy) cp -RpH "$src" "$dest" || return 1 ;;
        *)    log_error "backup_item: unknown mode '$mode'"; return 1 ;;
    esac

    printf '%s\t%s\n' "$name" "$src" >>"$dir/manifest"
    log_info "Backed up $src -> $dest"
}

# Prints the session dir if this process created one, else nothing.
backup_session_if_used() {
    if [ -n "${DOTFILES_BACKUP_SESSION:-}" ] && [ -d "$DOTFILES_BACKUP_SESSION" ]; then
        printf '%s\n' "$DOTFILES_BACKUP_SESSION"
    fi
}
