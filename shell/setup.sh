#!/usr/bin/env bash
# Shell component: make bash and zsh load shell/aliases.sh.
#
# Normally run by install.sh, but safe to run directly:  bash shell/setup.sh
#
# Unlike the other components, the rc files are not symlinked: ~/.bashrc and
# ~/.zshrc hold machine-specific things (PATH, tool init lines that installers
# append) that don't belong in the repository. Instead a small marked block
# that sources shell/aliases.sh is appended to them. Re-runs replace that
# block in place, so it never piles up.
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
ALIASES_SOURCE="$SCRIPT_DIR/aliases.sh"
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

# Refuse to hook up a file the shells can't parse: a syntax error in it would
# show up in every new terminal. Runs before anything in $HOME is touched.
validate_aliases() {
    [ -f "$ALIASES_SOURCE" ] || die "$ALIASES_SOURCE not found. Nothing was changed."
    local sh out
    for sh in bash zsh; do
        command_exists "$sh" || continue
        if ! out="$("$sh" -n "$ALIASES_SOURCE" 2>&1)"; then
            log_error "$sh found a syntax error in $ALIASES_SOURCE:"
            printf '%s\n' "$out" | sed 's/^/    /' >&2
            die "Nothing was changed."
        fi
    done
    log_success "aliases.sh parses cleanly."
}

# The path as it should appear in the rc file: $HOME-relative when possible,
# so the same line works if the home directory is ever renamed.
aliases_path_for_rc() {
    local p="$ALIASES_SOURCE"
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
    path="$(aliases_path_for_rc)"

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
        printf '%s\n' "# Added by dotfiles (shell/setup.sh). Put shortcuts in shell/aliases.sh, not here."
        printf 'if [ -r "%s" ]; then . "%s"; fi\n' "$path" "$path"
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
    log_success "$rc now loads $ALIASES_SOURCE"
}

main() {
    check_prerequisites
    validate_aliases

    local rc rcs
    rcs="$(target_rc_files)"
    while IFS= read -r rc; do
        [ -n "$rc" ] || continue
        update_rc "$rc"
    done <<EOF
$rcs
EOF

    local session
    session="$(backup_session_if_used)"
    [ -z "$session" ] || log_info "Backup of previous rc files: $session/$COMPONENT"

    log_success "Shell shortcuts are ready. Open a new terminal (or source your rc file) to use them."
}

main "$@"
