# Vim configuration

## What it provides

- **Plugins** via [vim-plug](https://github.com/junegunn/vim-plug), installed under `~/.vim/plugged`. Currently just `vim-polyglot`, for syntax and indentation across many languages.
- **Indentation:** 4-space indents (`expandtab`) everywhere, with Python, Rust and C/C++ set explicitly.
- **Editor UI:** relative line numbers, cursorline, sign column, `scrolloff=8`, and visible tabs and trailing spaces.
- **Search:** smart-case search. Press `Esc` to clear the highlight.
- **Persistent undo** in `~/.vim/undo/`, so undo history survives closing a file.
- **System clipboard:** yanking with `y`, `yy` or a visual selection plus `y` copies to the OS clipboard (see below).
- **Markdown:** wrapping and spell check for Markdown files.

## How installation works

`vim/setup.sh` (called by `install.sh`) runs these steps in order:

1. Checks the OS and that `vim`, `git` and `curl` exist, and asks Vim which features it was built with.
2. Downloads `plug.vim` to a temp file if `~/.vim/autoload/plug.vim` is missing. Up to here nothing in `$HOME` has changed, so a network failure leaves your config untouched.
3. Backs up `~/.vimrc` (moved) and `~/.vim` (copied), unless `~/.vimrc` already links to this repo.
4. Creates `~/.vim/{autoload,plugged,undo}`, installs `plug.vim`, and links `~/.vimrc` to `vim/vimrc`.
5. Runs `vim -Nes -u ~/.vimrc -i NONE -c 'PlugInstall --sync' -c 'qa!' </dev/null`, then re-reads the vimrc to check that every declared plugin directory exists and isn't empty. vim-plug doesn't report clone failures through Vim's exit code, so the installer checks the plugin directories itself.
6. Reports the clipboard situation.

## Updating the configuration

Edit `vim/vimrc` in the repo. `~/.vimrc` is a symlink, so the change applies to the next Vim you start. Commit and push to share it with your other machines. On those machines, `git pull` is enough.

## Adding a plugin

1. Add a line between `plug#begin` and `plug#end` in `vim/vimrc`:
   ```vim
   Plug 'tpope/vim-surround'
   ```
2. Install it with either of these:
   ```bash
   bash install.sh vim                 # same headless install + verification
   vim +'PlugInstall --sync' +qa       # or directly
   ```

To remove a plugin, delete its `Plug` line and run `vim +PlugClean! +qa`.

## Reinstalling and updating plugins

```bash
vim +'PlugInstall --sync' +qa   # install anything missing
vim +'PlugUpdate --sync' +qa    # update all plugins
vim +PlugUpgrade +qa            # update vim-plug itself
```

For a clean reinstall, move `~/.vim/plugged` aside and run `bash install.sh vim`.

## Clipboard integration

The vimrc picks the best option your Vim build supports:

| Vim build | Setting | Result |
|-----------|---------|--------|
| `+clipboard` with `unnamedplus` (typical Linux GUI-capable build) | `clipboard=unnamedplus` | Yanks go to the system CLIPBOARD |
| `+clipboard` without `unnamedplus` (macOS) | `clipboard=unnamed` | On macOS the `*` register *is* the system clipboard |
| `-clipboard` | `TextYankPost` hook | Yanks are piped to `pbcopy`, `wl-copy`, `xclip` or `xsel` (first one found) |

`set clipboard=unnamedplus` alone does nothing on macOS, because Vim there has no `unnamedplus`. That's why the vimrc falls back to `unnamed`.

The installer tells you which case applies. With the `-clipboard` fallback, only copying works. Pasting OS content inside Vim with `"+p` doesn't, so use your terminal's paste (Cmd‑V or Ctrl‑Shift‑V).

Check your build with `vim --version | grep clipboard`. Over SSH there is no local display, so the remote Vim can't reach your desktop clipboard.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `E117: Unknown function: plug#begin` | vim-plug is missing. Run `bash install.sh vim`. |
| Plugins missing, or syntax not highlighted | `vim +'PlugInstall --sync' +qa`. Check that `git` works and can reach github.com. |
| Installer says "lacks +eval" | You have `vim-tiny`. Install a full Vim (the installer prints the command). |
| Yanks don't reach the system clipboard | See the clipboard section above. On Debian/Ubuntu run `sudo apt install vim-gtk3`. On Fedora use `vimx` from `vim-X11`. |
| `~/.vim/vimrc` or `~/.config/vim/vimrc` ignored | `~/.vimrc` takes precedence. The installer warns about this. Merge what you need into `vim/vimrc`. |
| Want the old config back | `bash scripts/restore.sh` |
| Undo history not persisting | Make sure `~/.vim/undo/` exists (the installer creates it). |
