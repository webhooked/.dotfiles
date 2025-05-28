-- This file is automatically loaded by lazyvim.config.init
local Util = require("lazyvim.util")
local Snacks = require("snacks")
local harpoon = require("harpoon")

harpoon:setup()

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  ---
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    if opts.remap then
      opts.remap = nil
    end
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- basic telescope configuration
local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
  local file_paths = {}
  for _, item in ipairs(harpoon_files.items) do
    table.insert(file_paths, item.value)
  end

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Harpoon",
      finder = require("telescope.finders").new_table({
        results = file_paths,
      }),
      previewer = conf.file_previewer({}),
      sorter = conf.generic_sorter({}),
    })
    :find()
end

-- change word on enter
map("n", "<cr>", "ciw")

-- better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

map("n", "<C-j>", "<C-d>", { silent = true })
map("n", "<C-k>", "<C-u>", { silent = true })
map("v", "<C-j>", "<C-d>", { silent = true })
map("v", "<C-k>", "<C-u>", { silent = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move Lines
map("n", "<leader>mj", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<leader>mk", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("v", "<leader>mj", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<leader>mk", ":m '<-2<cr>gv=gv", { desc = "Move up" })
map("i", "jj", "<esc>", { desc = "Move up" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / clear hlsearch / diff update" }
)

map({ "n", "x" }, "gw", "*N", { desc = "Search word under cursor" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

-- save file
map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
map("n", "<leader>ww", "<cmd>w<cr><esc>", { desc = "Save file" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- lazy
map("n", "<leader>.", "<cmd>:Lazy<cr>", { desc = "Lazy" })

-- new file
map("n", "<leader>bn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

map("n", "<leader>rn", ":IncRename ")

-- zen mode
map("n", "<leader>Z", "<cmd>ZenMode<cr>", { desc = "Zen Mode" })
map("n", "<leader>z", "<cmd>NoNeckPain<cr>", { desc = "No Neck Pain" })

-- toggle options
map("n", "<leader>uf", require("lazyvim.util").format.toggle, { desc = "Toggle format on Save" })

-- buffers
if Util.has("bufferline.nvim") then
  map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
  map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  map("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Prev tab" })
  map("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next tab" })
  map("n", "<C-h>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "Prev tab" })
  map("n", "<C-l>", "<Cmd>BufferLineCycleNext<CR>", { desc = "Next tab" })
else
  map("n", "<leader>n", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
  map("n", "<leader>m", "<cmd>bnext<cr>", { desc = "Next buffer" })
end

map("n", "<leader>us", function()
  Snacks.toggle("spell")
end, { desc = "Toggle Spelling" })
map("n", "<leader>uw", function()
  Snacks.toggle("wrap")
end, { desc = "Toggle Word Wrap" })
map("n", "<leader>ul", function()
  Snacks.toggle("relativenumber", true)
  Snacks.toggle("number")
end, { desc = "Toggle Line Numbers" })
map("n", "<leader>ud", function()
  Snacks.toggle("diagnostics")
end, { desc = "Toggle Diagnostics" })
local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
map("n", "<leader>uc", function()
  Snacks.toggle("conceallevel", false, { 0, conceallevel })
end, { desc = "Toggle Conceal" })

-- lazygit
map("n", "<leader>gg", function()
  Snacks.terminal.open({ "lazygit" }, { cwd = Util.root(), esc_esc = false })
end, { desc = "Lazygit (root dir)" })
map("n", "<leader>gG", function()
  Snacks.terminal.open({ "lazygit" }, { esc_esc = false })
end, { desc = "Lazygit (cwd)" })

map("n", "<leader>a", function()
  harpoon:list():add()
end, { desc = "Add to Harpoon" })
map("n", "<leader>d", function()
  harpoon:list():remove()
end, { desc = "Remove from Harpoon" })

-- Harpoon quick select
map("n", "<leader>1", function()
  harpoon:list():select(1)
end, { desc = "Harpoon Select 1" })
map("n", "<leader>2", function()
  harpoon:list():select(2)
end, { desc = "Harpoon Select 2" })
map("n", "<leader>3", function()
  harpoon:list():select(3)
end, { desc = "Harpoon Select 3" })
map("n", "<leader>4", function()
  harpoon:list():select(4)
end, { desc = "Harpoon Select 4" })

-- Harpoon navigation
map("n", "<C-q>", function()
  harpoon:list():prev()
end, { desc = "Harpoon Prev Buffer" })
map("n", "<C-e>", function()
  harpoon:list():next()
end, { desc = "Harpoon Next Buffer" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- highlights under cursor
if vim.fn.has("nvim-0.9.0") == 1 then
  map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
end

-- windows
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window", remap = true })
map("n", "<leader>w-", "<C-W>s", { desc = "Split window below", remap = true })
map("n", "<leader>w|", "<C-W>v", { desc = "Split window right", remap = true })
map("n", "<leader>-", "<C-W>s", { desc = "Split window below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split window right", remap = true })

-- Global substitute (quick raw :%s)
map("n", "<leader>sW", [[:%s/\<<C-r><C-w>\>//g<Left><Left>]], { desc = "Sub word under cursor" })

map("n", "<leader>fh", "<cmd>DiffviewFileHistory %<CR>", { desc = "File history" })
map("n", "<leader>fb", ":Telescope file_browser<CR>", { noremap = true })
map("n", "<leader>h", function()
  toggle_telescope(harpoon:list())
end, { desc = "Open harpoon window" })
