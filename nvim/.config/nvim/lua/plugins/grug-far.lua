return {
  "magicduck/grug-far.nvim",
  opts = { headermaxwidth = 80 },
  cmd = "GrugFar",
  keys = {
    -- Disable the default <leader>sr mapping
    { "<leader>sr", false },

    -- Project-wide search
    {
      "<leader>sra",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesfilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "v" },
      desc = "grug-far: project-wide search",
    },

    -- Current file search
    {
      "<leader>src",
      function()
        local grug = require("grug-far")
        grug.open({
          transient = true,
          prefills = {
            paths = vim.fn.expand("%"),
          },
        })
      end,
      mode = { "n", "v" },
      desc = "grug-far: current file",
    },

    -- Visual selection search
    {
      "<leader>srw",
      function()
        require("grug-far").with_visual_selection({
          prefills = { paths = vim.fn.expand("%") },
        })
      end,
      mode = "v",
      desc = "grug-far: visual selection",
    },
  },
}
