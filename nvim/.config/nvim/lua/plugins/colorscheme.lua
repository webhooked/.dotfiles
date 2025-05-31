return {
  -- {
  --   dir = "/Users/webhooked/repos/private/themes/neovim/night-owl.nvim",
  --   name = "night-owl",
  --   lazy = false,
  --   priority = 1000,
  --   dev = true,
  --   opts = {
  --     bold = false,
  --     italics = false,
  --     transparent_background = true,
  --   },
  -- },
  -- {
  --   dir = "/Users/webhooked/repos/private/themes/neovim/kanso.nvim",
  --   name = "kanso",
  --   lazy = false,
  --   priority = 1000,
  --   dev = true,
  --   opts = {
  --     background = {
  --       light = "pearl",
  --       dark = "ink",
  --     },
  --     bold = false,
  --     italics = false,
  --     transparent_background = true,
  --   },
  -- },
  {
    "webhooked/kanso.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      background = {
        light = "pearl",
        dark = "ink",
      },
      transparent = true,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanso",
    },
  },
}
