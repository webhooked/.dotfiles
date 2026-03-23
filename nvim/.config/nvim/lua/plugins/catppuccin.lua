return {
  "catppuccin/nvim",
  enabled = false,
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      background = {
        light = "frappe",
        dark = "mocha",
      },
      color_overrides = {
        mocha = {
          base = "#101219",
          mantle = "#101219",
          crust = "#181823",
          mauve = "#bac2de",
          pink = "#f5e0dc",
        },
        frappe = {
          mauve = "#bac2de",
          pink = "#f5e0dc",
        },
        macchiato = {
          mauve = "#bac2de",
          pink = "#f5e0dc",
        },
      },
    })
  end,
}
