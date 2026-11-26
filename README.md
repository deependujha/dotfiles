# dotfiles

My development environment: shell (aliases, functions, prompt, key bindings), Vim, Neovim (AstroNvim) and Zellij, for Linux and macOS.

This repository, cloned at `~/dotfiles`, is the single source of truth. The configs in the home directory are symlinks into it, and the shell loads its files straight from it. The loop is: edit a file here, `make update` if needed, `make push`.

## Setup

```bash
git clone git@github.com:deependujha/dotfiles.git ~/dotfiles
cd ~/dotfiles
make update
```

`make update` applies everything to the machine. It is safe to run as often as you like; a run with nothing to change takes a couple of seconds.

On a machine where you only want the result (a cloud box, say), one command clones to `~/dotfiles` and applies:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/deependujha/dotfiles/main/install.sh)
```

## Commands

| Command | What it does |
|---------|--------------|
| `make update` | Apply everything in the repo to this machine |
| `make shell` / `vim` / `nvim` / `zellij` | Apply one component |
| `make push` | Commit all changes and push. `make push m="message"` sets the message (default: `update`) |
| `make pull` | Pull from GitHub, then apply |
| `make status` | Uncommitted changes, unpushed commits, what the snapshot holds |
| `make restore` | Put back what the last update replaced |
| `make check` | Syntax-check the scripts (runs before every push) |

From any directory, the `dots` shell function runs the same targets: `dots update`, `dots push m="new alias"`. `dots` alone is `cd ~/dotfiles`.

## Changing things

| I want to | Edit | Then |
|-----------|------|------|
| Add an alias | [`shell/aliases.sh`](shell/aliases.sh) | `reload` |
| Add a function | [`shell/functions.sh`](shell/functions.sh) | `reload` |
| Change the prompt | [`shell/prompt.bash`](shell/prompt.bash) | `reload` |
| Add a key binding | [`shell/inputrc`](shell/inputrc) | new terminal |
| Set something on this machine only | `shell/local.sh` (not tracked) | `reload` |
| Change Vim | [`vim/vimrc`](vim/vimrc) | restart Vim; `make vim` after adding a plugin |
| Change Neovim | [`nvim/config/`](nvim/config) | restart Neovim; `make nvim` after adding a plugin or tool |
| Change Zellij | [`zellij/config.kdl`](zellij/config.kdl) | Zellij reloads it itself |

Edits take effect without `make update`, because the live files are the repo files. `make update` is for the things a symlink can't do: installing plugins, and wiring up a file or component that is new. When the change works, `make push`.

`reload` re-reads the rc file in the current shell.

## What gets applied

| Component | In the home directory | From the repo |
|-----------|-----------------------|---------------|
| shell | a marked block in `~/.bashrc` and `~/.zshrc` | sources [`shell/init.sh`](shell/init.sh) |
| shell | `~/.inputrc` | symlink to `shell/inputrc` |
| vim | `~/.vimrc` | symlink to `vim/vimrc`; vim-plug and plugins installed |
| nvim | `~/.config/nvim` | symlink to `nvim/config`; plugins, language servers and treesitter parsers installed |
| zellij | `~/.config/zellij/config.kdl` | symlink to `zellij/config.kdl` |

The rc files are not symlinked, because installers append machine-specific lines to them (PATH, nvm, cargo). `make update` only manages this block, replacing it in place on each run:

```bash
# >>> dotfiles shell >>>
# Added by dotfiles (shell/setup.sh). Edit the files in shell/ there, not this block.
export DOTFILES_DIR="$HOME/dotfiles"
if [ -r "$DOTFILES_DIR/shell/init.sh" ]; then . "$DOTFILES_DIR/shell/init.sh"; fi
# <<< dotfiles shell <<<
```

`init.sh` loads `aliases.sh`, `functions.sh`, `prompt.bash` (bash only) and, if it exists, `local.sh`. Anything else you want in every shell belongs in one of those files, not in `~/.bashrc`.

Nothing in `$HOME` is touched until the checks pass: the shell files must parse, `zellij setup --check` must accept the config, and the tools a component needs must be installed. The scripts never install system packages; they print the install command for your OS and stop.

## Snapshot

When `make update` is about to replace something in the home directory that didn't come from this repo, it saves it first:

```text
~/dotfiles/snapshot/          ignored by git
├── shell/
│   ├── manifest              name -> original path
│   ├── bashrc                ~/.bashrc as it was before the block changed
│   └── inputrc               the previous ~/.inputrc
└── nvim/
    └── nvim-config/          the previous ~/.config/nvim
```

There is one snapshot. The next update that replaces something overwrites it; an update that replaces nothing leaves it alone. The configs themselves have their history in git, so the snapshot only covers what was on the machine before.

`make restore` shows what it will do, asks, and copies the snapshot back. What is in place at that moment becomes the new snapshot. `make update` applies the repo again.

## Platforms and dependencies

- **Linux**: Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE and Alpine get tailored install hints.
- **macOS**: works with the system Bash 3.2 and system Vim.

Needs **bash**, **git**, **make** and **curl**. Per component: **vim** (a full build with `+eval`, not `vim-tiny`), **neovim** ≥ 0.11 with a C compiler (plus `rg`, `node`, `go`, `fd`, `lazygit`, `deno` for the full feature set), and **zellij**.

## Layout

```text
Makefile              the commands above
install.sh            runs the component setup scripts (make update); also the curl bootstrap
common/               logging, snapshot and link helpers, OS detection
shell/                init.sh, aliases.sh, functions.sh, prompt.bash, inputrc, setup.sh
vim/                  vimrc, setup.sh, notes/
nvim/                 config/ (→ ~/.config/nvim), setup.sh, notes/
zellij/               config.kdl, setup.sh
scripts/restore.sh    make restore
snapshot/             what the last update replaced (not tracked)
```

### Adding a component

Create `<tool>/` with the config and a `setup.sh`. For a config that is one file or directory, the script is mostly one call:

```bash
link_config "$COMPONENT" <name> "$SCRIPT_DIR/<file>" "$HOME/<target>"
```

It links the target to the repo and moves whatever was there into the snapshot. [`zellij/setup.sh`](zellij/setup.sh) is the shortest example to copy. `make <tool>` works as soon as the script exists; add the name to `DEFAULT_COMPONENTS` in `install.sh` to include it in `make update`.

More detail: [vim/notes/README.md](vim/notes/README.md), [vim/notes/cheatsheet.md](vim/notes/cheatsheet.md), [nvim/notes/README.md](nvim/notes/README.md), [nvim/notes/cheatsheet.md](nvim/notes/cheatsheet.md).
