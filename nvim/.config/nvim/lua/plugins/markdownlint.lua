-- markdownlint-cli2 only searches for config files from the file's directory
-- up to Neovim's cwd, so a config in $HOME is never found. Point it at a global
-- file explicitly instead.
local config = vim.fn.stdpath("config") .. "/markdownlint.yaml"

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "--config", config, "-" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          args = { "--config", config, "--fix", "$FILENAME" },
        },
      },
    },
  },
  {
    -- LazyVim's markdown extra also registers markdownlint-cli2 through none-ls,
    -- which doubles every diagnostic when the none-ls extra is enabled.
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sources = vim.tbl_filter(function(source)
        return source.name ~= "markdownlint-cli2"
      end, opts.sources or {})
    end,
  },
}
