-- Markdown extras. In-buffer rendering (render-markdown.nvim) comes from
-- lua/community.lua; toggle it with :RenderMarkdown toggle.

---@type LazySpec
return {
  -- :PeekOpen / :PeekClose: live preview in a separate window. Needs `deno`;
  -- skipped automatically when deno isn't installed.
  {
    "toppair/peek.nvim",
    cond = vim.fn.executable "deno" == 1,
    build = "deno task --quiet build:fast",
    cmd = { "PeekOpen", "PeekClose" },
    config = function()
      local peek = require "peek"
      local function setup() peek.setup { app = "webview", theme = vim.o.background } end
      setup()
      vim.api.nvim_create_user_command("PeekOpen", function()
        setup() -- pick up a light/dark switch since the last preview
        peek.open()
      end, { desc = "Open markdown preview" })
      vim.api.nvim_create_user_command("PeekClose", peek.close, { desc = "Close markdown preview" })
    end,
  },
}
