# shellcheck shell=bash
# Shell functions. Aliases go in aliases.sh, the prompt in prompt.bash.
#
# Loaded by init.sh in every interactive bash and zsh session. After editing,
# run `reload` (or open a new terminal); there is nothing to re-apply.
#
# Keep it portable: it has to work in zsh and in macOS's Bash 3.2.

# ---------------------------------------------------------------------------
# Dotfiles
# ---------------------------------------------------------------------------

# dots                 cd into the dotfiles repository
# dots update          run a Makefile target there from anywhere
# dots push m="msg"    (see `dots help` for the targets)
dots() {
    if [ $# -eq 0 ]; then
        cd "$DOTFILES_DIR" || return 1
    else
        make --no-print-directory -C "$DOTFILES_DIR" "$@"
    fi
}

# Re-read the rc file in the current shell, picking up edits to these files.
reload() {
  local rc
  if [[ -n $ZSH_VERSION ]]; then
    rc=~/.zshrc
  elif [[ -n $BASH_VERSION ]]; then
    rc=~/.bashrc
  else
    echo "reload: unsupported shell (not bash or zsh)" >&2
    return 1
  fi

  if [[ -f $rc ]]; then
    source "$rc" && echo "reloaded $rc"
  else
    echo "reload: $rc not found" >&2
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Git
# ---------------------------------------------------------------------------

work() {
    cd "$HOME/codes/oss/lightning-ai/$1"
}

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
        echo "Usage: clone <repo_url>"
        return 1
    fi

    local repo_url="$1"
    local repo_name
    local fork_url

    repo_name="${repo_url##*/}"
    repo_name="${repo_name%.git}"

    if [[ "$repo_url" == *"github.com:deependujha/"* || "$repo_url" == *"github.com/deependujha/"* ]]; then
        fork_url="$repo_url"
    else
        fork_url="git@github.com:deependujha/${repo_name}.git"
    fi

    echo "🍴 Cloning: $fork_url"
    git clone "$fork_url" || return 1

    cd "$repo_name" || return 1

    if [ "$repo_url" != "$fork_url" ]; then
        echo "🔗 Adding upstream: $repo_url"
        git remote add upstream "$repo_url" || return 1
    else
        echo "ℹ️ Already your repository. Skipping upstream."
    fi

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
