return {
  "L3MON4D3/LuaSnip",
  version = "v2.*",
  build = "make install_jsregexp",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local ls = require("luasnip")

    -- Configure LuaSnip
    ls.config.set_config({
      history = true,
      updateevents = "TextChanged,TextChangedI",
      enable_autosnippets = true,
      ext_opts = {
        [require("luasnip.util.types").choiceNode] = {
          active = {
            virt_text = { { "●", "DiagnosticHint" } },
          },
        },
      },
    })

    -- Load friendly-snippets
    require("luasnip.loaders.from_vscode").lazy_load()
    
    -- Load custom snippets
    require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/snippets/" })

    -- Choice selection keymap (not handled by blink.cmp)
    vim.keymap.set({ "i", "s" }, "<C-n>", function()
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end, { silent = true, desc = "Change choice in snippet" })


    -- Auto-reload snippets on save
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = vim.fn.stdpath("config") .. "/snippets/*.lua",
      callback = function()
        require("luasnip.loaders.from_lua").load({ paths = vim.fn.stdpath("config") .. "/snippets/" })
        vim.notify("Snippets reloaded!", vim.log.levels.INFO)
      end,
      desc = "Reload LuaSnip snippets on save",
    })
  end,
}