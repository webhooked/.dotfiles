return {
  "hrsh7th/nvim-cmp",
  dependencies = { "hrsh7th/cmp-emoji" },
  keys = {
    { "<tab>", false, mode = { "i", "s" } },
    { "<s-tab>", false, mode = { "i", "s" } },
  },
  opts = {
    sources = {
      { name = "emoji" },
      { name = "supermaven" },
    },
  },
}
