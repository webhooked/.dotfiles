return {
  "nexxeln/vesper.nvim",
  enabled = true,
  lazy = false,
  priority = 1000,
  config = function()
    require("vesper").setup({
      transparent = true,
      palette_overrides = {
        bg = "#282828", -- was #101010
        bgFloat = "#343434", -- was #282828
        bgOption = "#505050", -- was #343434 (drives CursorLine, PmenuSel, WildMenu)
      },
    })

    local function set_vesper_overrides()
      vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#333333" })

      -- dropbar.nvim: transparent bar/menu bg, #505050 for selection/hover
      vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "DropBarMenuNormalFloat", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "DropBarMenuFloatBorder", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "DropBarCurrentContext", { bg = "#505050" })
      vim.api.nvim_set_hl(0, "DropBarHover", { bg = "#505050" })
      vim.api.nvim_set_hl(0, "DropBarPreview", { bg = "#505050" })
      vim.api.nvim_set_hl(0, "DropBarMenuCurrentContext", { bg = "#505050" })
      vim.api.nvim_set_hl(0, "DropBarMenuHoverEntry", { bg = "#505050" })
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "vesper",
      callback = set_vesper_overrides,
    })

    -- Also run after startup to catch initial load
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.g.colors_name == "vesper" then
          set_vesper_overrides()
        end
      end,
    })
  end,
}
