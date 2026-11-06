#!/usr/bin/env bash
# Vim component: vim-plug, ~/.vimrc symlink, headless plugin install.
#
# Normally run by install.sh, but safe to run directly:  bash vim/setup.sh
#
# Order matters: everything that can fail without touching $HOME (prereq
# checks, downloading vim-plug) happens before any backup or symlink, so a
# network failure leaves the existing configuration untouched.

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../common/utils.sh
. "$REPO_DIR/common/utils.sh"
# shellcheck source=../common/detect_os.sh
. "$REPO_DIR/common/detect_os.sh"
# shellcheck source=../common/backup.sh
. "$REPO_DIR/common/backup.sh"

COMPONENT="vim"
VIMRC_SOURCE="$SCRIPT_DIR/vimrc"
VIMRC_TARGET="$HOME/.vimrc"
VIM_DIR="$HOME/.vim"
PLUG_FILE="$VIM_DIR/autoload/plug.vim"
VIM_PLUG_URL="${VIM_PLUG_URL:-https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim}"
MANUAL_PLUG_CMD="vim +'PlugInstall --sync' +qa"

OS=''
VIM_VERSION=0
VIM_HAS_CLIPBOARD=0
VIM_HAS_UNNAMEDPLUS=0
VIM_HAS_TEXTYANKPOST=0
PLUG_DOWNLOADED=''       # path to a freshly downloaded plug.vim, if any

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-vim.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# ---------------------------------------------------------------------------

check_prerequisites() {
    OS="$(detect_os)"
    [ "$OS" != unsupported ] || die "Unsupported OS: $(uname -s). Only macOS and Linux are supported."
    log_info "Detected OS: $OS"

    local missing=0 tool
    for tool in vim git curl; do
        if ! command_exists "$tool"; then
            log_error "'$tool' is not installed. Install it with:  $(install_hint "$tool")"
            missing=1
        fi
    done
    [ "$missing" -eq 0 ] || die "Missing prerequisites (see above). Nothing was changed."
    log_info "Using $(command -v vim)"
}

# Ask Vim itself which features it has. A build without +eval (vim-tiny)
# can't run vim-plug at all, and won't write the probe file.
probe_vim() {
    local out="$WORK_DIR/probe"
    # shellcheck disable=SC2016  # $VAR is expanded by Vim, not the shell
    DOTFILES_PROBE_OUT="$out" vim -Nes -u NONE -i NONE \
        -c 'call writefile([v:version, has("clipboard"), has("unnamedplus"), exists("##TextYankPost")], $DOTFILES_PROBE_OUT)' \
        -c 'qa!' </dev/null >/dev/null 2>&1 || true

    if [ ! -s "$out" ]; then
        die "This Vim build lacks +eval (probably vim-tiny) and cannot run plugins. Install a full Vim:  $(install_hint vim)"
    fi
    VIM_VERSION="$(sed -n 1p "$out")"
    VIM_HAS_CLIPBOARD="$(sed -n 2p "$out")"
    VIM_HAS_UNNAMEDPLUS="$(sed -n 3p "$out")"
    VIM_HAS_TEXTYANKPOST="$(sed -n 4p "$out")"

    log_info "Vim version: $((VIM_VERSION / 100)).$((VIM_VERSION % 100))"
    if [ "$VIM_VERSION" -lt 800 ]; then
        log_warn "Vim 8.0+ is recommended; some options in the vimrc may not exist in this version."
    fi
}

vimrc_is_managed() {
    is_link_to "$VIMRC_TARGET" "$VIMRC_SOURCE"
}

# Vim reads only the first vimrc it finds (~/.vimrc wins), so these would
# silently stop being used once we link ~/.vimrc.
warn_shadowed_configs() {
    local f
    for f in "$VIM_DIR/vimrc" "${XDG_CONFIG_HOME:-$HOME/.config}/vim/vimrc"; do
        if path_exists "$f"; then
            log_warn "$f exists but will be ignored by Vim because ~/.vimrc takes precedence."
        fi
    done
}

# Fetch vim-plug into a temp dir first; only moved into ~/.vim later.
download_vim_plug() {
    if [ -s "$PLUG_FILE" ]; then
        log_info "vim-plug already installed: $PLUG_FILE"
        return 0
    fi
    log_info "Downloading vim-plug..."
    local tmp="$WORK_DIR/plug.vim"
    if ! curl -fsSL --retry 2 --connect-timeout 15 -o "$tmp" "$VIM_PLUG_URL"; then
        log_error "Failed to download vim-plug from $VIM_PLUG_URL (network issue?)."
        die "Nothing was changed. Check your connection and re-run the installer."
    fi
    grep -q 'plug#begin' "$tmp" || die "Downloaded file doesn't look like vim-plug: $VIM_PLUG_URL. Nothing was changed."
    PLUG_DOWNLOADED="$tmp"
}

# Back up only what we are about to change, and only the first time:
# once ~/.vimrc points at this repo, the pre-dotfiles state is already saved.
backup_existing() {
    if vimrc_is_managed; then
        log_info "$VIMRC_TARGET already links to this repository; no backup needed."
    else
        # ~/.vim: we only add to it (autoload/plug.vim, plugged/, undo/), so
        # keep it in place and save a snapshot. A broken symlink or a stray
        # file named .vim can't be used as a directory, so move those aside.
        if [ -d "$VIM_DIR" ]; then
            backup_item "$COMPONENT" vim-directory "$VIM_DIR" copy
        elif path_exists "$VIM_DIR"; then
            backup_item "$COMPONENT" vim-directory "$VIM_DIR" move
        fi

        # ~/.vimrc (file, symlink elsewhere, or broken symlink) gets replaced.
        if path_exists "$VIMRC_TARGET"; then
            backup_item "$COMPONENT" vimrc "$VIMRC_TARGET" move
        fi
    fi

    # A zero-byte or dangling plug.vim would block installation; set it aside.
    # Recorded after the ~/.vim snapshot so restore puts it back last.
    if [ -n "$PLUG_DOWNLOADED" ] && path_exists "$PLUG_FILE"; then
        backup_item "$COMPONENT" plug.vim "$PLUG_FILE" move
    fi
}

prepare_directories() {
    mkdir -p "$VIM_DIR/autoload" "$VIM_DIR/plugged" "$VIM_DIR/undo"
}

install_vim_plug() {
    [ -n "$PLUG_DOWNLOADED" ] || return 0
    mv "$PLUG_DOWNLOADED" "$PLUG_FILE"
    log_success "Installed vim-plug: $PLUG_FILE"
}

link_vimrc() {
    if vimrc_is_managed; then
        log_info "Symlink already correct: $VIMRC_TARGET -> $VIMRC_SOURCE"
        return 0
    fi
    # backup_existing moved anything here away; never clobber if it didn't.
    path_exists "$VIMRC_TARGET" && die "$VIMRC_TARGET still exists; refusing to overwrite it."
    ln -s "$VIMRC_SOURCE" "$VIMRC_TARGET"
    log_success "Linked $VIMRC_TARGET -> $VIMRC_SOURCE"
}

# Prints names of declared plugins whose directories are missing or empty.
# vim-plug doesn't turn clone failures into a non-zero exit status, so this
# check is what actually decides success.
missing_plugins() {
    local script="$WORK_DIR/verify.vim" out="$WORK_DIR/missing"
    cat >"$script" <<'VIM'
if !exists('g:plugs')
  call writefile(['(vim-plug did not load)'], $DOTFILES_PLUG_OUT)
  qa!
endif
let s:missing = []
for [s:name, s:spec] in items(g:plugs)
  if !isdirectory(s:spec.dir) || empty(glob(s:spec.dir . '/*', 1, 1))
    call add(s:missing, s:name)
  endif
endfor
call writefile(s:missing, $DOTFILES_PLUG_OUT)
qa!
VIM
    rm -f "$out"
    DOTFILES_PLUG_OUT="$out" vim -Nes -u "$VIMRC_TARGET" -i NONE -S "$script" </dev/null >/dev/null 2>&1 || true
    if [ -f "$out" ]; then
        cat "$out"
    else
        echo '(could not evaluate vimrc)'
    fi
}

install_plugins() {
    local log="$WORK_DIR/plug.log" rc=0 missing

    log_info "Installing Vim plugins (headless PlugInstall)..."
    # -N -e -s: silent Ex mode, no UI. stdin from /dev/null so Vim can't read
    # the installer itself when it was piped in, and exits at EOF regardless.
    # The [Plugins] status buffer is written out so failures can be shown.
    # shellcheck disable=SC2016  # $VAR is expanded by Vim, not the shell
    DOTFILES_PLUG_LOG="$log" vim -Nes -u "$VIMRC_TARGET" -i NONE \
        -c 'PlugInstall --sync' \
        -c 'silent! execute "write!" fnameescape($DOTFILES_PLUG_LOG)' \
        -c 'qa!' </dev/null >/dev/null 2>&1 || rc=$?

    missing="$(missing_plugins)"
    if [ "$rc" -eq 0 ] && [ -z "$missing" ]; then
        log_success "All plugins installed."
        return 0
    fi

    [ "$rc" -eq 0 ] || log_error "Headless Vim exited with status $rc."
    if [ -n "$missing" ]; then
        log_error "Plugins not installed: $(printf '%s' "$missing" | tr '\n' ' ')"
    fi
    if [ -s "$log" ]; then
        log_error "vim-plug output:"
        sed 's/^/    /' "$log" >&2
    fi
    log_error "Your vimrc is linked, but plugins are incomplete. Fix the cause (often network or git access) and run:"
    log_error "    $MANUAL_PLUG_CMD"
    log_error "or re-run the installer."
    return 1
}

# Report what the vimrc's clipboard block will actually do with this Vim.
report_clipboard() {
    if [ "$VIM_HAS_UNNAMEDPLUS" = 1 ]; then
        log_success "Clipboard: +clipboard with unnamedplus; yanks go to the system clipboard."
        if [ "$OS" = linux ] && [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
            log_warn "Clipboard: no DISPLAY/WAYLAND_DISPLAY in this session (SSH/headless?); the system clipboard is unavailable here."
        fi
        return 0
    fi

    if [ "$VIM_HAS_CLIPBOARD" = 1 ]; then
        if [ "$OS" = macos ]; then
            log_success "Clipboard: +clipboard (macOS); vimrc uses clipboard=unnamed, which is the system clipboard on macOS."
        else
            log_warn "Clipboard: this Vim has +clipboard but not unnamedplus; yanks go to the X PRIMARY selection, not CLIPBOARD."
            log_warn "For full support: $(install_hint vim-clipboard)"
        fi
        return 0
    fi

    log_warn "Clipboard: this Vim was built WITHOUT clipboard support (-clipboard)."
    if [ "$VIM_HAS_TEXTYANKPOST" != 1 ]; then
        log_warn "It is also too old for the yank fallback. Install a full Vim: $(install_hint vim-clipboard)"
        return 0
    fi

    local tool=''
    if command_exists pbcopy; then
        tool=pbcopy
    elif [ -n "${WAYLAND_DISPLAY:-}" ] && command_exists wl-copy; then
        tool=wl-copy
    elif [ -n "${DISPLAY:-}" ] && command_exists xclip; then
        tool=xclip
    elif [ -n "${DISPLAY:-}" ] && command_exists xsel; then
        tool=xsel
    fi

    if [ -n "$tool" ]; then
        log_warn "Fallback active: yanks are piped to '$tool'. Pasting from the OS clipboard inside Vim (\"+p) won't work;"
        log_warn "use your terminal's paste instead. For native support: $(install_hint vim-clipboard)"
    else
        log_warn "No clipboard tool found (pbcopy / wl-copy / xclip / xsel), so yanks stay inside Vim."
        log_warn "Fix with either:  $(install_hint vim-clipboard)"
        log_warn "             or:  $(install_hint clipboard-tool)"
    fi
}

main() {
    check_prerequisites
    probe_vim
    download_vim_plug
    warn_shadowed_configs
    backup_existing
    prepare_directories
    install_vim_plug
    link_vimrc
    local plugins_ok=0
    install_plugins || plugins_ok=1
    report_clipboard

    local session
    session="$(backup_session_if_used)"
    [ -z "$session" ] || log_info "Backup of previous Vim config: $session/$COMPONENT"

    if [ "$plugins_ok" -ne 0 ]; then
        log_error "Vim setup finished with errors."
        return 1
    fi
    log_success "Vim is ready."
}

main "$@"
