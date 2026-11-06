# dotfiles

Personal development environment configuration with a one-command bootstrap for macOS and Linux.

The goal is one command on a fresh machine and nothing to do by hand afterwards. Configs are **symlinked** from this repository, so the repo is always the single source of truth.

| Component | Status |
|-----------|--------|
| Vim       | ✅ supported |
| Neovim, Zellij, Git, Shell, terminal emulators | planned |

## Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/deependujha/dotfiles/main/install.sh)
```

What this does:

1. Clones this repository to `~/.local/share/dotfiles`. If it is already there, it fast-forwards it instead (a checkout with local changes is left alone).
2. Runs each component's setup script. For Vim that means:
   - downloading [vim-plug](https://github.com/junegunn/vim-plug) if it is missing
   - backing up your existing `~/.vimrc` / `~/.vim`
   - symlinking `~/.vimrc` to `vim/vimrc`
   - installing all plugins headlessly
3. Prints a summary that includes where the backup went.

When it exits successfully, Vim is ready to use. You don't need to run `:PlugInstall` yourself.

Environment overrides:

| Variable | Default | Purpose |
|----------|---------|---------|
| `DOTFILES_DIR` | `~/.local/share/dotfiles` | Where the bootstrap clones the repo |
| `DOTFILES_REPO` | `https://github.com/deependujha/dotfiles.git` | Repo to clone |
| `DOTFILES_BRANCH` | `main` | Branch to clone |
| `DOTFILES_BACKUP_ROOT` | `~/dotfiles_backup` | Where backups are written |

### From a local clone

```bash
git clone https://github.com/deependujha/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```

When `install.sh` runs from inside a checkout, it uses that checkout directly and doesn't clone anything.

## Selective installation

```bash
bash install.sh          # default components (currently: vim)
bash install.sh vim      # only the named components
bash install.sh --help   # list available components
```

## Backup and restore

Before the installer replaces anything, it saves the previous version to a new timestamped directory. Existing backups are never overwritten:

```text
~/dotfiles_backup/
└── 2026-11-06_103000/
    └── vim/
        ├── manifest          # name -> original path
        ├── vimrc             # your previous ~/.vimrc (file or symlink, kept as-is)
        └── vim-directory/    # snapshot of your previous ~/.vim
```

- Only files the installer is about to change get backed up, and only the first time. Once `~/.vimrc` points at this repo, re-running the installer creates no new backups.
- `~/.vimrc` is *moved* into the backup and then replaced by the symlink. `~/.vim` stays in place, because the installer only adds to it, and a snapshot *copy* goes into the backup.
- Backups live outside the repository, so deleting the repo doesn't delete them.

To restore:

```bash
bash ~/.local/share/dotfiles/scripts/restore.sh            # choose from a list
bash ~/.local/share/dotfiles/scripts/restore.sh 2026-11-06_103000
```

The restore script shows exactly what it will do and asks before changing anything. Whatever is currently in place gets moved to a new `<timestamp>_pre-restore` backup first, so a restore can itself be undone. Symlinks into this repo are removed, since they hold no data.

If you had no Vim config before installing, no backup was made and there is nothing to restore. To uninstall in that case, run `rm ~/.vimrc`, which only removes the symlink.

## Updating

```bash
# Option 1: re-run the bootstrap command (it pulls, then re-applies)
bash <(curl -fsSL https://raw.githubusercontent.com/deependujha/dotfiles/main/install.sh)

# Option 2: by hand
git -C ~/.local/share/dotfiles pull --ff-only
bash ~/.local/share/dotfiles/install.sh
```

Because `~/.vimrc` is a symlink, a `git pull` alone updates your Vim settings. Re-run the installer when plugins were added so they get installed.

## Supported platforms

- **macOS**: tested with the system Bash 3.2 and system Vim 9.1.
- **Linux**: Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE and Alpine get tailored install hints.

Dependencies: **bash**, **git**, **curl**, **vim** (a full build with `+eval`, not `vim-tiny`). The installer never installs system packages. If something is missing, it stops before changing anything and prints the install command for your OS.

## Repository layout

```text
install.sh            entry point: bootstrap + run component setup scripts
common/utils.sh       logging and small helpers
common/backup.sh      timestamped backups + manifest
common/detect_os.sh   OS / package-manager detection, install hints
vim/                  vimrc, setup.sh, notes/
scripts/restore.sh    restore from a backup
```

### Adding a component later

Create `<tool>/setup.sh`, which can use the helpers in `common/`, and optionally add the tool to `DEFAULT_COMPONENTS` in `install.sh`. `install.sh <tool>` picks it up automatically, and backups and restore work the same way through `backup_item`.

See [vim/notes/README.md](vim/notes/README.md) for Vim specifics and [vim/notes/cheatsheet.md](vim/notes/cheatsheet.md) for a quick reference.
