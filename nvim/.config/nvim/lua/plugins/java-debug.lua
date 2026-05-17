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

  -- <leader>dJ -- "Debug Java Main" with no race and no attach fall-through.
  -- <leader>dA -- "Debug Java Attach" (127.0.0.1:5005, opt-in).
  --
  -- Background
  -- ----------
  -- <F5> / <leader>dc invoke dap.continue(), which reads
  -- dap.configurations.java. LazyVim's lang.java extra pre-seeds that table
  -- with a SINGLE default config -- 'Debug (Attach) - Remote' to
  -- 127.0.0.1:5005. Later, jdtls.dap.setup_dap_main_class_configs()
  -- asynchronously appends 'launch' entries for every main(...) it finds.
  --
  -- Two problems for the casual case:
  --   1. Race: pressing <F5> before the async scan finishes runs the only
  --      available config (the attach one) and fails with
  --          "Failed to attach to 127.0.0.1:5005"
  --      because nothing is listening on 5005.
  --   2. Even after the scan, if the buffer's project has NO main(String[])
  --      anywhere (e.g. utility classes, code-challenges repos), the attach
  --      config is still selected silently -- same error.
  --
  -- <leader>dJ fixes both: it forces the main-class scan, waits for its
  -- on_ready callback, then only considers configs with request=="launch"
  -- (real main classes). 1 launch -> run it; >1 -> vim.ui.select picker; 0
  -- -> a clear notification suggesting alternatives.
  --
  -- <leader>dA explicitly launches the attach-to-127.0.0.1:5005 config when
  -- you really do have a JVM running with -agentlib:jdwp=...,address=5005.
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    init = function()
      local function only_launches()
        local configs = (require("dap").configurations or {}).java or {}
        return vim.tbl_filter(function(c)
          return c.request == "launch"
        end, configs)
      end

      local function debug_java_main()
        local ok, jdtls_dap = pcall(require, "jdtls.dap")
        if not ok then
          vim.notify("jdtls.dap not loaded -- has jdtls attached yet?", vim.log.levels.WARN)
          return
        end
        vim.notify("Scanning for Java main classes...", vim.log.levels.INFO)
        jdtls_dap.setup_dap_main_class_configs({
          on_ready = vim.schedule_wrap(function()
            local launches = only_launches()
            if #launches == 0 then
              vim.notify(
                "No Java main(String[]) found in this project.\n"
                  .. "  * If this file has @Test methods, try <leader>tt or <leader>tr.\n"
                  .. "  * If you want to attach to a running JVM on 127.0.0.1:5005, use <leader>dA.\n"
                  .. "  * Otherwise add a main(String[] args) method or open a class with one.",
                vim.log.levels.WARN
              )
              return
            end
            if #launches == 1 then
              vim.notify(
                string.format("Launching: %s", launches[1].name or "<unnamed>"),
                vim.log.levels.INFO
              )
              require("dap").run(launches[1])
              return
            end
            vim.ui.select(launches, {
              prompt = "Select Java main to debug:",
              format_item = function(c)
                return c.name or c.mainClass or "<unnamed>"
              end,
            }, function(choice)
              if choice then
                require("dap").run(choice)
              end
            end)
          end),
        })
      end

      local function debug_java_attach()
        require("dap").run({
          type = "java",
          request = "attach",
          name = "Debug (Attach) - Remote",
          hostName = "127.0.0.1",
          port = 5005,
        })
      end

      -- Strip the attach-to-5005 default that LazyVim's lang.java extra
      -- hardcodes into dap.configurations.java. Any code path that ends up
      -- in select_config_and_run() (e.g. <leader>dc or <F5> with no active
      -- session) would otherwise silently pick it and timeout against the
      -- non-existent JVM. <leader>dA below remains the explicit way to use
      -- the attach config when you actually have a remote JVM listening.
      local function strip_attach_defaults()
        local ok, dap = pcall(require, "dap")
        if not ok then return end
        dap.configurations = dap.configurations or {}
        if type(dap.configurations.java) == "table" then
          dap.configurations.java = vim.tbl_filter(function(c)
            return c.request ~= "attach"
          end, dap.configurations.java)
        end
      end

      -- Run the strip once nvim has settled (after LazyVim's lang.java
      -- extra has populated the configurations).
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = strip_attach_defaults,
      })
      -- Also re-strip whenever jdtls finishes its async scan, in case any
      -- attach entry creeps back in via tooling we don't control.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.name == "jdtls" then
            vim.defer_fn(strip_attach_defaults, 500)
          end
        end,
      })

      -- Smart <leader>dc / <F5> for Java buffers:
      --   * If a session is alive       -> defer to vanilla dap.continue()
      --                                     (resume / next-breakpoint / etc).
      --   * If no session               -> race-free launch (same path as
      --                                     <leader>dJ). No attach fall-through.
      local function debug_java_continue()
        local ok, dap = pcall(require, "dap")
        if not ok then return end
        if dap.session() then
          dap.continue()
          return
        end
        debug_java_main()
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserJavaDebugMain", { clear = true }),
        pattern = "java",
        callback = function(ev)
          vim.keymap.set("n", "<leader>dJ", debug_java_main, {
            buffer = ev.buf,
            silent = true,
            desc = "Debug Java Main (launch only)",
          })
          vim.keymap.set("n", "<leader>dA", debug_java_attach, {
            buffer = ev.buf,
            silent = true,
            desc = "Debug Java Attach (127.0.0.1:5005)",
          })
          vim.keymap.set("n", "<leader>dc", debug_java_continue, {
            buffer = ev.buf,
            silent = true,
            desc = "Debug Continue (Java-aware)",
          })
          vim.keymap.set("n", "<F5>", debug_java_continue, {
            buffer = ev.buf,
            silent = true,
            desc = "Debug Continue (Java-aware)",
          })
        end,
      })
    end,
  },
}
