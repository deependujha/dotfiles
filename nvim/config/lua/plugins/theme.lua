-- Theme: one colorscheme for dark mode and one for light mode.
--
-- Neovim follows the macOS appearance (or the GNOME/KDE colour scheme on Linux)
-- live, so `toggle_dark_mode` flips the editor along with the terminal.
-- <Leader>ub flips just this Neovim by hand.
--
-- To change theme: edit the two names below. `:colorscheme <Tab>` lists every
-- installed scheme, and <Leader>ft gives a live-preview picker.
-- To use a theme that isn't installed yet, add its plugin to the `return` table
-- at the bottom (there's an example there).

local themes = {
  dark = "catppuccin-mocha", -- matches Ghostty's "Catppuccin Mocha"
  light = "catppuccin-latte", -- matches Ghostty's "Catppuccin Latte"
}

-- Apply the scheme that belongs to the current 'background'.
local function apply_theme()
  local want = themes[vim.o.background] or themes.dark
  if vim.g.colors_name ~= want then pcall(vim.cmd.colorscheme, want) end
end

-- Pick the right background before the UI draws, so starting in light mode
-- doesn't flash dark first. On macOS, `defaults` prints "Dark" in dark mode and
-- fails in light mode. Elsewhere, Neovim's own terminal background detection
-- and auto-dark-mode below take care of it.
if vim.fn.has "mac" == 1 and vim.fn.executable "defaults" == 1 then
  local out = vim.fn.system { "defaults", "read", "-g", "AppleInterfaceStyle" }
  vim.o.background = out:match "Dark" and "dark" or "light"
end

-- Whatever changes 'background' (auto-dark-mode, <Leader>ub, `:set bg=light`,
-- the terminal reporting its colours), the matching scheme follows.
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  group = vim.api.nvim_create_augroup("dotfiles_theme_follow_background", { clear = true }),
  callback = function() vim.schedule(apply_theme) end,
})

---@type LazySpec
return {
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      colorscheme = themes[vim.o.background] or themes.dark,
      highlights = {
        init = { -- overrides applied on top of every theme, e.g. Normal = { bg = "#000000" }
        },
      },
    },
  },

  -- Polls the OS appearance and sets 'background'; the autocmd above does the rest.
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    opts = {
      update_interval = 1000, -- ms between checks
      set_dark_mode = function()
        if vim.o.background ~= "dark" then vim.o.background = "dark" end
      end,
      set_light_mode = function()
        if vim.o.background ~= "light" then vim.o.background = "light" end
      end,
      fallback = "dark",
    },
  },

  -- Example: install another theme, then put its names in `themes` above.
  -- { "folke/tokyonight.nvim", lazy = true }, -- "tokyonight-night" / "tokyonight-day"
}
