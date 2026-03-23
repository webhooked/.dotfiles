return {
  "sam4llis/nvim-tundra",
  enabled = false,
  lazy = false,
  priority = 1000,
  config = function()
    require("nvim-tundra").setup({
      syntax = {
        booleans = { bold = false, italic = true },
        comments = { bold = false, italic = true },
        constants = { bold = false },
        numbers = { bold = false },
        operators = { bold = false },
      },
      plugins = {
        lsp = true,
        semantic_tokens = true,
        treesitter = true,
        cmp = true,
        context = true,
        gitsigns = true,
      },
      -- overwrite = {
      --   colors = {
      --     gray = {
      --       _900 = "#0E1420", -- An `ocean` colour instead of `sky`.
      --     },
      --   },
      -- },
    })
  end,
}
