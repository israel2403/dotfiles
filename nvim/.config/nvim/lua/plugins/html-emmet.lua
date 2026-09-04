return {
  -- Ensure Mason installs html-lsp and emmet-language-server
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "html-lsp",
        "css-lsp",
        "typescript-language-server",
        "emmet-language-server",
      },
    },
  },

  -- Configure both LSP servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {
          filetypes = { "html", "jsp" },
        },
        cssls = {},
        ts_ls = {},
        emmet_language_server = {
          filetypes = {
            "html",
            "jsp",
            "css",
            "scss",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "vue",
            "svelte",
          },
        },
      },
    },
  },

  -- Ensure treesitter has html parser
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "html",
        "css",
        "javascript",
      },
    },
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.jsp_attributes = {
        name = "JSP attributes",
        module = "jsp-attributes",
        score_offset = 20,
      }

      opts.sources.per_filetype = opts.sources.per_filetype or {}
      opts.sources.per_filetype.jsp = { inherit_defaults = true, "jsp_attributes" }
    end,
  },
}
