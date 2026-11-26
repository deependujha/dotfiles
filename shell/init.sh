# shellcheck shell=bash
# Entry point for the shell configuration. ~/.bashrc and ~/.zshrc source this
# file (shell/setup.sh adds the line), and it loads everything else from the
# repository, so edits here take effect in the next shell without re-applying.
#
#   aliases.sh     aliases
#   functions.sh   functions
#   prompt.bash    the bash prompt (PS1)
#   local.sh       optional, not tracked by git: things for this machine only

: "${DOTFILES_DIR:=$HOME/dotfiles}"

for _dotfiles_f in aliases.sh functions.sh; do
    # shellcheck disable=SC1090
    [ -r "$DOTFILES_DIR/shell/$_dotfiles_f" ] && . "$DOTFILES_DIR/shell/$_dotfiles_f"
done
unset _dotfiles_f

# shellcheck source=prompt.bash
[ -n "${BASH_VERSION:-}" ] && [ -r "$DOTFILES_DIR/shell/prompt.bash" ] && . "$DOTFILES_DIR/shell/prompt.bash"

# shellcheck disable=SC1091
[ -r "$DOTFILES_DIR/shell/local.sh" ] && . "$DOTFILES_DIR/shell/local.sh"

true
