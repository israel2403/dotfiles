return {
  -- Ensure Mason installs html-lsp and emmet-language-server
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "html-lsp",
        "emmet-language-server",
      },
    },
  },

  -- Configure both LSP servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {},
        emmet_language_server = {
          filetypes = {
            "html",
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
      },
    },
  },
}
