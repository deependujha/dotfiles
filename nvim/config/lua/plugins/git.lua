-- Git integration on top of AstroNvim's defaults (gitsigns + lazygit on <Leader>gg).

---@type LazySpec
return {
  -- Show who last changed the current line, inline.
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true, -- toggle with :Gitsigns toggle_current_line_blame
      current_line_blame_opts = { delay = 300 },
    },
  },

  -- :Git <anything>  (:Git blame, :Git log, :Gdiffsplit, ...)
  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "GBrowse" } },

  -- Open the PR that introduced the line under the cursor.
  {
    "h3pei/trace-pr.nvim",
    cmd = { "TracePR" },
    opts = {},
  },
}
