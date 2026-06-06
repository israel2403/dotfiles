return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>na", group = "Angular" },

        {
          "<leader>nac",
          function()
            vim.ui.input({ prompt = "Component name: " }, function(name)
              if name and name ~= "" then
                vim.cmd("terminal ng generate component " .. name)
              end
            end)
          end,
          desc = "Angular generate component",
        },

        {
          "<leader>nas",
          function()
            vim.ui.input({ prompt = "Service name: " }, function(name)
              if name and name ~= "" then
                vim.cmd("terminal ng generate service " .. name)
              end
            end)
          end,
          desc = "Angular generate service",
        },

        {
          "<leader>nam",
          function()
            vim.ui.input({ prompt = "Module name: " }, function(name)
              if name and name ~= "" then
                vim.cmd("terminal ng generate module " .. name)
              end
            end)
          end,
          desc = "Angular generate module",
        },
      },
    },
  },
}
