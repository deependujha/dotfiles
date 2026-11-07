-- Treesitter: syntax highlighting, indentation and text objects from real parsers.
-- Language packs add their own parsers; these are extras that are always handy.
-- `auto_install` fetches a parser the first time you open a file that needs it.
-- Manage by hand with `:TSInstall <lang>`, `:TSUpdate`, `:checkhealth nvim-treesitter`.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true,
      indent = true,
      auto_install = true,
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "query",
        "regex",
        "bash",
        "diff",
        "git_config",
        "gitcommit",
        "git_rebase",
        "gitignore",
        "dockerfile",
        "make",
        "cmake",
        "sql",
      },
    },
  },
}
