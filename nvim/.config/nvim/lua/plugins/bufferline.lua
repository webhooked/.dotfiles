return {
  "akinsho/bufferline.nvim",
  opts = function()
    local bufferline = require("bufferline")

    return {
      highlights = require("polar.plugins.bufferline").akinsho(),
      options = {
        show_buffer_close_icons = false,
        show_buffer_icons = false, -- disable filetype icons for buffers
        show_close_icon = true,
        show_tab_indicators = false,
        buffer_close_icon = "",
        modified_icon = "",
        diagnostics = "nvim_lsp",
        -- diagnostics = false,
        always_show_bufferline = true,
        indicator = {
          icon = " ", -- this should be omitted if indicator style is not 'icon'
          -- style = "none", -- "icon" | "underline" | "none",
        },
        separator_style = { " ", " " },
        offsets = {
          {
            -- filetype = "neo-tree",
            -- text = "Neo-tree",
            -- highlight = "BufferLineBackground",
            -- highlight = "NeoTreeNormal",
            text_align = "center",
          },
        },
        style_preset = {
          bufferline.style_preset.no_italic,
          bufferline.style_preset.no_bold,
        },
      },
    }
  end,
}
