return {
  "shortcuts/no-neck-pain.nvim",
  version = "*",
  opts = {
    width = 120,
    buffers = {
      left = {
        setNames = false,
      },
      right = {
        enabled = false,
        setNames = false,
      },
      scratchPad = {
        enabled = true,
        -- -- set to `nil` to default
        -- -- to current working directory
        -- location = nil, -- "~/Documents/",
        pathToFile = ".scratchpad",
      },
      bo = {
        filetype = "md",
      },
    },
  },
}
