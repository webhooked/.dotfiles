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
  -- Package and imports
  s("pkg", fmt("package {}", { i(1, "main") })),
  s("imp", fmt("import \"{}\"", { i(1) })),
  s("imps", fmt("import (\n\t\"{}\"\n)", { i(1) })),
  
  -- Basic function
  s("fn", fmt("func {}({}) {} {{\n\t{}\n}}", { i(1, "name"), i(2), i(3), i(4) })),
  s("fnn", fmt("func {}({}) {{\n\t{}\n}}", { i(1, "name"), i(2), i(3) })),
  
  -- Main function
  s("main", fmt("func main() {{\n\t{}\n}}", { i(1) })),
  
  -- Method
  s("meth", fmt("func ({} {}) {}({}) {} {{\n\t{}\n}}", { i(1, "r"), i(2, "Receiver"), i(3, "Method"), i(4), i(5), i(6) })),
  
  -- Error handling
  s("iferr", fmt("if err != nil {{\n\t{}\n}}", { i(1, "return err") })),
  s("errn", t("if err != nil {\n\treturn nil, err\n}")),
  s("errf", fmt("if err != nil {{\n\treturn fmt.Errorf(\"{}: %w\", {})\n}}", { i(1, "failed to"), i(2, "err") })),
  
  -- Printf debugging
  s("pf", fmt("fmt.Printf(\"{}: %+v\\n\", {})", { rep(1), i(1) })),
  s("pl", fmt("fmt.Println({})", { i(1) })),
  s("ps", fmt("fmt.Sprintf(\"{}\", {})", { i(1), i(2) })),
  
  -- Struct
  s("st", fmt("type {} struct {{\n\t{}\n}}", { i(1, "Name"), i(2) })),
  
  -- Interface
  s("int", fmt("type {} interface {{\n\t{}\n}}", { i(1, "Name"), i(2) })),
  
  -- For loops
  s("for", fmt("for {} {{\n\t{}\n}}", { i(1, "condition"), i(2) })),
  s("fori", fmt("for i := 0; i < {}; i++ {{\n\t{}\n}}", { i(1, "length"), i(2) })),
  s("forr", fmt("for {}, {} := range {} {{\n\t{}\n}}", { i(1, "key"), i(2, "value"), i(3, "slice"), i(4) })),
  s("fors", fmt("for {} := range {} {{\n\t{}\n}}", { i(1, "value"), i(2, "slice"), i(3) })),
  
  -- Conditionals
  s("if", fmt("if {} {{\n\t{}\n}}", { i(1, "condition"), i(2) })),
  s("ife", fmt("if {} {{\n\t{}\n}} else {{\n\t{}\n}}", { i(1, "condition"), i(2), i(3) })),
  s("sw", fmt("switch {} {{\ncase {}:\n\t{}\ndefault:\n\t{}\n}}", { i(1), i(2), i(3), i(4) })),
  
  -- Variable declarations
  s("var", fmt("var {} {}", { i(1, "name"), i(2, "type") })),
  s("vars", fmt("var (\n\t{}\n)", { i(1) })),
  s("const", fmt("const {} = {}", { i(1, "name"), i(2, "value") })),
  s("consts", fmt("const (\n\t{}\n)", { i(1) })),
  
  -- Channel operations
  s("ch", fmt("make(chan {})", { i(1, "type") })),
  s("chb", fmt("make(chan {}, {})", { i(1, "type"), i(2, "buffer") })),
  s("go", fmt("go func() {{\n\t{}\n}}()", { i(1) })),
  s("sel", fmt("select {{\ncase {}:\n\t{}\ndefault:\n\t{}\n}}", { i(1), i(2), i(3) })),
  
  -- HTTP handlers
  s("hf", fmt("func {}(w http.ResponseWriter, r *http.Request) {{\n\t{}\n}}", { i(1, "handler"), i(2) })),
  s("json", fmt("json.NewEncoder(w).Encode({})", { i(1) })),
  
  -- Test functions
  s("test", fmt("func Test{}(t *testing.T) {{\n\t{}\n}}", { i(1, "Function"), i(2) })),
  s("bench", fmt("func Benchmark{}(b *testing.B) {{\n\tfor i := 0; i < b.N; i++ {{\n\t\t{}\n\t}}\n}}", { i(1, "Function"), i(2) })),
  s("tab", fmt("tests := []struct {{\n\tname string\n\t{}\n}}{{\n\t{{\n\t\tname: \"{}\",\n\t\t{}\n\t}},\n}}\nfor _, tt := range tests {{\n\tt.Run(tt.name, func(t *testing.T) {{\n\t\t{}\n\t}})\n}}", { i(1), i(2), i(3, "test case"), i(4) })),
  
  -- Defer, panic, recover
  s("def", fmt("defer {}", { i(1) })),
  s("panic", fmt("panic(\"{}\")", { i(1) })),
  s("recover", fmt("if r := recover(); r != nil {{\n\t{}\n}}", { i(1) })),
  
  -- Common patterns
  s("empty", fmt("if len({}) == 0 {{\n\t{}\n}}", { i(1, "slice"), i(2) })),
  s("nil", fmt("if {} == nil {{\n\t{}\n}}", { i(1), i(2) })),
  s("make", fmt("make({}, {})", { i(1, "[]type"), i(2, "0") })),
  s("append", fmt("{} = append({}, {})", { rep(1), i(1, "slice"), i(2, "element") })),
  
  -- Context
  s("ctx", t("ctx context.Context")),
  s("ctxb", t("ctx := context.Background()")),
  s("ctxt", fmt("ctx, cancel := context.WithTimeout(context.Background(), {})\ndefer cancel()", { i(1, "time.Second") })),
  
  -- JSON tags
  s("jsontag", fmt("`json:\"{}\"`", { i(1, "field_name") })),
  s("jsonom", fmt("`json:\"{},omitempty\"`", { i(1, "field_name") })),
}