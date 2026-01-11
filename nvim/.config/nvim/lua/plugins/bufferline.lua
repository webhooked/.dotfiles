return {
  "akinsho/bufferline.nvim",
  enabled = false,
  keys = {
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
    { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
    { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
    { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
    {
      "<leader>bd",
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        -- Check if buffer is pinned
        if vim.b[bufnr].bufferline_pinned then
          vim.notify("Cannot delete pinned buffer", vim.log.levels.WARN)
          return
        end
        require("snacks").bufdelete()
      end,
      desc = "Delete Buffer (respect pinned)",
    },
  },
  opts = function()
    local bufferline = require("bufferline")

    return {
      -- highlights = require("polar.plugins.bufferline").akinsho(),
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
        close_command = function(bufnum)
          -- Check if buffer is pinned before closing
          if vim.b[bufnum].bufferline_pinned then
            vim.notify("Cannot close pinned buffer", vim.log.levels.WARN)
            return
          end
          require("snacks").bufdelete(bufnum)
        end,
      },
    }
  end,
}
