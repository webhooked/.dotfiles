return {
  "nvim-lualine/lualine.nvim",
  optional = true,
  event = "VeryLazy",
  config = function()
    require("lualine").setup({
      options = {
        theme = "polar",
        component_separators = "",
        section_separators = "",
      },
    })
  end,
}
