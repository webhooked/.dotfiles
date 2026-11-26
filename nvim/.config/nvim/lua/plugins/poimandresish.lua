return {
  -- Local checkout until the light variant is pushed; then back to
  -- "webhooked/poimandresish.nvim".
  dir = vim.fn.expand("~/repos/private/themes/neovim/poimandresish.nvim"),
  name = "poimandresish",
  enabled = true,
  lazy = false,
  priority = 1000,
  opts = {
    bold = false,
    italics = false,
    transparent = true,
    -- auto-dark-mode.lua flips 'background' with macOS, which reloads the
    -- theme in the matching variant.
    background = {
      light = "light",
      dark = "night",
    },
  },
}
