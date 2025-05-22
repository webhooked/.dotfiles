return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
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
        hl.SnacksPickerBoxTitle = {
          bg = c.bg_dark,
          fg = c.fg_dark,
        }
        hl.SnacksPickerTitle = {
          bg = c.bg_dark,
          fg = c.fg_dark,
        }
        hl.SnacksPicker = {
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
        -- TabLineFill is currently set to black
        hl.TabLineFill = {
          bg = c.none,
        }
      end,
    },
  },
  -- {
  --   "webhooked/kanso.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   opts = {
  --     background = {
  --       light = "pearl",
  --       dark = "ink",
  --     },
  --     transparent = true,
  --   },
  -- },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
