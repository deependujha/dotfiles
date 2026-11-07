-- Mason installs language servers, formatters, linters and debuggers into
-- ~/.local/share/nvim/mason. The language packs in lua/community.lua add their
-- own tools; list anything extra here, using the names shown in `:Mason`.
-- `:MasonToolsInstall` installs anything missing, `:MasonToolsUpdate` updates.

---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed or {}, {
        "tree-sitter-cli", -- compiles treesitter parsers (nvim-treesitter needs it)
        "rust-analyzer", -- the rust pack uses rustaceanvim, which expects this on PATH
        "stylua",
      })
    end,
  },
}
