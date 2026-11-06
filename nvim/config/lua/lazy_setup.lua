-- Plugin manager setup. Load order matters:
--   1. AstroNvim core (sensible defaults for everything)
--   2. lua/community.lua (language packs + themes from AstroCommunity)
--   3. lua/plugins/*.lua (your own plugins and overrides; these win)
require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    version = "^6", -- stay on AstroNvim v6; `:Lazy update` moves within v6 only
    import = "astronvim.plugins",
    opts = { -- AstroNvim options must be set here with the `import` key
      mapleader = " ", -- <Leader> is Space
      maplocalleader = ",",
      icons_enabled = true, -- needs a Nerd Font in the terminal; set false if icons look broken
      pin_plugins = nil, -- pin plugins to versions tested with this AstroNvim release
      update_notifications = true,
    },
  },
  { import = "community" },
  { import = "plugins" },
} --[[@as LazySpec]], {
  install = { colorscheme = { "catppuccin", "astrotheme", "habamax" } },
  ui = { backdrop = 100 },
  -- don't pop up a notification every time a config file is saved
  change_detection = { notify = false },
  -- no plugin here needs luarocks; turning it off avoids a checkhealth error
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "netrwPlugin", "tarPlugin", "tohtml", "zipPlugin" },
    },
  },
} --[[@as LazyConfig]])
