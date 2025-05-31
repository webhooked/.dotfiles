return {
  "folke/snacks.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    {
      "<leader>fb",
      function()
        require("snacks").picker.buffers()
      end,
      desc = "Find Buffers",
    },
    {
      "<leader><leader>",
      function()
        require("snacks").picker.files()
      end,
      desc = "Find Files",
    },
    {
      "<leader>lg",
      function()
        require("snacks").lazygit()
      end,
      desc = "Lazygit",
    },
    {
      "<leader>gl",
      function()
        require("snacks").lazygit.log()
      end,
      desc = "Lazygit Logs",
    },
    {
      "<leader>rN",
      function()
        require("snacks").rename.rename_file()
      end,
      desc = "Fast Rename Current File",
    },
    {
      "<leader>dB",
      function()
        require("snacks").bufdelete()
      end,
      desc = "Delete or Close Buffer  (Confirm)",
    },

    -- Snacks Picker
    {
      "<leader>sc",
      function()
        require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config File",
    },
  },
  opts = {
    dashboard = {
      width = 60,
      row = nil,
      col = nil,
      pane_gap = 4,
      autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
      preset = {
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
        header = [[
░░     ░░ ░░░░░░░ ░░░░░░  ░░   ░░  ░░░░░░   ░░░░░░  ░░   ░░ ░░░░░░░ ░░░░░░  
▒▒     ▒▒ ▒▒      ▒▒   ▒▒ ▒▒   ▒▒ ▒▒    ▒▒ ▒▒    ▒▒ ▒▒  ▒▒  ▒▒      ▒▒   ▒▒ 
▒▒  ▒  ▒▒ ▒▒▒▒▒   ▒▒▒▒▒▒  ▒▒▒▒▒▒▒ ▒▒    ▒▒ ▒▒    ▒▒ ▒▒▒▒▒   ▒▒▒▒▒   ▒▒   ▒▒ 
▓▓ ▓▓▓ ▓▓ ▓▓      ▓▓   ▓▓ ▓▓   ▓▓ ▓▓    ▓▓ ▓▓    ▓▓ ▓▓  ▓▓  ▓▓      ▓▓   ▓▓ 
 ███ ███  ███████ ██████  ██   ██  ██████   ██████  ██   ██ ███████ ██████  
          ]],
      },
      sections = {
        { section = "header" },
        { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
        { icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
        { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
        { section = "startup" },
      },
    },
    picker = {
      exclude = { -- add folder names here to exclude
        ".git",
        "node_modules",
        ".next",
        "target",
        ".idea",
      },
      sources = {
        files = { hidden = true, ignored = true },
        grep = { hidden = true, ignored = true },
        explorer = { hidden = true, ignored = true },
      },
      win = {
        input = {
          keys = {
            ["<C-p>"] = { "focus_preview", mode = { "i", "n" } },
          },
        },
        list = {
          keys = {
            ["<C-p>"] = { "focus_preview", mode = { "n" } },
          },
        },
        preview = {
          keys = {
            ["<C-p>"] = { "focus_input", mode = { "n" } },
          },
        },
      },
      formatters = {
        file = { filename_first = false },
      },
      layout = {
        layout = {
          box = "horizontal",
          width = 0.8,
          min_width = 120,
          height = 0.8,
          {
            box = "vertical",
            border = "rounded",
            title = "{title} {live} {flags}",
            { win = "input", height = 1, border = "bottom" },
            { win = "list", border = "none" },
          },
          { win = "preview", title = "{preview}", border = "rounded", width = 0.5 },
        },
      },
    },
  },
}
