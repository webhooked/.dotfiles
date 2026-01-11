return {
  "nexxeln/vesper.nvim",
  enabled = false,
  lazy = false,
  priority = 1000,
  config = function()
    require("vesper").setup({
      transparent = true,
    })

    local function set_vesper_overrides()
      vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#333333" })
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
