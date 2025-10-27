return {
  {
    "saghen/blink.cmp",
    lazy = false, -- lazy loading handled internally
    dependencies = {
      { "L3MON4D3/LuaSnip", version = "v2.*" },
    },
    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    ---@diagnostic disable: missing-fields
    opts = {
      keymap = {
        preset = "default",
        ["<C-l>"] = { "snippet_forward", "fallback" },
        ["<C-h>"] = { "snippet_backward", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide" },
        ["<Tab>"] = { "accept", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
      },
      completion = {
        list = {
          selection = { preselect = false, auto_insert = false },
        },
        menu = {
          border = "rounded",
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
      },
      signature = { enabled = true },
      snippets = { preset = "luasnip" },
      appearance = {
        nerd_font_variant = "mono",
        kind_icons = {
          Text = "󰉿",
          Method = "󰊕",
          Function = "󰊕",
          Constructor = "󰒓",
          Field = "󰜢",
          Variable = "󰆦",
          Class = "󰠱",
          Interface = "󰠱",
          Module = "󰆧",
          Property = "󰖷",
          Unit = "󱉸",
          Value = "󰎠",
          Enum = "󰖷",
          Keyword = "󰌋",
          Snippet = "󰘮",
          Color = "󰏘",
          File = "󰈙",
          Reference = "󰬲",
          Folder = "󰉋",
          EnumMember = "󰖷",
          Constant = "󰏿",
          Struct = "󰠱",
          Event = "󰉁",
          Operator = "󰆕",
          TypeParameter = "󰗴",
        },
      },
      sources = {
        default = {
          "lsp",
          "path",
          "snippets",
          "buffer",
        },
      },
    },
    opts_extend = {
      "sources.default",
    },
  },
}
