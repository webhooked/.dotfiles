return {
  "f-person/auto-dark-mode.nvim",
  enabled = false,
  opts = {
    set_dark_mode = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("rose-pine-main")
    end,
    set_light_mode = function()
      vim.o.background = "light"
      vim.cmd.colorscheme("rose-pine-moon")
    end,
  },
}
