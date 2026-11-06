-- YOUR PLUGINS GO HERE.
--
-- Add a plugin: put its GitHub "owner/repo" in the table below, save, and
-- restart nvim (or run `:Lazy sync`). lazy.nvim installs it automatically.
--
--   "owner/repo",                                -- simplest form
--   { "owner/repo", opts = {} },                 -- also calls require("repo").setup({})
--   { "owner/repo", event = "User AstroFile" },  -- load once a real file is opened
--   { "owner/repo", cmd = "SomeCommand" },       -- load the first time :SomeCommand runs
--   { "owner/repo", keys = { { "<Leader>x", "<Cmd>SomeCommand<CR>", desc = "Do X" } } },
--   { "owner/repo", enabled = false },           -- turn a plugin off (also works for AstroNvim's own)
--
-- Remove a plugin: delete its line, then `:Lazy clean`.
-- A plugin that needs more than a line or two can get its own file in this
-- folder (lua/plugins/<anything>.lua) that returns the same kind of table.
--
-- Before writing your own, check https://github.com/AstroNvim/astrocommunity:
-- many plugins are one `import` line in lua/community.lua with sensible settings.

---@type LazySpec
return {
  -- CSV/TSV as aligned columns: :CsvViewToggle
  {
    "hat0uma/csvview.nvim",
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    ---@module "csvview"
    ---@type CsvView.Options
    opts = {
      parser = { comments = { "#", "//" } },
      view = {
        header_lnum = true, -- detect the header line
        sticky_header = { enabled = true, separator = "─" },
      },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
  },
}
