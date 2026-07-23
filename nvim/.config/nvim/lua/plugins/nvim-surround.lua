return {
  -- Disable mini.surround (ships with LazyVim) to avoid conflicts
  { "nvim-mini/mini.surround", enabled = false },

  -- nvim-surround: classic ys/ds/cs keybindings
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<leader>w", "<Plug>(nvim-surround-visual)", mode = "x", desc = "Wrap selection" },
    },
  },
}
