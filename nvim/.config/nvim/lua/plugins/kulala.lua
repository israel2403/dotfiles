-- lua/plugins/kulala.lua
return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    opts = {},
    keys = {
      { "<leader>Rs", function() require("kulala").run() end, desc = "Run HTTP request" },
      { "<leader>Ra", function() require("kulala").run_all() end, desc = "Run all HTTP requests" },
      { "<leader>Rb", function() require("kulala").scratchpad() end, desc = "HTTP scratchpad" },
    },
  },
}
