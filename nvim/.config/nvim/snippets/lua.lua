local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local rep = require("luasnip.extras").rep

return {
  -- Function definitions
  s("fn", fmt("function {}({})\n\t{}\nend", { i(1, "name"), i(2), i(3) })),
  s("lf", fmt("local function {}({})\n\t{}\nend", { i(1, "name"), i(2), i(3) })),
  s("af", fmt("local {} = function({})\n\t{}\nend", { i(1, "name"), i(2), i(3) })),

  -- Variables
  s("l", fmt("local {} = {}", { i(1, "var"), i(2, "value") })),
  s("lt", fmt("local {} = {}", { i(1, "tbl"), i(2, "{}") })),

  -- Control structures
  s("if", fmt("if {} then\n\t{}\nend", { i(1, "condition"), i(2) })),
  s("ife", fmt("if {} then\n\t{}\nelse\n\t{}\nend", { i(1, "condition"), i(2), i(3) })),
  s("for", fmt("for {} = {}, {} do\n\t{}\nend", { i(1, "i"), i(2, "1"), i(3, "10"), i(4) })),
  s("forp", fmt("for {}, {} in pairs({}) do\n\t{}\nend", { i(1, "k"), i(2, "v"), i(3, "table"), i(4) })),
  s("fori", fmt("for {}, {} in ipairs({}) do\n\t{}\nend", { i(1, "i"), i(2, "v"), i(3, "table"), i(4) })),
  s("while", fmt("while {} do\n\t{}\nend", { i(1, "condition"), i(2) })),

  -- Neovim specific
  s("req", fmt("local {} = require('{}')", { i(1), i(2) })),
  s("keymap", fmt("vim.keymap.set('{}', '{}', {}, {{ desc = '{}' }})", { i(1, "n"), i(2), i(3), i(4) })),
  s(
    "autocmd",
    fmt(
      "vim.api.nvim_create_autocmd('{}', {{\n\tpattern = '{}',\n\tcallback = function()\n\t\t{}\n\tend,\n}})",
      { i(1, "BufRead"), i(2, "*"), i(3) }
    )
  ),
  s("opt", fmt("vim.opt.{} = {}", { i(1, "option"), i(2, "value") })),
  s("g", fmt("vim.g.{} = {}", { i(1, "variable"), i(2, "value") })),

  -- Table operations
  s("tins", fmt("table.insert({}, {})", { i(1, "table"), i(2, "value") })),
  s("trem", fmt("table.remove({}, {})", { i(1, "table"), i(2, "index") })),
  s("tcon", fmt("table.concat({}, '{}')", { i(1, "table"), i(2, ", ") })),

  -- String operations
  s("sf", fmt("string.format('{}', {})", { i(1), i(2) })),
  s("ssub", fmt("string.sub({}, {}, {})", { i(1, "str"), i(2, "start"), i(3, "end") })),
  s("smatch", fmt("string.match({}, '{}')", { i(1, "str"), i(2, "pattern") })),
  s("sgsub", fmt("string.gsub({}, '{}', '{}')", { i(1, "str"), i(2, "pattern"), i(3, "replacement") })),

  -- Common patterns
  s("print", fmt("print({})", { i(1) })),
  s("pp", fmt("print(vim.inspect({}))", { i(1) })),
  s("type", fmt("type({}) == '{}'", { i(1), i(2, "string") })),
  s("nil", fmt("if {} == nil then\n\t{}\nend", { i(1), i(2) })),
  s("not", fmt("if not {} then\n\t{}\nend", { i(1), i(2) })),

  -- Module structure
  s("mod", fmt("local M = {{}}\n\n{}\n\nreturn M", { i(1) })),
  s("ret", fmt("return {}", { i(1) })),
}
