return {
  "nvim-lualine/lualine.nvim",
  optional = true,
  event = "VeryLazy",
  config = function()
    require("lualine").setup({
      options = {
        component_separators = "",
        section_separators = "",
      },
    })
  end,
}
