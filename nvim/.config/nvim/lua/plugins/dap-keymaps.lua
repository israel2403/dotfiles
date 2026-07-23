-- dap-keymaps.lua
-- Keyboard-friendly debug keymaps that work on a Glove80 (no F11/F12) and
-- avoid F10, which some terminal emulators (and some window managers)
-- intercept before nvim sees the key.
--
-- IntelliJ-style F-keys -- the layout most Java developers already have
-- in muscle memory, and which fits entirely inside the Glove80's F5..F10:
--
--     F5         Start / Continue (Java main-aware)
--     F6         Toggle debugger UI
--     F7         Step Into
--     F8         Step Over
--     F9         Step Out
--     F10        Toggle Breakpoint
--
-- The Glove80 has only F5..F10 (no F11/F12), so this set deliberately
-- avoids those higher F-keys and is fully sequential to minimise hand
-- movement during a debug session.
--
-- Letter aliases (work on any keyboard, including Glove80 layers without
-- F-keys): use the existing <leader>d... namespace.
--
--     <leader>dn   step Next (== over)
--     <leader>di   step Into            -- LazyVim default
--     <leader>dO   step Out (cap O)     -- LazyVim default
--     <leader>db   toggle breakpoint    -- LazyVim default
--     <leader>dc   continue             -- LazyVim default
--     <leader>du   toggle DAP UI        -- LazyVim default
--
-- These are global (not Java-specific) because nvim-dap drives every
-- language. If you ever change debug adapters, the same mappings apply.

local function java_continue()
  local dap = require("dap")
  if dap.session() then
    dap.continue()
    return
  end

  local ok, jdtls_dap = pcall(require, "jdtls.dap")
  if not ok then
    vim.notify("Java debugger is not ready; wait for jdtls to attach", vim.log.levels.WARN)
    return
  end

  vim.notify("Scanning for Java main classes...", vim.log.levels.INFO)
  jdtls_dap.setup_dap_main_class_configs({
    on_ready = vim.schedule_wrap(function()
      local configurations = (dap.configurations or {}).java or {}
      local launches = vim.tbl_filter(function(config)
        return config.request == "launch"
      end, configurations)

      if #launches == 0 then
        vim.notify("No Java main(String[]) found in this project", vim.log.levels.WARN)
      elseif #launches == 1 then
        vim.notify("Launching: " .. (launches[1].name or launches[1].mainClass or "<unnamed>"), vim.log.levels.INFO)
        dap.run(launches[1])
      else
        vim.ui.select(launches, {
          prompt = "Select Java main to debug:",
          format_item = function(config)
            return config.name or config.mainClass or "<unnamed>"
          end,
        }, function(config)
          if config then
            dap.run(config)
          end
        end)
      end
    end),
  })
end

local function continue()
  if vim.bo.filetype == "java" then
    java_continue()
  else
    require("dap").continue()
  end
end

return {
  {
    "mfussenegger/nvim-dap",
    optional = true,
    keys = {
      -- IntelliJ-style F-keys, all inside F5..F10 (Glove80-safe).
      {
        "<F5>",
        continue,
        desc = "Debug: Start / Continue",
      },
      {
        "<F6>",
        function() require("dapui").toggle({ reset = true }) end,
        desc = "Debug: Toggle UI",
      },
      {
        "<F7>",
        function() require("dap").step_into() end,
        desc = "Debug: Step Into",
      },
      {
        "<F8>",
        function() require("dap").step_over() end,
        desc = "Debug: Step Over",
      },
      {
        "<F9>",
        function() require("dap").step_out() end,
        desc = "Debug: Step Out",
      },
      {
        "<F10>",
        function() require("dap").toggle_breakpoint() end,
        desc = "Debug: Toggle Breakpoint",
      },

      -- Letter alias: step next-line, no F-key required.
      {
        "<leader>dn",
        function() require("dap").step_over() end,
        desc = "Step Next (over)",
      },
    },
  },
}
