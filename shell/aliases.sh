# shellcheck shell=bash
# Aliases. Functions go in functions.sh, the prompt in prompt.bash.
#
# Loaded by init.sh in every interactive bash and zsh session. After editing,
# run `reload` (or open a new terminal); there is nothing to re-apply.
#
# Keep it portable: it has to work in zsh and in macOS's Bash 3.2, and it must
# stay quiet and fast, since it runs on every shell start.

# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

alias gc='git add .; git commit'
alias gcu='git add .; git commit -m "update"'
alias gcp='git add .; git commit -m "update"; git push'
alias gcl='git diff'
alias gl='git log --oneline'
alias gsync='git checkout main && (git remote | grep -q "^upstream$" && git pull upstream main || git pull origin main) && git push origin main'
alias gmsync='git checkout master && git pull upstream master && git push origin master'

# ---------------------------------------------------------------------------
# Python / uv
# ---------------------------------------------------------------------------

# Activate the project-local environment.
alias act='source .venv/bin/activate'

# ---------------------------------------------------------------------------
# Terminal
# ---------------------------------------------------------------------------

# Push the current screen contents up into scrollback, then clear.
alias clean="yes '' | head -n 1000; clear"
