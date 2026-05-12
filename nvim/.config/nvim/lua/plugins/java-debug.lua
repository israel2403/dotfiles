-- java-debug.lua
-- Java debugging is enabled by:
--   1. lazyvim.plugins.extras.dap.core   -> nvim-dap, nvim-dap-ui,
--                                            nvim-dap-virtual-text,
--                                            mason-nvim-dap
--   2. lazyvim.plugins.extras.lang.java  -> nvim-jdtls + auto-wires the DAP
--                                            bundles (java-debug-adapter,
--                                            java-test) into jdtls when
--                                            dap.core is also enabled.
-- Both extras are already on in lazyvim.json. This file layers small
-- improvements on top:
--
--   * Mason ensure_installed for java-debug-adapter + java-test (the lang.java
--     extra already does this, but stating it explicitly here makes the
--     dependency obvious and self-healing if you ever disable that line in
--     LazyVim).
--   * jdtls.dap options: hotcodereplace = "auto" so Spring Boot dev-tools-
--     style hot reload Just Works during a debug session.
--   * which-key group labels for the Java debug keymaps so <leader>d / <leader>t
--     show readable names instead of bare codes.
--
-- Common Java debug keymaps (provided by dap.core + lang.java extras):
--   <F5>          Continue (start / resume)
--   <F10>         Step over
--   <F11>         Step into
--   <S-F11>       Step out
--   <leader>db    Toggle breakpoint
--   <leader>dB    Conditional breakpoint
--   <leader>dc    Continue
--   <leader>dC    Run to cursor
--   <leader>dt    Terminate
--   <leader>du    Toggle DAP UI
--   <leader>de    Eval expression (REPL)
--   <leader>tt    Run Test Class            (jdtls)
--   <leader>tr    Run Nearest Test (Method) (jdtls)
--   <leader>tT    Pick Test                 (jdtls)

return {
  -- Mason: make the Java debug bundles part of ensure_installed so a fresh
  -- box gets them on first nvim launch.
  {
    "mason-org/mason.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "java-debug-adapter",
        "java-test",
      })
    end,
  },

  -- jdtls: extend the dap options layered on top of LazyVim's defaults.
  -- LazyVim already sets dap = { hotcodereplace = "auto" }; we keep that
  -- and also enable dap_main so jdtls auto-discovers main classes (handy
  -- for the `mvn_new` projects which have a single App.java).
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    opts = {
      dap = { hotcodereplace = "auto", config_overrides = {} },
      dap_main = {},
      test = true,
    },
  },

  -- which-key: make the Java debug section discoverable.
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>d", group = "Debug", icon = "" },
        { "<leader>t", group = "Test",  icon = "ó±¨" },
      },
    },
  },

  -- <leader>dJ -- "Debug Java Main" with no race.
  --
  -- Background: <F5> / <leader>dc invoke dap.continue(), which reads
  -- dap.configurations.java. That table is populated ASYNCHRONOUSLY by
  -- jdtls.dap.setup_dap_main_class_configs() after jdtls finishes indexing
  -- the project. On a fresh project (or right after :LspRestart), pressing
  -- F5 too early lands on an empty configurations table -- continue exits
  -- silently and looks broken.
  --
  -- This mapping forces a synchronous-feeling debug start: it (re-)runs the
  -- main-class scan and only calls dap.continue() once jdtls has finished
  -- populating dap.configurations.java. If nothing turns up after the scan,
  -- it tells you so explicitly instead of failing silently.
  --
  -- Buffer-local to filetype=java so it doesn't pollute other languages'
  -- <leader>dJ.
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserJavaDebugMain", { clear = true }),
        pattern = "java",
        callback = function(ev)
          vim.keymap.set("n", "<leader>dJ", function()
            local ok, jdtls_dap = pcall(require, "jdtls.dap")
            if not ok then
              vim.notify("jdtls.dap not loaded -- has jdtls attached yet?", vim.log.levels.WARN)
              return
            end
            vim.notify("Scanning for Java main classes...", vim.log.levels.INFO)
            jdtls_dap.setup_dap_main_class_configs({
              on_ready = vim.schedule_wrap(function()
                local configs = (require("dap").configurations or {}).java or {}
                if #configs == 0 then
                  vim.notify(
                    "No Java main classes found. Wait for jdtls to finish indexing (status line) and try again,\nor open a buffer inside a Maven/Gradle project root.",
                    vim.log.levels.WARN
                  )
                  return
                end
                vim.notify(
                  string.format("Found %d Java main config(s); launching dap.continue()", #configs),
                  vim.log.levels.INFO
                )
                require("dap").continue()
              end),
            })
          end, { buffer = ev.buf, silent = true, desc = "Debug Java Main" })
        end,
      })
    end,
  },
}
