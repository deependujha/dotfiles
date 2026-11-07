-- Snippets available in EVERY filetype (all.lua = "all").
-- Per-language snippets go next to this file, named after the filetype:
-- python.lua, cpp.lua, rust.lua, go.lua, ... (`:set ft?` shows a buffer's filetype).
--
-- Type the trigger (e.g. `main`), pick it from the completion menu with <CR>,
-- then <Tab>/<S-Tab> jumps between the placeholders.
-- Edits are picked up when you save the file; no restart needed.
-- Docs: https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md

local ls = require "luasnip"
local s = ls.snippet -- s(trigger, nodes) or s({ trig = ..., desc = ... }, nodes)
local t = ls.text_node -- fixed text; a table of strings = several lines
local i = ls.insert_node -- placeholder you type into: i(jump_order, default_text)

return {
  -- Python entry point.
  s({ trig = "main", desc = "Python main() + __name__ guard" }, {
    t { "def main():", "    " },
    i(1, "pass"),
    t { "", "", "", 'if __name__ == "__main__":', "    main()" },
  }),
}
