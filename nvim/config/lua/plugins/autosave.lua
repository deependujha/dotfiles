-- Autosave: files save themselves, so format-on-save runs without :w.
--
-- When it saves:
--   - 1 second after you leave insert mode or change text in normal mode
--     (typing again within that second postpones it)
--   - right away when you switch buffers, leave nvim, or Neovim loses focus
-- Every autosave is a normal :w, so format on save (lua/plugins/astrolsp.lua)
-- runs as usual.
--
-- <Space>uW (or :ASToggle) turns it off/on for this session.
-- To disable it permanently, set `enabled = false` below.

---@type LazySpec
return {
  "okuuva/auto-save.nvim",
  enabled = true,
  event = { "User AstroFile", "InsertEnter" },
  cmd = "ASToggle",
  dependencies = {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>uW"] = { "<Cmd>ASToggle<CR>", desc = "Toggle autosave" },
        },
      },
    },
  },
  opts = {
    debounce_delay = 1000, -- ms to wait after the last change before saving
    -- Only real files: skip terminals, file explorer, help, quickfix, git
    -- commit messages (saving would end the commit early) and unnamed buffers.
    condition = function(buf)
      local bo = vim.bo[buf]
      if bo.buftype ~= "" or not bo.modifiable or bo.readonly then return false end
      if vim.api.nvim_buf_get_name(buf) == "" then return false end
      if vim.tbl_contains({ "gitcommit", "gitrebase", "oil" }, bo.filetype) then return false end
      return true
    end,
  },
}
