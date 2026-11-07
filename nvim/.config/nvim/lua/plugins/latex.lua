return {
  {
    "lervag/vimtex",
    init = function()
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        options = {
          "-pdf",
          "-verbose",
          "-file-line-error",
          "-synctex=1",
          "-interaction=nonstopmode",
        },
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          mason = false,
          settings = {
            texlab = {
              -- VimTeX owns continuous builds; avoid a second compiler on save.
              build = { onSave = false },
              chktex = { onEdit = true, onOpenAndSave = true },
            },
          },
        },
      },
    },
  },
}
