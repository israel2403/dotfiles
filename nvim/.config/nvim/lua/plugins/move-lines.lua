-- Keep line movement when LazyVim reapplies buffer-local LSP mappings.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "J", ":move .+1<CR>==", desc = "Move line down", silent = true },
            { "K", ":move .-2<CR>==", desc = "Move line up", silent = true },
            { "J", ":move '>+1<CR>gv=gv", mode = "x", desc = "Move selection down", silent = true },
            { "K", ":move '<-2<CR>gv=gv", mode = "x", desc = "Move selection up", silent = true },
          },
        },
      },
    },
  },
}
