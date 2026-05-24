return {
  "nvim-lualine/lualine.nvim",
  optional = true,
  event = "VeryLazy",
  config = function()
    local custom_theme = require("lualine.themes.auto")
    for _, mode in pairs(custom_theme) do
      for _, section in pairs(mode) do
        section.bg = "NONE"
      end
    end

    require("lualine").setup({
      options = {
        theme = custom_theme,
        component_separators = "",
        section_separators = "",
      },
    })
  end,
}
