-- Runs last, after every plugin is set up. Plain Lua for anything that doesn't
-- fit the plugin specs in lua/plugins/.

-- Clipboard over SSH. Locally, 'clipboard=unnamedplus' (lua/plugins/astrocore.lua)
-- uses pbcopy on macOS or wl-copy/xclip on Linux. In an SSH session there's no
-- local clipboard tool, so yanks are sent to *your* terminal with the OSC 52
-- escape sequence (Ghostty, iTerm2, WezTerm, kitty, tmux and zellij support it).
-- Pasting reads Neovim's own last yank: asking the terminal for its clipboard
-- usually blocks or pops up a permission prompt, so paste text copied elsewhere
-- with your terminal's paste shortcut (Cmd+V).
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local osc52 = require "vim.ui.clipboard.osc52"
  local function paste() return { vim.fn.split(vim.fn.getreg "", "\n"), vim.fn.getregtype "" } end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy "+", ["*"] = osc52.copy "*" },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
