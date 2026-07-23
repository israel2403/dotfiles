return {
  {
    "neovim/nvim-lspconfig",
    event = "LazyFile",
    init = function()
      local function enable_inlay_hints(bufnr)
        if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserInlayHints", { clear = true }),
        callback = function(event)
          enable_inlay_hints(event.buf)
        end,
      })

      vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("UserInlayHintsRefresh", { clear = true }),
        callback = function(event)
          if #vim.lsp.get_clients({ bufnr = event.buf }) > 0 then
            enable_inlay_hints(event.buf)
          end
        end,
      })
    end,
  },
}
