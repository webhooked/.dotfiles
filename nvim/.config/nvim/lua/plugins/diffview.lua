return {
  "sindrets/diffview.nvim",
  keys = {
    { "<leader>da", mode = { "n", "v" }, "<cmd>DiffviewOpen<cr>", desc = "Open diffview" },
    { "<leader>dfh", mode = { "n", "v" }, "<cmd>DiffviewFileHistory --base=LOCAL %<CR>", desc = "File history (with uncommitted)" },
    { "<leader>dbh", mode = { "n", "v" }, "<cmd>DiffviewFileHistory<CR>", desc = "Current branch history" },
    { "<leader>ds", mode = { "n", "v" }, "<cmd>DiffviewOpen --cached<CR>", desc = "View staged changes" },
    { "<leader>dq", mode = { "n", "v" }, "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
  },
  opts = {
    keymaps = {
      view = {
        -- Custom navigation keymaps
        ["<leader>dm"] = "select_next_entry", -- Next file (was ]f)
        ["<leader>dn"] = "select_prev_entry", -- Previous file (was [f)
        ["<leader>dt"] = function()
          require("diffview.config").actions.goto_file_tab()
        end, -- Open file in new tab
        -- Disable default keymaps
        ["]f"] = false,
        ["[f"] = false,
        ["<tab>"] = false,
        ["<s-tab>"] = false,
      },
      file_panel = {
        -- Custom navigation keymaps for file panel
        ["<leader>dm"] = "select_next_entry", -- Next file (was <tab>)
        ["<leader>dn"] = "select_prev_entry", -- Previous file (was <s-tab>)
        ["<leader>dt"] = function()
          require("diffview.config").actions.goto_file_tab()
        end, -- Open file in new tab
        -- Disable default keymaps
        ["<tab>"] = false,
        ["<s-tab>"] = false,
      },
    },
  },
}
