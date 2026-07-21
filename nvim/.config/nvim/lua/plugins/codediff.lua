return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  keys = {
    { "<leader>da", mode = { "n", "v" }, "<cmd>CodeDiff<cr>", desc = "Open diff (changes explorer)" },
    { "<leader>dfh", mode = { "n", "v" }, "<cmd>CodeDiff history % --base WORKING<CR>", desc = "File history (with uncommitted)" },
    { "<leader>dbh", mode = { "n", "v" }, "<cmd>CodeDiff history<CR>", desc = "Current branch history" },
    -- codediff has no `--cached` equivalent; the explorer groups staged changes
    -- separately (toggle with `gs` / `gu` inside the view).
    { "<leader>ds", mode = { "n", "v" }, "<cmd>CodeDiff<CR>", desc = "View staged changes (explorer)" },
    -- codediff diffs live in their own tab; `q` closes natively, this mirrors <leader>dq.
    { "<leader>dq", mode = { "n", "v" }, "<cmd>tabclose<cr>", desc = "Close diff" },
  },
  opts = {
    keymaps = {
      view = {
        -- Custom navigation keymaps. Reassigning each action moves it off its
        -- default key, so ]f / [f / gf are freed automatically.
        ["next_file"] = "<leader>dm", -- Next file (was ]f)
        ["prev_file"] = "<leader>dn", -- Previous file (was [f)
        ["open_in_prev_tab"] = "<leader>dt", -- Open file in previous tab (was gf)
      },
    },
  },
}
