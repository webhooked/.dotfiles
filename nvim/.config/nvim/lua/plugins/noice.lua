return {
  "folke/noice.nvim",
  opts = function(_, opts)
    opts.presets.lsp_doc_border = true
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
}
