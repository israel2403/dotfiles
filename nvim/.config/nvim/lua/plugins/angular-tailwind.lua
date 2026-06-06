return {
  { import = "lazyvim.plugins.extras.lang.tailwind" },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tailwindcss = {
          filetypes = {
            "html",
            "htmlangular",
            "typescript",
            "typescriptreact",
            "javascript",
            "javascriptreact",
            "css",
            "scss",
          },
        },
      },
    },
  },
}
