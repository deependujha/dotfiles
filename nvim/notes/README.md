# Neovim (AstroNvim) configuration

Neovim runs [AstroNvim v6](https://docs.astronvim.com), with LSP, treesitter, formatting and debugging set up for C/C++, Python, Rust, Go, Markdown, HTML, CSS, JavaScript and TypeScript, plus Lua, JSON, YAML, TOML and Bash.

Keys are in [cheatsheet.md](cheatsheet.md). This file explains how the setup works and how to change it.

- [Quick answers](#quick-answers)
- [What you get](#what-you-get)
- [Where things live](#where-things-live)
- [Adding, configuring and removing plugins](#adding-configuring-and-removing-plugins)
- [Themes and light/dark mode](#themes-and-lightdark-mode)
- [Languages: LSP, formatters, treesitter](#languages-lsp-formatters-treesitter)
- [Clipboard](#clipboard)
- [Updating](#updating)
- [How installation works](#how-installation-works)
- [Troubleshooting](#troubleshooting)

## Quick answers

| I want to… | Do this |
|---|---|
| Add a plugin | Add `"owner/repo",` to `config/lua/plugins/user.lua` and restart nvim |
| Change the theme | Edit the two names at the top of `config/lua/plugins/theme.lua` |
| Flip light/dark in nvim only | `<Space>ub` |
| Add a language | Add an `astrocommunity.pack.<lang>` line to `config/lua/community.lua` |
| Change an option (tabs, wrap, …) | `options.opt` in `config/lua/plugins/astrocore.lua` |
| Add a key mapping | `mappings` in `config/lua/plugins/astrocore.lua` |
| Format on save for more languages | `allow_filetypes` in `config/lua/plugins/astrolsp.lua` |
| See why something is broken | `:checkhealth`, `:LspInfo`, `:Lazy`, `:Mason` |
| Find a key | Press `<Space>` and wait: which-key lists everything |

Paths in this file are relative to `nvim/` in the dotfiles repo. `~/.config/nvim` is a symlink to `nvim/config`, so editing either one changes the same files.

## What you get

- **LSP** for every language above: completion, go-to-definition, hover docs, rename, code actions and diagnostics.
- **Treesitter** syntax highlighting and indentation. A missing parser is installed the first time you open a file that needs it.
- **Formatting**: on save for Go, Python and Rust; by hand with `<Space>lf` for everything else (prettier for web files, clang-format via clangd for C/C++).
- **System clipboard**: `y` copies to the macOS clipboard and `p` pastes from it. This also works over SSH.
- **A theme that follows macOS dark mode**: Catppuccin Mocha in dark mode and Catppuccin Latte in light mode, matching Ghostty. `toggle_dark_mode` switches nvim too, within about a second.
- **Debugging** (nvim-dap) for C/C++/Rust (codelldb), Python (debugpy), Go (delve) and JS/TS: `<Space>d…`.
- **Markdown**: rendered in the buffer (headings, tables, checkboxes) and live preview with `:PeekOpen`.
- **Git**: signs in the gutter, inline blame on the current line, lazygit on `<Space>gg`, fugitive's `:Git`, and `:TracePR` to open the PR behind the current line.
- Plus AstroNvim's defaults: file explorer, fuzzy finder, terminal, sessions, a status line and more.

## Where things live

```text
nvim/
├── setup.sh                   installer (run by install.sh)
├── notes/                     these notes
└── config/                    ← ~/.config/nvim points here
    ├── init.lua               bootstraps lazy.nvim; leave it alone
    ├── lazy-lock.json         exact plugin versions; commit it after updating
    └── lua/
        ├── lazy_setup.lua     loads AstroNvim, then community.lua, then plugins/
        ├── community.lua      language packs and themes from AstroCommunity
        ├── polish.lua         plain Lua that runs last (clipboard over SSH)
        └── plugins/
            ├── user.lua       ← YOUR PLUGINS GO HERE
            ├── theme.lua      light/dark theme names + OS dark mode sync
            ├── astrocore.lua  vim options, key mappings, autocommands
            ├── astrolsp.lua   LSP: format on save, per-server settings
            ├── mason.lua      extra tools Mason should install
            ├── treesitter.lua extra parsers
            ├── git.lua        gitsigns blame, fugitive, trace-pr
            ├── ui.lua         dashboard, neo-tree, rainbow brackets, scrollbar
            └── markdown.lua   peek.nvim live preview
```

Every file in `lua/plugins/` is loaded automatically, whatever its name. Each one returns a list of plugin specs.

Things that are **not** in the repo, because nvim manages them:

| Path | Contains | Safe to delete? |
|---|---|---|
| `~/.local/share/nvim/lazy/` | plugin source code | Yes, it reinstalls on next start |
| `~/.local/share/nvim/mason/` | LSP servers, formatters, debuggers | Yes, then run `bash install.sh nvim` |
| `~/.local/share/nvim/site/parser/` | compiled treesitter parsers | Yes, they reinstall |
| `~/.local/state/nvim/` | logs, undo history, shada | Yes, but you lose undo history |

## Adding, configuring and removing plugins

Plugins are managed by [lazy.nvim](https://lazy.folke.io). A plugin is a GitHub `owner/repo` string, optionally wrapped in a table with settings.

### Add one

Open `config/lua/plugins/user.lua` and add a line to the returned table:

```lua
return {
  "tpope/vim-surround",                         -- simplest form

  { "folke/zen-mode.nvim", opts = {} },         -- opts = {} also runs require("zen-mode").setup({})

  {
    "folke/trouble.nvim",
    cmd = "Trouble",                            -- don't load until :Trouble is used
    keys = {
      { "<Leader>xx", "<Cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics list" },
    },
    opts = {},
  },
}
```

Save and restart nvim. lazy.nvim notices the new plugin and installs it. You can also run `:Lazy sync` without restarting.

The fields you'll use most:

| Field | Meaning |
|---|---|
| `opts = { … }` | Settings passed to the plugin's `setup()` |
| `config = function(_, opts) … end` | Custom setup code, when `opts` isn't enough |
| `event = "User AstroFile"` | Load once a real file is opened (AstroNvim's event) |
| `event = "VeryLazy"` | Load just after startup |
| `cmd = "Name"` | Load the first time `:Name` runs |
| `keys = { … }` | Load the first time one of these keys is pressed (and define them) |
| `ft = "python"` | Load for a filetype |
| `dependencies = { "owner/repo" }` | Other plugins this one needs |
| `enabled = false` | Turn it off |
| `build = "make"` | Command to run after install/update |

A plugin's README usually has a "lazy.nvim" install snippet. Paste it into `user.lua` as-is.

### Check AstroCommunity first

[AstroCommunity](https://github.com/AstroNvim/astrocommunity) has hundreds of plugins already configured to work with AstroNvim. If what you want is there, one line in `config/lua/community.lua` is enough:

```lua
{ import = "astrocommunity.motion.flash-nvim" },
```

### Change a plugin AstroNvim already ships

List it again with just the settings you want to change. Your `opts` are merged into AstroNvim's:

```lua
{ "nvim-neo-tree/neo-tree.nvim", opts = { window = { width = 40 } } },
```

`config/lua/plugins/ui.lua` and `git.lua` have real examples of this.

### Disable or remove one

- One of AstroNvim's plugins: `{ "max397574/better-escape.nvim", enabled = false }` (`ui.lua` already does this).
- One you added: delete its line, then run `:Lazy clean`.

### Bigger plugins

Give a plugin its own file, for example `config/lua/plugins/copilot.lua`, which returns `{ "owner/repo", … }`. Every file in that folder is loaded.

### After adding or updating plugins

`lazy-lock.json` records the exact commit of every plugin. Commit it with your config change so other machines install the same versions.

## Themes and light/dark mode

All of it is in `config/lua/plugins/theme.lua`.

```lua
local themes = {
  dark = "catppuccin-mocha",
  light = "catppuccin-latte",
}
```

**How the sync works:** auto-dark-mode.nvim asks macOS once a second whether dark mode is on (`defaults read -g AppleInterfaceStyle`) and sets nvim's `background` to `dark` or `light`. Whenever `background` changes, an autocommand applies `themes.dark` or `themes.light`. So `toggle_dark_mode`, `<Space>ub` and `:set background=light` all end up in the same place. On startup the OS is checked before anything is drawn, so a light-mode start doesn't flash dark first. On Linux the plugin reads the GNOME/KDE colour scheme over D-Bus instead.

**Try themes live:** `<Space>ft` opens a picker with preview. `:colorscheme <Tab>` lists every installed scheme. Catppuccin also has `catppuccin-frappe` and `catppuccin-macchiato`, and AstroNvim ships `astrodark` and `astrolight`.

**Switch to another theme family**, for example Tokyo Night:

1. Add the plugin at the bottom of `theme.lua` (or `user.lua`):
   ```lua
   { "folke/tokyonight.nvim", lazy = true },
   ```
   Or import it from AstroCommunity in `community.lua`: `{ import = "astrocommunity.colorscheme.tokyonight-nvim" }`.
2. Change the names:
   ```lua
   local themes = { dark = "tokyonight-night", light = "tokyonight-day" }
   ```
3. Restart nvim.

You'll probably want Ghostty's theme to match: `theme = light:…,dark:…` in `~/.config/ghostty/config`.

**Tweak colours** for every theme with `highlights.init` in `theme.lua`, for example `Normal = { bg = "#000000" }`.

**Stop following the OS:** remove the `f-person/auto-dark-mode.nvim` block. `<Space>ub` still works.

## Languages: LSP, formatters, treesitter

Each language comes from an AstroCommunity *pack* in `config/lua/community.lua`. A pack bundles the treesitter parser, the language server, formatters/linters and a debugger, and adds them to Mason's install list.

| Language | LSP | Format | Debug |
|---|---|---|---|
| C / C++ | clangd (+ clangd_extensions, cmake-tools) | clangd (clang-format; reads `.clang-format`) | codelldb |
| Python | basedpyright (types) + ruff (lint) | ruff | debugpy |
| Rust | rust-analyzer via rustaceanvim, crates.nvim for `Cargo.toml` | rustfmt (via rust-analyzer) | codelldb |
| Go | gopls | goimports / gopls | delve |
| Markdown | marksman | prettierd | — |
| HTML / CSS | html, cssls, emmet_ls | prettierd | — |
| JS / TS / JSX / TSX | vtsls | prettierd | js-debug-adapter |
| Lua, JSON, YAML, TOML, Bash | lua_ls, jsonls, yamlls, taplo, bashls | stylua, prettierd, taplo, shfmt | bash-debug-adapter |

**Python virtualenvs:** start nvim from a shell with the venv active and basedpyright uses it. Or pick one inside nvim with `<Space>lv`.

**Rust** needs a Cargo project (a `Cargo.toml`). **Go** works best inside a module (`go.mod`). **C/C++** need a `compile_commands.json` for anything beyond single files (CMake: `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`), or a `.clangd`/`compile_flags.txt`.

**Add a language:** browse the [pack list](https://github.com/AstroNvim/astrocommunity/tree/main/lua/astrocommunity/pack), add `{ import = "astrocommunity.pack.<name>" },` to `community.lua`, and restart. Mason installs the tools in the background (watch `:Mason`).

**Add a single tool** (formatter, linter, server) without a pack: add its `:Mason` name to `config/lua/plugins/mason.lua`.

**Format on save** is limited to Go, Python and Rust by `allow_filetypes` in `config/lua/plugins/astrolsp.lua`. Add filetypes there, or delete the `allow_filetypes` line to format everything on save. `<Space>uf` toggles it for the current buffer and `<Space>uF` toggles it everywhere.

**Per-server settings** go in `config = { <server> = { settings = { … } } }` in `astrolsp.lua`. The `basedpyright` entry there is an example.

**Treesitter:** extra parsers are listed in `config/lua/plugins/treesitter.lua`, and anything else installs on demand. To install by hand, run `:TSInstall <lang>`. To update all parsers, run `:TSUpdate`.

## Clipboard

`clipboard=unnamedplus` is set in `config/lua/plugins/astrocore.lua`, so:

- `y`, `yy`, `yiw`, visual-mode `y`, and also `d`/`x`, put text on the system clipboard.
- `p` pastes whatever you last copied anywhere.

On macOS this goes through `pbcopy`/`pbpaste`. On Linux it needs `wl-copy` (Wayland) or `xclip`/`xsel` (X11).

**Over SSH** (`config/lua/polish.lua`), yanks are sent to the terminal you're sitting at with the OSC 52 escape code, so they land on your *local* clipboard. Ghostty, iTerm2, kitty, WezTerm, tmux and zellij support it. Inside nvim over SSH, `p` pastes nvim's own last yank. To paste something copied on your Mac, use Cmd+V.

If you'd rather deletes didn't overwrite the clipboard, change `x` to `"_x` in a mapping, or remove `clipboard` from the options and use `"+y` / `"+p` explicitly.

## Updating

```text
<Space>pa     update plugins (Lazy) and tools (Mason) in one go
:Lazy update  plugins only, then commit config/lazy-lock.json
:MasonToolsUpdate
:TSUpdate
```

AstroNvim itself is pinned to v6 in `config/lua/lazy_setup.lua` (`version = "^6"`). `:Lazy update` moves within v6. A future v7 means reading AstroNvim's migration notes and changing that line on purpose.

On another machine: `git pull` in the dotfiles repo, then `:Lazy restore` installs exactly the versions in `lazy-lock.json`.

## How installation works

`nvim/setup.sh` (run by `install.sh`, or directly with `bash nvim/setup.sh`):

1. Checks the OS, `nvim` ≥ 0.11, `git`, `curl`, `tar` and a C compiler, and stops before changing anything if one is missing. It then warns about optional tools: `rg` (grep), `node`/`npm` (most web language servers), `go` (gopls), `unzip`, `fd` (venv picker), `lazygit`, `deno` (markdown preview).
2. Moves an existing `~/.config/nvim` into `~/dotfiles_backup/<timestamp>/nvim/`, unless it is already the symlink. Plugins and tools in `~/.local/share/nvim` are kept and reused.
3. Symlinks `~/.config/nvim` → `nvim/config`.
4. Starts nvim headlessly to install all plugins at the versions in `lazy-lock.json`, and fails if any are missing.
5. Starts nvim headlessly again to install every Mason tool and treesitter parser. It waits until they finish and then lists anything that didn't install. `DOTFILES_NVIM_SKIP_TOOLS=1` skips this step.
6. Reports the clipboard setup.

Re-running it is safe and quick. Already-installed things are skipped, and a re-run picks up anything that failed before. `bash scripts/restore.sh` puts the previous config back.

## Troubleshooting

| Symptom | Try |
|---|---|
| No completion / no diagnostics | `:LspInfo` (is a server attached?), `:Mason` (is it installed?), `:checkhealth vim.lsp` |
| A server is installed but not attached | Rust needs `Cargo.toml`, Go needs `go.mod`, C++ needs `compile_commands.json`; also try `:LspRestart` |
| No colours / flat highlighting | `:InspectTree`; `:TSInstall <lang>`; check `cc` works (parsers are compiled C) |
| Formatting does nothing | `:LspInfo` and `<Space>lI` (null-ls) show which formatters are attached; check `allow_filetypes` for on-save |
| Weird boxes instead of icons | Use a Nerd Font in Ghostty (`font-family = "JetBrainsMono Nerd Font"`), or set `icons_enabled = false` in `lazy_setup.lua` |
| Theme doesn't follow dark mode | `:checkhealth auto-dark-mode`; `:set background?` should change when you toggle |
| Clipboard doesn't work | `:checkhealth vim.provider` (Clipboard section) |
| Everything is broken after an update | `:Lazy restore` returns to the versions in `lazy-lock.json`; `git checkout config/lazy-lock.json` first if you hadn't committed |
| Start completely fresh | Move `~/.local/share/nvim`, `~/.local/state/nvim` and `~/.cache/nvim` aside, then `bash install.sh nvim` |
