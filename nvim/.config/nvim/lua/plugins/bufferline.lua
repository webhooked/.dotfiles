return {
  "akinsho/bufferline.nvim",
  opts = function()
    local bufferline = require("bufferline")
    local fill_hl = "StatusLine"
    local custom_bg = { attribute = "bg", highlight = fill_hl }
    return {
      highlights = {
        fill = { bg = custom_bg },
        background = { bg = custom_bg },
        close_button = { bg = custom_bg },
        offset_separator = { bg = custom_bg },
        trunc_marker = { bg = custom_bg },
        duplicate = { bg = custom_bg },
        close_button_selected = { fg = "#B55A67" }, -- *
        separator = { fg = custom_bg, bg = custom_bg },
        modified = { fg = "#B55A67", bg = custom_bg },
        hint = { bg = custom_bg },
        hint_diagnostic = { bg = custom_bg },
        info = { bg = custom_bg },
        info_diagnostic = { bg = custom_bg },
        warning = { bg = custom_bg },
        warning_diagnostic = { bg = custom_bg },
        error = { bg = custom_bg },
        error_diagnostic = { bg = custom_bg },
      },
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
          icon = "▎", -- this should be omitted if indicator style is not 'icon'
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
          {
            filetype = "NvimTree",
            highlight = "NvimTreeNormal",
            separator = false,
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
