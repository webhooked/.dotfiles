return {
  "stevearc/oil.nvim",
  ---@module 'oil'
  ---@type oil.SetupOpts
  -- Optional dependencies
  dependencies = { { "echasnovski/mini.icons" } },
  keys = {
    { "<leader>o", "<cmd>Oil --float<cr>", desc = "Oil Float - Parent Dir" },
    { "-", "<cmd>Oil --float<cr>", desc = "Oil Float - Parent Dir" },
  },
  opts = {
    keymaps = {
      ["<C-s>"] = false,
      -- ["<C-h>"] = false,
      ["q"] = "actions.close",
      -- ["<leader>-"] = "actions.close",
      ["<C-h>"] = "actions.parent",
      ["<C-l>"] = "actions.select",
      ["gd"] = {
        desc = "Toggle file detail view",
        callback = function()
          detail = not detail
          if detail then
            require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
          else
            require("oil").set_columns({ "icon" })
          end
        end,
      },
      ["<Tab>"] = "actions.select",
      ["<S-Tab>"] = "actions.open_cwd",
    },
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
    float = {
      padding = 2,
      max_width = 90,
      max_height = 0,
    },
    win_options = {
      wrap = true,
      winblend = 0,
    },
  },
  lazy = false,
}
