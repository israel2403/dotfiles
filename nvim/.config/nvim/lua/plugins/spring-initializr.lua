return {
  {
    "jkeresman01/spring-initializr.nvim",
    lazy = false,
    priority = 1000,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("spring-initializr").setup()
    end,
    keys = {
      { "<leader>si", "<cmd>SpringInitializr<cr>", desc = "Spring Initializr" },
    },
  },
}
