return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  opts = function(_, opts) end,
  config = function(_, opts)
    require("telescope").setup({
      defaults = {

        mappings = {
          i = {
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
          },
          n = {
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
          },
        },
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--hidden",
        },
        file_ignore_patterns = {
          "node_modules/.*",
          ".idea",
          "yarn.lock",
          "package%-lock.json",
          "lazy%-lock.json",
          "init.sql",
          "target/.*",
          ".git/.*",
        },
        preview = {
          treesitter = false,
        },
      },
      pickers = {
        find_files = {
          hidden = true,
          no_ignore = true,
        },
        live_grep = {
          additional_args = function()
            return { "--hidden", "--no-ignore" }
          end,
        },
        grep_string = {
          additional_args = function()
            return { "--hidden", "--no-ignore" }
          end,
        },
      },
    })
    require("telescope").load_extension("fzf")
  end,
}
