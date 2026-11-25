# shellcheck shell=bash
# Personal shell shortcuts: aliases and small functions.
#
# This file is sourced by every interactive bash and zsh session (shell/setup.sh
# adds the loader line to ~/.bashrc / ~/.zshrc). To add a shortcut, write it in
# the matching section below, or start a new section, then open a new terminal
# or re-source your rc file (`source ~/.bashrc` / `source ~/.zshrc`).
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

gstatus() {
    git status
}

# Push the current branch to origin.
gpush() {
    local branch
    branch="$(git rev-parse --abbrev-ref HEAD)"
    if [ -n "$branch" ]; then
        git push origin "$branch"
    else
        echo "Error: Could not determine the current branch name."
        return 1
    fi
}

# Clone your fork of a repository and configure the original as upstream.
clone() {
    if [ -z "$1" ]; then
        echo "Usage: clone <upstream_repo_url>"
        return 1
    fi

    local repo_url="$1"
    local repo_name
    local fork_url

    repo_name="${repo_url##*/}"
    repo_name="${repo_name%.git}"
    fork_url="git@github.com:deependujha/${repo_name}.git"

    echo "🍴 Cloning your fork: $fork_url"
    git clone "$fork_url" || return 1

    cd "$repo_name" || return 1

    echo "🔗 Adding upstream: $repo_url"
    git remote add upstream "$repo_url" || return 1

    echo "✅ Repository setup complete!"
    git remote -v
}

# Print the current branch name.
current_branch() {
    git rev-parse --abbrev-ref HEAD
}

# True if the working tree has no uncommitted changes.
is_git_clean() {
    [ -z "$(git status --porcelain)" ]
}

# stash_changes <message>
stash_changes() {
    git stash push -m "$1"
}

pop_stash() {
    git stash pop
}

# ---------------------------------------------------------------------------
# Python / uv   (named environments live in ~/.uvenv)
# ---------------------------------------------------------------------------

# Activate the project-local environment.
alias act='source .venv/bin/activate'

ensure_uvenv_dir() {
    local uvenv_dir="$HOME/.uvenv"
    if [ ! -d "$uvenv_dir" ]; then
        echo "📁 Creating $uvenv_dir directory..."
        mkdir -p "$uvenv_dir"
    fi
}

# List the named environments.
listenv() {
    ls "$HOME/.uvenv"
}

# sourceenv <env_name>: activate ~/.uvenv/<env_name>.
sourceenv() {
    if [ -z "$1" ]; then
        echo "Usage: sourceenv <env_name>"
        return 1
    fi

    ensure_uvenv_dir

    local env_path="$HOME/.uvenv/$1/bin/activate"

    if [ -f "$env_path" ]; then
        # shellcheck disable=SC1090
        source "$env_path"
        echo "Activated env: $1"
    else
        echo "❌ No such env: $1 at $env_path"
        return 1
    fi
}

# editinstall <env_name>: create ~/.uvenv/<env_name> if needed, activate it,
# and install the project in the current directory in editable mode.
editinstall() {
    if [ -z "$1" ]; then
        echo "Usage: editinstall <env_name>"
        return 1
    fi

    ensure_uvenv_dir

    local env_dir="$HOME/.uvenv/$1"
    local activate_path="$env_dir/bin/activate"

    if [ ! -f "$activate_path" ]; then
        echo "🔧 Creating env: $1 at $env_dir"
        uv venv "$env_dir" || return 1
    fi

    echo "🐍 Activating env: $1"
    # shellcheck disable=SC1090
    source "$activate_path"

    echo "📦 Installing current project in editable mode"
    uv pip install -e .
}

# ---------------------------------------------------------------------------
# Terminal
# ---------------------------------------------------------------------------

# Push the current screen contents up into scrollback, then clear.
alias clean="yes '' | head -n 1000; clear"
