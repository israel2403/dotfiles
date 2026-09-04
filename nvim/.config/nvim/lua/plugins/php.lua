return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "php",
        "php_only",
        "html",
        "css",
        "javascript",
        "typescript",
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          settings = {
            intelephense = {
              diagnostics = { enable = true },
              completion = { fullyQualifyGlobalConstantsAndFunctions = true },
              format = { enable = false },
            },
          },
        },
        html = {},
        cssls = {},
        ts_ls = {},
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "intelephense",
        "html-lsp",
        "css-lsp",
        "typescript-language-server",
        "php-cs-fixer",
        "phpactor",
        "prettier",
      },
    },
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        php = { "php_cs_fixer" },
        css = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
      },
    },
  },

  {
    "gbprod/phpactor.nvim",
    ft = "php",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      install = {
        -- phpactor.nvim invokes this path as `php <bin>`, so use Mason's
        -- actual PHAR rather than its Bash wrapper in mason/bin.
        bin = vim.fn.stdpath("data") .. "/mason/packages/phpactor/phpactor.phar",
        -- iconv is installed but disabled in the system php.ini. Enable it
        -- only for Phpactor instead of changing the global PHP configuration.
        php_bin = "php -d extension=iconv",
      },
      lspconfig = {
        enabled = false,
      },
    },
    config = function(_, opts)
      require("phpactor").setup(opts)

      local rpc = require("phpactor.rpc")
      local utils = require("phpactor.utils")
      local original_input_callback = rpc.handle_input_callback

      rpc.handle_input_callback = function(parameters)
        local input = parameters.inputs[#parameters.inputs]
        if not input or input.type ~= "list" or not input.parameters.multi then
          return original_input_callback(parameters)
        end

        local fields = vim.tbl_values(input.parameters.choices)
        table.sort(fields)

        local choices = { "* All fields" }
        vim.list_extend(choices, fields)

        vim.ui.select(choices, { prompt = input.parameters.label }, function(choice)
          if not choice then
            vim.g.phpactor_generate_getters_and_setters = false
            return
          end

          local selected = choice == "* All fields" and fields or { choice }
          parameters.callback.parameters[input.name] = selected
          rpc.call(parameters.callback.action, parameters.callback.parameters)

          if vim.g.phpactor_generate_getters_and_setters then
            vim.g.phpactor_generate_getters_and_setters = false
            rpc.call("generate_mutator", {
              names = selected,
              offset = utils.offset(),
              source = utils.source(),
              path = utils.path(),
            })
          end
        end)
      end
    end,
    keys = {
      {
        "<leader>cg",
        function()
          vim.g.phpactor_generate_getters_and_setters = true
          require("phpactor").rpc("generate_accessor")
        end,
        ft = "php",
        desc = "Generate PHP Getters and Setters",
      },
    },
  },
}
