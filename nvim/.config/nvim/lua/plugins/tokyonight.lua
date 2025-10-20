return {
  "folke/tokyonight.nvim",
  enabled = false,
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "moon",
      light_style = "storm",
      transparent = true,
      styles = {
        keywords = { italic = false },
        sidebars = "transparent",
        floats = "transparent",
      },
      hide_inactive_statusline = true,
      on_colors = function(c)
        -- Because lualine broke stuff with the latest commit
        c.bg_statusline = c.none
      end,
      on_highlights = function(hl, c)
        hl.SnacksPicker = {
          bg = c.bg_dark,
          fg = c.fg_dark,
        }
        hl.SnacksPickerSelected = {
          bg = c.bg_dark,
          fg = c.fg_dark,
        }
        hl.SnacksPickerBorder = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
        hl.SnacksPickerInputBorder = {
          bg = c.bg_dark,
          fg = c.bg_dark,
        }
        -- Dashboard highlights
        hl.SnacksDashboardHeader = {
          fg = "#C0CAF5",
        }
        hl.SnacksDashboardTitle = {
          fg = "#e0af68",
        }
        hl.SnacksDashboardDesc = {
          fg = "#C0CAF5",
        }
        hl.SnacksDashboardTerminal = {
          fg = "#C0CAF5",
        }
        hl.SnacksDashboardIcon = {
          fg = "#C0CAF5",
        }
        hl.SnacksDashboardKey = {
          fg = "#C0CAF5",
        }
        hl.SnacksDashboardFooter = {
          fg = "#C0CAF5",
        }
        hl.SnacksDashboardNormal = {
          fg = "#C0CAF5",
        }
        hl.SnacksDashboardFile = {
          fg = "#C0CAF5",
        }
        hl.SnacksDashboardSpecial = {
          fg = "#e0af68",
        }
        -- TabLineFill is currently set to black
        hl.TabLineFill = {
          bg = c.none,
        }
      end,
    })
  end,
}
