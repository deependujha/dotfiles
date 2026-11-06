#!/usr/bin/env bash
# Neovim (AstroNvim) component: symlink ~/.config/nvim to nvim/config and
# install plugins, language servers and treesitter parsers headlessly.
#
# Normally run by install.sh, but safe to run directly:  bash nvim/setup.sh
#
# Order matters: prerequisite checks happen before anything in $HOME changes,
# so a missing tool leaves the existing configuration untouched.
#
# Environment overrides:
#   DOTFILES_NVIM_SKIP_TOOLS=1   link the config and install plugins, but skip
#                                Mason tools and treesitter parsers (fast, offline-ish)

set -euo pipefail

SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -P "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=../common/utils.sh
. "$REPO_DIR/common/utils.sh"
# shellcheck source=../common/detect_os.sh
. "$REPO_DIR/common/detect_os.sh"
# shellcheck source=../common/backup.sh
. "$REPO_DIR/common/backup.sh"

COMPONENT="nvim"
CONFIG_SOURCE="$SCRIPT_DIR/config"
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
MIN_NVIM="0.11.0"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-nvim.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# ---------------------------------------------------------------------------

# version_ge A B: true if dotted version A >= B (numeric, up to 3 parts).
version_ge() {
    local a1 a2 a3 b1 b2 b3
    IFS=. read -r a1 a2 a3 <<EOF
$1
EOF
    IFS=. read -r b1 b2 b3 <<EOF
$2
EOF
    a1=${a1:-0} a2=${a2:-0} a3=${a3:-0} b1=${b1:-0} b2=${b2:-0} b3=${b3:-0}
    [ "$a1" -gt "$b1" ] && return 0; [ "$a1" -lt "$b1" ] && return 1
    [ "$a2" -gt "$b2" ] && return 0; [ "$a2" -lt "$b2" ] && return 1
    [ "$a3" -ge "$b3" ]
}

check_prerequisites() {
    local os missing=0 tool version
    os="$(detect_os)"
    [ "$os" != unsupported ] || die "Unsupported OS: $(uname -s). Only macOS and Linux are supported."
    log_info "Detected OS: $os"

    # Hard requirements: without these AstroNvim can't install itself.
    for tool in nvim git curl tar; do
        if ! command_exists "$tool"; then
            log_error "'$tool' is not installed. Install it with:  $(install_hint "$tool")"
            missing=1
        fi
    done
    if ! command_exists cc && ! command_exists gcc && ! command_exists clang; then
        log_error "No C compiler found (needed to build treesitter parsers). Install it with:  $(install_hint c-compiler)"
        missing=1
    fi
    [ "$missing" -eq 0 ] || die "Missing prerequisites (see above). Nothing was changed."

    version="$(nvim --version 2>/dev/null | sed -n '1s/^NVIM v\([0-9][0-9.]*\).*/\1/p')"
    [ -n "$version" ] || die "Could not determine the Neovim version from 'nvim --version'. Nothing was changed."
    version_ge "$version" "$MIN_NVIM" \
        || die "Neovim $version is too old; AstroNvim v6 needs >= $MIN_NVIM. Upgrade with:  $(install_hint neovim). Nothing was changed."
    log_info "Using $(command -v nvim) (v$version)"

    # Soft requirements: things work without them, but some features don't.
    local warned=0
    warn_missing() { # <command> <hint-key> <what breaks>
        if ! command_exists "$1"; then
            log_warn "'$1' not found: $3. Install with:  $(install_hint "$2")"
            warned=1
        fi
    }
    warn_missing rg ripgrep "live grep (<Leader>fw) won't work"
    warn_missing node node "the HTML/CSS/JS/TS/JSON/YAML/Bash language servers and prettier can't be installed"
    warn_missing npm node "the HTML/CSS/JS/TS/JSON/YAML/Bash language servers and prettier can't be installed"
    warn_missing go go "gopls and the other Go tools can't be installed"
    warn_missing unzip unzip "some Mason packages (e.g. clangd, lua-language-server) can't be unpacked"
    if ! command_exists fd && ! command_exists fdfind; then
        log_warn "'fd' not found: the Python venv selector (<Leader>lv) is disabled and file search is slower. Install with:  $(install_hint fd)"
        warned=1
    fi
    warn_missing lazygit lazygit "the git UI (<Leader>gg) won't open"
    warn_missing deno deno "markdown live preview (:PeekOpen) is disabled"
    [ "$warned" -eq 0 ] || log_warn "Continuing; install the tools above later and run 'bash install.sh nvim' again."
}

config_is_managed() {
    is_link_to "$CONFIG_TARGET" "$CONFIG_SOURCE"
}

backup_existing() {
    if config_is_managed; then
        log_info "$CONFIG_TARGET already links to this repository; no backup needed."
        return 0
    fi
    # The whole directory is replaced by a symlink, so it is moved, not copied.
    # Plugins and Mason tools in ~/.local/share/nvim are left alone and reused.
    if path_exists "$CONFIG_TARGET"; then
        backup_item "$COMPONENT" nvim-config "$CONFIG_TARGET" move
    fi
}

link_config() {
    if config_is_managed; then
        log_info "Symlink already correct: $CONFIG_TARGET -> $CONFIG_SOURCE"
        return 0
    fi
    mkdir -p "$(dirname "$CONFIG_TARGET")"
    path_exists "$CONFIG_TARGET" && die "$CONFIG_TARGET still exists; refusing to overwrite it."
    ln -s "$CONFIG_SOURCE" "$CONFIG_TARGET"
    log_success "Linked $CONFIG_TARGET -> $CONFIG_SOURCE"
}

# run_nvim <log> <lua file>: run a Lua script in headless nvim with the real
# config loaded. stdin from /dev/null so nvim can't read the installer itself.
run_nvim() {
    local log="$1" script="$2" rc=0
    nvim --headless -c "luafile $script" </dev/null >"$log" 2>&1 || rc=$?
    return "$rc"
}

# 1. lazy.nvim installs every plugin (at the versions in lazy-lock.json).
install_plugins() {
    local log="$WORK_DIR/lazy.log" script="$WORK_DIR/lazy.lua"
    cat >"$script" <<'LUA'
local ok, lazy = pcall(require, "lazy")
if not ok then io.stderr:write("lazy.nvim did not load\n") vim.cmd "cquit 1" end
lazy.install { wait = true, show = false }
local missing = {}
for _, p in ipairs(lazy.plugins()) do
  if not p._.installed and p.enabled ~= false and p._.cond ~= false then table.insert(missing, p.name) end
end
if #missing > 0 then
  io.stderr:write("missing plugins: " .. table.concat(missing, " ") .. "\n")
  vim.cmd "cquit 1"
end
vim.cmd "qall!"
LUA
    log_info "Installing plugins with lazy.nvim (first run can take a minute)..."
    if run_nvim "$log" "$script"; then
        log_success "Plugins installed."
        return 0
    fi
    log_error "Plugin installation failed:"
    sed 's/^/    /' "$log" >&2
    return 1
}

# 2. Mason installs LSP servers/formatters/debuggers; 3. treesitter parsers.
# Both are asynchronous inside nvim, so this script waits for them and then
# reports anything that is still missing.
install_tools() {
    local log="$WORK_DIR/tools.log" script="$WORK_DIR/tools.lua" out="$WORK_DIR/tools.out"
    cat >"$script" <<'LUA'
local out = assert(os.getenv "DOTFILES_NVIM_OUT")
local report = {}
local function finish(code)
  vim.fn.writefile(report, out)
  vim.cmd(code == 0 and "qall!" or "cquit 1")
end

-- Mason: mason-tool-installer holds the merged ensure_installed list from
-- every language pack plus lua/plugins/mason.lua.
require("lazy").load { plugins = { "mason.nvim", "mason-tool-installer.nvim" } }
local mti = require("lazy.core.config").spec.plugins["mason-tool-installer.nvim"]
local wanted = require("lazy.core.plugin").values(mti, "opts", false).ensure_installed or {}
local registry = require "mason-registry"
local refreshed = false
registry.refresh(function() refreshed = true end)
vim.wait(120000, function() return refreshed end, 200)

local pending = {}
for _, name in ipairs(wanted) do
  local ok, pkg = pcall(registry.get_package, name)
  if not ok then
    table.insert(report, "mason-unknown " .. name)
  elseif not pkg:is_installed() then
    pending[name] = pkg
    -- mason-tool-installer may already have started it on launch
    if not pkg:is_installing() then pcall(pkg.install, pkg) end
  end
end
-- Done only when nothing is installing any more. Mason creates the package
-- directory before an install is finalized, so `is_installed()` alone can be
-- true for an install that quitting nvim would still abort. A package that
-- ended up not installed (failed, or aborted by mason-tool-installer racing us)
-- gets one retry.
local retried = {}
vim.wait(900000, function()
  for name, pkg in pairs(pending) do
    if pkg:is_installing() then return false end
    if not pkg:is_installed() and not retried[name] then
      retried[name] = true
      pcall(pkg.install, pkg)
      return false
    end
  end
  return true
end, 1000)
for _, name in ipairs(wanted) do
  local ok, pkg = pcall(registry.get_package, name)
  if ok and not pkg:is_installed() then table.insert(report, "mason-missing " .. name) end
end

-- Treesitter: install every parser in astrocore's merged ensure_installed list
-- and wait for the compile to finish. Mason's bin dir (with tree-sitter-cli)
-- is on PATH inside nvim.
local langs = require("astrocore").config.treesitter.ensure_installed or {}
if type(langs) == "table" and #langs > 0 then
  require("lazy").load { plugins = { "nvim-treesitter" } }
  local ok, err = pcall(function() require("nvim-treesitter").install(langs, { summary = false }):wait(900000) end)
  if not ok then table.insert(report, "ts-error " .. tostring(err)) end
  local have = {}
  for _, l in ipairs(require("nvim-treesitter").get_installed "parsers") do have[l] = true end
  for _, l in ipairs(langs) do
    if not have[l] then table.insert(report, "ts-missing " .. l) end
  end
end

finish(0)
LUA
    log_info "Installing language servers, formatters and treesitter parsers (several minutes on a fresh machine)..."
    local rc=0
    DOTFILES_NVIM_OUT="$out" run_nvim "$log" "$script" || rc=$?

    if [ "$rc" -ne 0 ] || [ ! -f "$out" ]; then
        log_error "Tool installation did not finish (exit $rc):"
        sed 's/^/    /' "$log" >&2
        return 1
    fi
    if [ -s "$out" ]; then
        log_warn "Some tools are not installed:"
        sed -e 's/^mason-missing /    Mason package: /' \
            -e 's/^mason-unknown /    Unknown Mason package name: /' \
            -e 's/^ts-missing /    Treesitter parser: /' \
            -e 's/^ts-error /    Treesitter error: /' "$out" >&2
        log_warn "Usually a missing toolchain (see warnings above) or a network problem."
        log_warn "Fix it, then re-run 'bash install.sh nvim' or use :Mason / :TSInstall inside nvim."
        return 1
    fi
    log_success "Language servers, formatters and treesitter parsers installed."
}

report_clipboard() {
    if [ "$(detect_os)" = macos ]; then
        log_success "Clipboard: yanks go to the macOS clipboard (pbcopy/pbpaste)."
        return 0
    fi
    if [ -n "${SSH_TTY:-}${SSH_CONNECTION:-}" ]; then
        log_info "Clipboard: SSH session; yanks are sent to your local terminal via OSC 52."
    elif command_exists wl-copy || command_exists xclip || command_exists xsel; then
        log_success "Clipboard: system clipboard tool found; yanks go to the system clipboard."
    else
        log_warn "Clipboard: no wl-copy/xclip/xsel found, so yanks stay inside Neovim. Install with:  $(install_hint clipboard-tool)"
    fi
}

main() {
    check_prerequisites
    backup_existing
    link_config

    local failed=0
    install_plugins || failed=1
    if [ "$failed" -eq 0 ] && [ -z "${DOTFILES_NVIM_SKIP_TOOLS:-}" ]; then
        install_tools || failed=1
    fi
    report_clipboard

    local session
    session="$(backup_session_if_used)"
    [ -z "$session" ] || log_info "Backup of previous Neovim config: $session/$COMPONENT"

    if [ "$failed" -ne 0 ]; then
        log_error "Neovim setup finished with errors (config is linked; see above)."
        return 1
    fi
    log_success "Neovim is ready. Notes: $SCRIPT_DIR/notes/README.md"
}

main "$@"
