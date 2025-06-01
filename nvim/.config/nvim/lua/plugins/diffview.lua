return {
  "sindrets/diffview.nvim",
  keys = {
    { "<leader>da", mode = { "n", "v" }, "<cmd>DiffviewOpen<cr>", desc = "Open diffview" },
    { "<leader>dfh", mode = { "n", "v" }, "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
    { "<leader>dbh", mode = { "n", "v" }, "<cmd>DiffviewFileHistory<CR>", desc = "Current branch history" },
  },
}
