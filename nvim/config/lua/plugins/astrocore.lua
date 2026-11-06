-- AstroCore: editor options, key mappings, autocommands and user commands.
-- Docs: `:h astrocore`. AstroNvim's own defaults are listed in
-- ~/.local/share/nvim/lazy/AstroNvim/lua/astronvim/plugins/_astrocore_options.lua
-- and _astrocore_mappings.lua; anything set here overrides them.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 }, -- above this, treesitter/LSP are disabled for the buffer
      autopairs = true,
      cmp = true,
      diagnostics = { virtual_text = true, virtual_lines = false },
      highlighturl = true,
      notifications = true,
    },
    diagnostics = {
      virtual_text = true,
      underline = true,
    },

    -- vim.opt.<name> = value
    options = {
      opt = {
        -- yank/delete/paste use the system clipboard: `y` copies, `p` pastes
        -- what you copied anywhere else. (Over SSH see lua/polish.lua.)
        clipboard = "unnamedplus",
        number = true,
        relativenumber = true,
        signcolumn = "yes",
        wrap = false,
        spell = false,
        scrolloff = 8,
      },
      g = {},
    },

    -- Key mappings. First key is the mode: n = normal, v = visual, i = insert, t = terminal.
    -- Tables with only a `desc` name a which-key group. Map to `false` to delete a default.
    mappings = {
      n = {
        ["<Leader>nh"] = { function() Snacks.notifier.show_history() end, desc = "Notification history" },
        -- example: ["<Leader>w"] = { "<Cmd>w<CR>", desc = "Save" },
      },
    },

    commands = {
      Notifications = { function() Snacks.notifier.show_history() end, desc = "Show notification history" },
    },

    autocmds = {
      -- Python: fold by expression (treesitter) but start with every fold open.
      python_folds = {
        {
          event = "FileType",
          pattern = "python",
          desc = "Treesitter folds for Python, open by default",
          callback = function()
            vim.opt_local.foldmethod = "expr"
            vim.opt_local.foldenable = false
          end,
        },
      },
    },
  },
}
