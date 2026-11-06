-- Look and feel tweaks on top of AstroNvim's defaults.

---@type LazySpec
return {
  -- Dashboard header and notification popups.
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            " █████  ███████ ████████ ██████   ██████ ",
            "██   ██ ██         ██    ██   ██ ██    ██",
            "███████ ███████    ██    ██████  ██    ██",
            "██   ██      ██    ██    ██   ██ ██    ██",
            "██   ██ ███████    ██    ██   ██  ██████ ",
            "",
            "███    ██ ██    ██ ██ ███    ███",
            "████   ██ ██    ██ ██ ████  ████",
            "██ ██  ██ ██    ██ ██ ██ ████ ██",
            "██  ██ ██  ██  ██  ██ ██  ██  ██",
            "██   ████   ████   ██ ██      ██",
          }, "\n"),
        },
      },
      notifier = {
        timeout = 5000,
        width = { min = 40, max = 120 },
      },
    },
  },

  -- File tree (<Leader>e): show dotfiles and gitignored files, dimmed.
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },

  -- Colour matching brackets by depth.
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "User AstroFile",
    init = function()
      vim.g.rainbow_delimiters = {
        query = { [""] = "rainbow-delimiters", lua = "rainbow-blocks" },
      }
    end,
  },

  -- Scrollbar with diagnostic markers.
  {
    "petertriho/nvim-scrollbar",
    event = "User AstroFile",
    opts = {
      handlers = { diagnostic = true, search = false },
      marks = {
        Error = { text = { "─" } },
        Warn = { text = { "─" } },
        Info = { text = { "─" } },
        Hint = { text = { "─" } },
      },
    },
  },

  -- You turned this off previously: `jk`/`jj` no longer act as <Esc>.
  { "max397574/better-escape.nvim", enabled = false },
}
