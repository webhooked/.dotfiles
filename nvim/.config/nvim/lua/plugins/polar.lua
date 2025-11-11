return {
  -- dir = "/Users/webhooked/repos/private/themes/neovim/polar.nvim",
  -- dev = true,
  "webhooked/polar.nvim",
  lazy = false,
  priority = 1000,
  enabled = false,
  config = function()
    require("polar").setup({
      transparent = true,
      borders = false,
    })
  end,
}
