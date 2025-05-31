return {
  "magicduck/grug-far.nvim",
  config = function()
    local grug = require("grug-far")
    
    -- Setup grug-far with options
    grug.setup({
      headermaxwidth = 80,
    -- Match Snacks picker behavior: include hidden and ignored files
    engines = {
      ripgrep = {
        extraArgs = "--hidden --no-ignore",
      },
    },
    -- Exclude same folders as Snacks picker
    excludePaths = {
      ".git",
      "node_modules",
      ".next",
      "target",
      ".idea",
    },
    -- Open in new tab for full-screen experience (closest to floating)
    windowCreationCommand = "tabnew",
    startInInsertMode = false,
    wrap = false,
    -- Custom keymaps for navigation
    keymaps = {
      replace = { n = "<localleader>r" },
      qflist = { n = "<localleader>q" },
      syncLocations = { n = "<localleader>s" },
      syncLine = { n = "<localleader>l" },
      close = { n = "<localleader>c" },
      historyOpen = { n = "<localleader>t" },
      historyAdd = { n = "<localleader>a" },
      refresh = { n = "<localleader>f" },
      openLocation = { n = "<localleader>o" },
      gotoLocation = { n = "<enter>" },
      pickHistoryEntry = { n = "<enter>" },
      abort = { n = "<localleader>b" },
      help = { n = "g?" },
      toggleShowCommand = { n = "<localleader>p" },
      swapEngine = { n = "<localleader>e" },
      -- Navigation with Ctrl-j/k
      nextHistoryItem = { n = "<C-j>" },
      prevHistoryItem = { n = "<C-k>" },
    },
    })
    
    -- Add Ctrl-j/k navigation for search results
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "grug-far",
      callback = function()
        -- Map Ctrl-j to act like down arrow
        vim.keymap.set({ "n", "i" }, "<C-j>", "<Down>", { buffer = true, remap = true, desc = "Move down" })
        
        -- Map Ctrl-k to act like up arrow
        vim.keymap.set({ "n", "i" }, "<C-k>", "<Up>", { buffer = true, remap = true, desc = "Move up" })
      end,
    })
  end,
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

    -- Quick search for word under cursor
    {
      "<leader>srw",
      function()
        local grug = require("grug-far")
        local word = vim.fn.expand("<cword>")
        grug.open({
          transient = true,
          prefills = {
            search = word,
          },
        })
      end,
      mode = "n",
      desc = "grug-far: word under cursor",
    },

    -- Search-only mode (no replace)
    {
      "<leader>sS",
      function()
        local grug = require("grug-far")
        grug.open({
          transient = true,
          disableBufferLineNumbers = true,
          prefills = {
            flags = "--no-heading",
          },
          -- Start with cursor in search field
          startCursorRow = 1,
        })
      end,
      mode = { "n", "v" },
      desc = "grug-far: search only",
    },

    -- Search from Snacks picker results
    {
      "<leader>srg",
      function()
        require("snacks").picker.grep({
          actions = {
            ["<C-r>"] = {
              function(picker, items)
                local grug = require("grug-far")
                picker:close()
                grug.open({
                  transient = true,
                  prefills = {
                    search = picker.state.search or "",
                  },
                })
              end,
              desc = "Open in grug-far",
              mode = { "n", "i" },
            },
          },
        })
      end,
      desc = "Grep → grug-far",
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
