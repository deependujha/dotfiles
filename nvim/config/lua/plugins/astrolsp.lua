-- AstroLSP: language server behaviour (formatting, per-server settings, keymaps).
-- Docs: `:h astrolsp`. Which servers get installed is decided by the packs in
-- lua/community.lua and the list in lua/plugins/mason.lua.

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      codelens = true,
      inlay_hints = false, -- toggle at runtime with <Leader>uH
      semantic_tokens = true,
    },

    formatting = {
      format_on_save = {
        enabled = true, -- toggle at runtime: <Leader>uf (buffer) / <Leader>uF (global)
        -- Only these filetypes format on save. Remove `allow_filetypes` to format
        -- everything on save. Any file can be formatted by hand with <Leader>lf.
        allow_filetypes = { "go", "python", "rust" },
        ignore_filetypes = {},
      },
      disabled = {}, -- server names whose formatting should never be used
      timeout_ms = 2000,
    },

    -- Servers you installed yourself (not with Mason) that should still be started:
    servers = {},

    -- Per-server settings, passed to `vim.lsp.config(<name>, ...)`.
    config = {
      -- Use the active virtualenv ($VIRTUAL_ENV) when nvim is started from one.
      basedpyright = {
        before_init = function(_, config)
          local venv = vim.env.VIRTUAL_ENV
          if not venv then return end
          config.settings = config.settings or {}
          config.settings.python = config.settings.python or {}
          config.settings.python.pythonPath = venv .. "/bin/python"
        end,
      },
    },

    mappings = {
      n = {
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
      },
    },
  },
}
