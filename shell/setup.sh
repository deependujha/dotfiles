#!/usr/bin/env bash
# Shell component: make bash and zsh load shell/init.sh (aliases, functions,
# prompt), and link ~/.inputrc.
#
# Normally run by install.sh, but safe to run directly:  bash shell/setup.sh
#
# Unlike the other components, the rc files are not symlinked: ~/.bashrc and
# ~/.zshrc hold machine-specific things (PATH, tool init lines that installers
# append) that don't belong in the repository. Instead a small marked block
# that sources shell/init.sh is appended to them. Re-runs replace that block
# in place, so it never piles up.
#
# This component replaces the old "shellfu" repository; the loader block its
# `make setup` appended to the rc file is removed here.

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../common/utils.sh
. "$REPO_DIR/common/utils.sh"
# shellcheck source=../common/detect_os.sh
. "$REPO_DIR/common/detect_os.sh"
# shellcheck source=../common/backup.sh
. "$REPO_DIR/common/backup.sh"

COMPONENT="shell"
INIT_SOURCE="$SCRIPT_DIR/init.sh"
INPUTRC_SOURCE="$SCRIPT_DIR/inputrc"
INPUTRC_TARGET="$HOME/.inputrc"
BASHRC="$HOME/.bashrc"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

MARK_BEGIN="# >>> dotfiles shell >>>"
MARK_END="# <<< dotfiles shell <<<"
LEGACY_BEGIN="# Load all shellfu scripts automatically"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-shell.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# ---------------------------------------------------------------------------

check_prerequisites() {
    local os
    os="$(detect_os)"
    [ "$os" != unsupported ] || die "Unsupported OS: $(uname -s). Only macOS and Linux are supported."
    log_info "Detected OS: $os"
    command_exists awk || die "'awk' is not installed. Install it with:  $(install_hint awk)"
}

# Refuse to hook up files the shells can't parse: a syntax error in one would
# show up in every new terminal. Runs before anything in $HOME is touched.
validate_sources() {
    [ -f "$INIT_SOURCE" ] || die "$INIT_SOURCE not found. Nothing was changed."
    local sh f out
    for f in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/*.bash; do
        [ -f "$f" ] || continue
        for sh in bash zsh; do
            command_exists "$sh" || continue
            # *.bash files are only ever loaded by bash.
            case "$sh:$f" in zsh:*.bash) continue ;; esac
            if ! out="$("$sh" -n "$f" 2>&1)"; then
                log_error "$sh found a syntax error in $f:"
                printf '%s\n' "$out" | sed 's/^/    /' >&2
                die "Nothing was changed."
            fi
        done
    done
    log_success "Shell files parse cleanly."
}

# The repository path as it should appear in the rc file: $HOME-relative when
# possible, so the same line works if the home directory is ever renamed.
repo_path_for_rc() {
    local p="$REPO_DIR"
    case "$p" in
        *[\"\`\$\\]*) die "The repository path contains characters that can't be quoted safely: $p" ;;
    esac
    case "$p" in
        "$HOME"/*) p='$HOME/'${p#"$HOME"/} ;;
    esac
    printf '%s\n' "$p"
}

# Prints the rc files to manage, one per line: every one that exists, or, if
# neither exists, the one for the login shell.
target_rc_files() {
    local found=0 f
    for f in "$BASHRC" "$ZSHRC"; do
        if [ -e "$f" ]; then
            printf '%s\n' "$f"
            found=1
        fi
    done
    [ "$found" -eq 1 ] && return 0
    case "${SHELL##*/}" in
        zsh) printf '%s\n' "$ZSHRC" ;;
        *)   printf '%s\n' "$BASHRC" ;;
    esac
}

# render_rc <rc file> <output>: the rc file without our block and without the
# old shellfu loader, followed by the current block. A block whose end line is
# missing is left alone rather than eating the rest of the file.
render_rc() {
    local rc="$1" out="$2" path
    path="$(repo_path_for_rc)"

    if [ -f "$rc" ]; then
        awk -v begin="$MARK_BEGIN" -v end="$MARK_END" -v legacy="$LEGACY_BEGIN" '
            function flush_blank() { while (blank > 0) { print ""; blank-- } }
            mode == "" && ($0 == begin || $0 == legacy) {
                mode = ($0 == begin) ? "managed" : "legacy"
                buf = $0
                next
            }
            mode != "" {
                buf = buf "\n" $0
                if ((mode == "managed" && $0 == end) || (mode == "legacy" && $0 == "fi")) {
                    mode = ""
                    buf = ""
                }
                next
            }
            # Hold blank lines back so trailing ones are dropped.
            /^[ \t]*$/ { blank++; next }
            { flush_blank(); print }
            END { if (mode != "") { flush_blank(); print buf } }
        ' "$rc" >"$out"
    else
        : >"$out"
    fi

    [ -s "$out" ] && printf '\n' >>"$out"
    {
        printf '%s\n' "$MARK_BEGIN"
        printf '%s\n' "# Added by dotfiles (shell/setup.sh). Edit the files in shell/ there, not this block."
        printf 'export DOTFILES_DIR="%s"\n' "$path"
        printf '%s\n' 'if [ -r "$DOTFILES_DIR/shell/init.sh" ]; then . "$DOTFILES_DIR/shell/init.sh"; fi'
        printf '%s\n' "$MARK_END"
    } >>"$out"
}

update_rc() {
    local rc="$1" new="$WORK_DIR/rc.new" had_legacy=0

    render_rc "$rc" "$new"

    if [ -f "$rc" ] && cmp -s "$rc" "$new"; then
        log_info "Already set up: $rc"
        return 0
    fi

    if [ -f "$rc" ]; then
        grep -qxF -- "$LEGACY_BEGIN" "$rc" && had_legacy=1
        backup_item "$COMPONENT" "$(basename "$rc" | sed 's/^\.//')" "$rc" copy
        # Written through the existing path (not mv) so a symlinked rc file
        # stays a symlink and permissions are kept.
        cat "$new" >"$rc"
    elif path_exists "$rc"; then
        die "$rc is a broken symlink; fix or remove it and re-run."
    else
        mkdir -p "$(dirname "$rc")"
        cat "$new" >"$rc"
        log_info "Created $rc"
    fi

    if [ "$had_legacy" -eq 1 ] && ! grep -qxF -- "$LEGACY_BEGIN" "$rc"; then
        log_info "Removed the old shellfu loader from $rc"
    fi
    log_success "$rc now loads $INIT_SOURCE"
}

main() {
    check_prerequisites
    validate_sources

    local rc rcs
    rcs="$(target_rc_files)"
    while IFS= read -r rc; do
        [ -n "$rc" ] || continue
        update_rc "$rc"
    done <<EOF
$rcs
EOF

    link_config "$COMPONENT" inputrc "$INPUTRC_SOURCE" "$INPUTRC_TARGET"

    local session
    session="$(backup_session_if_used)"
    [ ! -d "$session/$COMPONENT" ] || log_info "Previous rc files: $session/$COMPONENT"

    log_success "Shell is ready. Run 'reload' (or open a new terminal) to pick up changes."
}

main "$@"
