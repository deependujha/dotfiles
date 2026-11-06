-- AstroCommunity: ready-made plugin bundles maintained by the AstroNvim community.
-- Browse everything available at https://github.com/AstroNvim/astrocommunity
--
-- A "pack" sets up one language end to end: treesitter parser, LSP server,
-- formatter/linter and (where it exists) a debugger, all installed by Mason.
--
-- To add a language: add one `{ import = "astrocommunity.pack.<name>" }` line,
-- restart nvim, and Mason installs the tools. To drop one, delete its line.

---@type LazySpec
return {
  "AstroNvim/astrocommunity",

  -- Languages ---------------------------------------------------------------
  { import = "astrocommunity.pack.cpp" }, -- clangd, clangd_extensions, cmake-tools, codelldb
  { import = "astrocommunity.pack.python.base" }, -- python parser, debugpy, venv-selector (<Leader>lv)
  { import = "astrocommunity.pack.python.basedpyright" }, -- type checking / completion
  { import = "astrocommunity.pack.python.ruff" }, -- linting + formatting (replaces black/isort)
  { import = "astrocommunity.pack.rust" }, -- rustaceanvim, crates.nvim, codelldb
  { import = "astrocommunity.pack.go" }, -- gopls, goimports, delve
  { import = "astrocommunity.pack.markdown" }, -- marksman
  { import = "astrocommunity.pack.html-css" }, -- html, cssls, emmet
  { import = "astrocommunity.pack.typescript" }, -- vtsls for JS/TS/JSX/TSX, js-debug-adapter
  { import = "astrocommunity.pack.prettier" }, -- prettierd for web files (format with <Leader>lf)
  { import = "astrocommunity.pack.lua" }, -- so editing this config gets completion
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.toml" },
  { import = "astrocommunity.pack.bash" },

  -- Markdown rendered inside the buffer (headings, tables, checkboxes) ---------
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },

  -- Themes (which one is active is chosen in lua/plugins/theme.lua) -----------
  { import = "astrocommunity.colorscheme.catppuccin" },
}
