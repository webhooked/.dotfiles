return {
  "stevearc/oil.nvim",
  ---@module 'oil'
  ---@type oil.SetupOpts
  -- Optional dependencies
  dependencies = { { "echasnovski/mini.icons" } },
  keys = {
    {
      "<leader>o",
      function()
        require("oil").open()
      end,
      desc = "[F]ormat buffer",
    },
  },
  opts = {
    keymaps = {
      ["<Tab>"] = "actions.select",
      ["<S-Tab>"] = "actions.open_cwd",
    },
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
  },
  lazy = false,
}
