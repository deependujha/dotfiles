#!/usr/bin/env bash
# Restore configuration from a backup made by install.sh.
#
#   bash scripts/restore.sh            # pick a backup interactively
#   bash scripts/restore.sh <name>     # e.g. 2026-11-06_103000
#
# Nothing is deleted: whatever is currently in place is first moved into a new
# "<timestamp>_pre-restore" backup (symlinks into this repository are simply
# removed — they hold no data). Backups are copied back, never consumed, so
# the same backup can be restored again later.

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../common/utils.sh
. "$REPO_DIR/common/utils.sh"
# shellcheck source=../common/backup.sh
. "$REPO_DIR/common/backup.sh"

# Prints backup session names (oldest first; names sort chronologically).
list_sessions() {
    local d
    for d in "$DOTFILES_BACKUP_ROOT"/*/; do
        [ -d "$d" ] || continue
        d="${d%/}"
        # Only sessions with at least one component manifest are restorable.
        ls "$d"/*/manifest >/dev/null 2>&1 || continue
        printf '%s\n' "${d##*/}"
    done
}

# Prints the components contained in a session, e.g. "vim".
session_components() {
    local m out=''
    for m in "$DOTFILES_BACKUP_ROOT/$1"/*/manifest; do
        [ -f "$m" ] || continue
        m="${m%/manifest}"
        out="$out ${m##*/}"
    done
    printf '%s\n' "${out# }"
}

# True if $1 is a symlink pointing somewhere inside this repository.
is_repo_link() {
    local target
    [ -L "$1" ] || return 1
    target="$(readlink "$1")"
    case "$target" in "$REPO_DIR"/*) return 0 ;; esac
    return 1
}

choose_session() {
    local sessions="$1" count i=0 choice name
    count="$(printf '%s\n' "$sessions" | wc -l | tr -d ' ')"

    printf '\nAvailable backups in %s:\n' "$DOTFILES_BACKUP_ROOT" >&2
    while IFS= read -r name; do
        i=$((i + 1))
        printf '  %2d) %s   [%s]\n' "$i" "$name" "$(session_components "$name")" >&2
    done <<EOF
$sessions
EOF
    printf 'Select a backup [1-%s]: ' "$count" >&2
    read -r choice || choice=''
    case "$choice" in
        ''|*[!0-9]*) die "No valid selection; nothing was changed." ;;
    esac
    [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ] || die "Selection out of range; nothing was changed."
    printf '%s\n' "$sessions" | sed -n "${choice}p"
}

# Print what will happen for every item, so the user confirms a concrete plan.
show_plan() {
    local session_dir="$1" manifest component name target
    printf '\nRestore plan:\n'
    for manifest in "$session_dir"/*/manifest; do
        component="$(basename "$(dirname "$manifest")")"
        while IFS="$(printf '\t')" read -r name target; do
            [ -n "$name" ] || continue
            printf '  [%s] %s\n' "$component" "$target"
            if is_repo_link "$target"; then
                printf '      - remove current symlink into the dotfiles repo\n'
            elif path_exists "$target"; then
                printf '      - move current version to a pre-restore backup\n'
            fi
            printf '      - copy back from %s/%s\n' "$component" "$name"
        done <"$manifest"
    done
    printf '\n'
}

restore_session() {
    local session_dir="$1" manifest component name target src
    for manifest in "$session_dir"/*/manifest; do
        component="$(basename "$(dirname "$manifest")")"
        while IFS="$(printf '\t')" read -r name target; do
            [ -n "$name" ] || continue
            src="$session_dir/$component/$name"
            if ! path_exists "$src"; then
                log_warn "Missing from backup, skipping: $src"
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
    local sessions selected session_dir

    sessions="$(list_sessions)"
    if [ -z "$sessions" ]; then
        log_info "No backups found in $DOTFILES_BACKUP_ROOT."
        log_info "Backups are only created when the installer replaces existing files;"
        log_info "if you had no previous Vim config, there is nothing to restore."
        exit 0
    fi

    if [ $# -gt 0 ]; then
        selected="$1"
        printf '%s\n' "$sessions" | grep -qxF -- "$selected" \
            || die "No such backup: $selected (look in $DOTFILES_BACKUP_ROOT)"
    else
        selected="$(choose_session "$sessions")"
    fi
    session_dir="$DOTFILES_BACKUP_ROOT/$selected"

    show_plan "$session_dir"
    confirm "Proceed with restore from $selected?" || { log_info "Aborted; nothing was changed."; exit 0; }

    # Current state goes into its own new session, never into an existing one.
    DOTFILES_BACKUP_SESSION="$(backup_new_session_path pre-restore)"
    export DOTFILES_BACKUP_SESSION

    restore_session "$session_dir"

    if [ -d "$DOTFILES_BACKUP_SESSION" ]; then
        log_info "Previous state saved to: $DOTFILES_BACKUP_SESSION"
    fi
    log_success "Restore from $selected complete."
}

main "$@"
