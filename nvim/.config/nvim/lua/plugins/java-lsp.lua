return {
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    opts = function(_, opts)
      local data = vim.fn.stdpath("data")
      -- Pin the tested stable server separately from Mason's rolling installation.
      opts.cmd = {
        data .. "/jdtls-versions/1.61.0/bin/jdtls",
        "--java-executable", data .. "/jdtls-versions/java25/bin/java",
        "--jvm-arg=-javaagent:" .. data .. "/mason/share/jdtls/lombok.jar",
      }
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          completion = {
            postfix = { enabled = true },
            -- Eager expansion hangs in the parser on `setOrigin(input.)` in a lambda.
            lazyResolveTextEdit = { enabled = true },
          },
        },
      })
      -- Keep the newer server's state separate from the previous Mason server.
      opts.jdtls_config_dir = function(project_name)
        return vim.fn.stdpath("cache") .. "/jdtls-1.61.0/" .. project_name .. "/config"
      end
      opts.jdtls_workspace_dir = function(project_name)
        return vim.fn.stdpath("cache") .. "/jdtls-1.61.0/" .. project_name .. "/workspace"
      end
    end,
  },
}
