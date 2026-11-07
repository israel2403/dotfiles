return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = {
          keys = {
            {
              "<leader>cr",
              function()
                vim.lsp.buf.rename(nil, { name = "jdtls" })
              end,
              expr = false,
              desc = "Rename Java symbol",
              has = "rename",
            },
          },
        },
      },
    },
  },
}
