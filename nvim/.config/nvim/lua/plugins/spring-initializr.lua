return {
  {
    "jkeresman01/spring-initializr.nvim",
    lazy = false,
    priority = 1000,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("spring-initializr").setup()
      vim.keymap.set("n", "<leader>si", "<cmd>SpringInitializr<cr>", { desc = "Spring Initializr" })
    end,
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>si", false },
    },
  },
}
