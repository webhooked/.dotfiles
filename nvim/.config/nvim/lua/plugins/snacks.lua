return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    -- Snacks Picker
    {
      "<leader>sc",
      function()
        require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "Find Config File",
    },
    {
      "<leader>f",
      function()
        require("snacks").picker.buffers()
      end,
      desc = "Find Buffer",
    },
    {
      "<leader>sR",
      function()
        require("snacks").picker.resume()
      end,
      desc = "Resume Last Picker",
    },
  },
  opts = {
    -- Core features that LazyVim expects
    bigfile = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
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
        buffers = {
          win = {
            list = {
              keys = {
                ["d"] = {
                  function(picker, item)
                    local buf = item and item.buf
                    if buf and vim.api.nvim_buf_is_valid(buf) then
                      vim.api.nvim_buf_delete(buf, { force = false })
                      picker:refresh()
                    end
                  end,
                  desc = "Delete buffer",
                  mode = { "n" },
                },
                ["D"] = {
                  function(picker, item)
                    local buf = item and item.buf
                    if buf and vim.api.nvim_buf_is_valid(buf) then
                      vim.api.nvim_buf_delete(buf, { force = true })
                      picker:refresh()
                    end
                  end,
                  desc = "Force delete buffer",
                  mode = { "n" },
                },
              },
            },
          },
        },
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
