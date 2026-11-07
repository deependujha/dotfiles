# Neovim cheatsheet

`<Space>` is the leader key. **Press `<Space>` and wait** to get a menu of everything (which-key). That's the easiest way to find a key you've forgotten.

These are AstroNvim v6 defaults plus this config's additions. Run `:map` for the full list, or `<Space>fk` to search keymaps.

## Files and search

| Key | Action |
|---|---|
| `<Space>ff` | Find files |
| `<Space>fw` | Grep for words in the project (needs `rg`) |
| `<Space>fb` | Open buffers |
| `<Space>fo` | Recently opened files |
| `<Space>fh` | Search help |
| `<Space>fk` | Search keymaps |
| `<Space>e` | Toggle the file explorer |
| `<Space>o` | Focus the file explorer |
| `<Space>w` | Save |
| `<Space>q` | Close window |
| `<Space>c` | Close buffer |
| `]b` / `[b` | Next / previous buffer |

In the explorer: `a` adds a file (end the name with `/` for a folder), `d` deletes, `r` renames, `H` toggles hidden files, and `?` shows help.

## Code (LSP)

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `grr` | References |
| `gri` | Implementation |
| `K` | Hover docs (press again to enter the window) |
| `<Space>la` | Code action (quick fixes, imports) |
| `<Space>lr` | Rename symbol |
| `<Space>lf` | Format buffer |
| `<Space>ls` | Search symbols in the file |
| `<Space>lS` | Symbols outline |
| `<Space>ld` | Show the diagnostic under the cursor |
| `<Space>lD` | Search all diagnostics |
| `]d` / `[d` | Next / previous diagnostic |
| `<Space>li` | Which language servers are attached |
| `<Space>lv` | Pick a Python virtualenv |
| `gcc` / `gc` (visual) | Toggle comment |

Completion: `<C-n>`/`<C-p>` or `<Tab>`/`<S-Tab>` move through the list, `<CR>` accepts, and `<C-e>` closes it. `<C-Space>` opens it manually.

## Toggles (`<Space>u`)

| Key | Action |
|---|---|
| `<Space>ub` | Light / dark background (the theme follows) |
| `<Space>uf` | Format on save, this buffer |
| `<Space>uF` | Format on save, everywhere |
| `<Space>uH` | Inlay hints (types inline) |
| `<Space>un` | Line numbers: relative / absolute / off |
| `<Space>uw` | Line wrap |
| `<Space>us` | Spell check |
| `<Space>ud` | Diagnostics on / off |

## Git

| Key | Action |
|---|---|
| `<Space>gg` | lazygit |
| `<Space>gb` | Branches |
| `<Space>gc` | Commits |
| `<Space>gl` | Blame for the current line |
| `<Space>gp` | Preview the hunk |
| `<Space>gr` / `<Space>gs` | Reset / stage hunk |
| `]g` / `[g` | Next / previous change |
| `:Git …` | Any git command (fugitive), e.g. `:Git blame` |
| `:TracePR` | Open the PR that introduced this line |

## Terminal

| Key | Action |
|---|---|
| `<Space>tf` | Floating terminal |
| `<Space>th` / `<Space>tv` | Horizontal / vertical split terminal |
| `<F7>` | Toggle the terminal |
| `<C-\><C-n>` | Leave terminal insert mode (to scroll/copy) |
| `<C-h/j/k/l>` | Jump from the terminal to another split |

## Windows

| Key | Action |
|---|---|
| `<C-h/j/k/l>` | Move between splits |
| `<C-Up/Down/Left/Right>` | Resize a split |
| `\` / `\|` | Horizontal / vertical split |

## Debugging (`<Space>d`)

| Key | Action |
|---|---|
| `<Space>db` or `<F9>` | Toggle breakpoint |
| `<Space>dc` or `<F5>` | Start / continue |
| `<Space>di` / `<Space>do` / `<Space>dO` | Step into / over / out (`<F11>` / `<F10>` / `<S-F11>`) |
| `<Space>du` | Debugger UI |
| `<Space>dq` | Stop |

## Plugins and tools (`<Space>p`)

| Key / command | Action |
|---|---|
| `<Space>pa` | Update everything (plugins + Mason tools) |
| `<Space>pS` / `:Lazy sync` | Install, update and clean plugins |
| `<Space>pu` | Check for plugin updates |
| `<Space>pm` / `:Mason` | Mason: installed servers and tools |
| `:Lazy` | Plugin manager UI (`?` for help) |
| `:Lazy clean` | Remove plugins you deleted from the config |
| `:Lazy restore` | Go back to the versions in `lazy-lock.json` |
| `:TSUpdate` / `:TSInstall <lang>` | Treesitter parsers |
| `:checkhealth` | Diagnose problems |

## Markdown and CSV

| Command | Action |
|---|---|
| `:RenderMarkdown toggle` | In-buffer rendering on / off |
| `:PeekOpen` / `:PeekClose` | Live preview window |
| `:CsvViewToggle` | Show a CSV/TSV as aligned columns |

## Clipboard

`y` copies to the system clipboard and `p` pastes from it. No `"+` needed. Over SSH, yanks still reach your local clipboard (OSC 52). To paste text copied on your Mac into nvim over SSH, use Cmd+V.

## Other handy keys

| Key / command | Action |
|---|---|
| `<Space>nh` / `:Notifications` | Notification history |
| `<Space>ft` | Pick a theme with live preview (lasts for this session; edit `theme.lua` to keep it) |
| `<Space>S…` | Sessions: `<Space>Sl` loads the last session, `<Space>S.` the session for this folder |
| `:InspectTree` | Show the treesitter syntax tree |
| `:Inspect` | Show which highlight group is under the cursor |
