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

-- JavaScript snippets (same as TypeScript but without TS-specific ones)
return {
  -- Console log
  s("cl", fmt("console.log({});", { i(1) })),
  s("cll", fmt("console.log('{}:', {});", { rep(1), i(1) })),
  s("cle", fmt("console.error('{}:', {});", { rep(1), i(1) })),
  
  -- Function declarations
  s("fn", fmt("function {}({}) {{\n\t{}\n}}", { i(1, "name"), i(2), i(3) })),
  s("af", fmt("const {} = ({}) => {{\n\t{}\n}}", { i(1, "name"), i(2), i(3) })),
  s("afn", fmt("const {} = ({}) => {}", { i(1, "name"), i(2), i(3) })),
  
  -- Async/await
  s("asf", fmt("async function {}({}) {{\n\t{}\n}}", { i(1, "name"), i(2), i(3) })),
  s("asa", fmt("const {} = async ({}) => {{\n\t{}\n}}", { i(1, "name"), i(2), i(3) })),
  s("aw", fmt("await {}", { i(1) })),
  
  -- Try/catch
  s("try", fmt("try {{\n\t{}\n}} catch (error) {{\n\t{}\n}}", { i(1), i(2, "console.error(error);") })),
  
  -- React hooks
  s("us", fmt("const [{}, set{}] = useState({});", { 
    i(1, "state"), 
    f(function(args) return args[1][1]:gsub("^%l", string.upper) end, {1}), 
    i(2) 
  })),
  s("ue", fmt("useEffect(() => {{\n\t{}\n}}, [{}]);", { i(1), i(2) })),
  s("uc", fmt("const {} = useCallback(({}) => {{\n\t{}\n}}, [{}]);", { i(1, "callback"), i(2), i(3), i(4) })),
  s("um", fmt("const {} = useMemo(() => {{\n\t{}\n}}, [{}]);", { i(1, "memoized"), i(2), i(3) })),
  s("ur", fmt("const {} = useRef({});", { i(1, "ref"), i(2, "null") })),
  
  -- React components
  s("rfc", fmt("export default function {}({}) {{\n\treturn (\n\t\t{}\n\t);\n}}", { i(1, "Component"), i(2), i(3, "<div></div>") })),
  s("rafce", fmt("import React from 'react';\n\nconst {} = ({}) => {{\n\treturn (\n\t\t{}\n\t);\n}};\n\nexport default {};", { i(1, "Component"), i(2), i(3, "<div></div>"), rep(1) })),
  
  -- Import/Export
  s("imp", fmt("import {} from '{}';", { i(1), i(2) })),
  s("imn", fmt("import '{}';", { i(1) })),
  s("imd", fmt("import {} from '{}';", { i(1, "{ }"), i(2) })),
  s("exp", fmt("export {{ {} }};", { i(1) })),
  s("exd", fmt("export default {};", { i(1) })),
  
  -- Destructuring
  s("des", fmt("const {{ {} }} = {};", { i(1), i(2) })),
  s("desa", fmt("const [{}] = {};", { i(1), i(2) })),
  
  -- Promise handling
  s("prom", fmt("new Promise((resolve, reject) => {{\n\t{}\n}});", { i(1) })),
  s("then", fmt(".then(({}) => {{\n\t{}\n}});", { i(1, "response"), i(2) })),
  s("catch", fmt(".catch(({}) => {{\n\t{}\n}});", { i(1, "error"), i(2) })),
  
  -- Test snippets
  s("desc", fmt("describe('{}', () => {{\n\t{}\n}});", { i(1), i(2) })),
  s("test", fmt("test('{}', () => {{\n\t{}\n}});", { i(1), i(2) })),
  s("it", fmt("it('{}', () => {{\n\t{}\n}});", { i(1), i(2) })),
  s("expect", fmt("expect({}).{}", { i(1), i(2, "toBe()") })),
  
  -- Common patterns
  s("ternary", fmt("{} ? {} : {}", { i(1), i(2), i(3) })),
  s("iife", fmt("(() => {{\n\t{}\n}})();", { i(1) })),
  s("req", fmt("const {} = require('{}');", { i(1), i(2) })),
}