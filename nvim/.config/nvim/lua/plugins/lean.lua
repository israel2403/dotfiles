-- Lean 4 proof development.
--
-- `lean.nvim` provides the Lean-specific LSP/proof-goal UI. Elan owns the
-- actual Lean toolchain, so projects can pin Lean/mathlib through lake.

return {
  {
    "Julian/lean.nvim",
    event = { "BufReadPre *.lean", "BufNewFile *.lean" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "andymass/vim-matchup",
    },
    init = function()
      vim.g.lean_config = {
        lsp = {
          on_attach = function(_, bufnr)
            local map = function(lhs, rhs, desc)
              vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
            end

            map("<leader>lg", "<cmd>LeanGoal<cr>", "Lean Goal")
            map("<leader>li", "<cmd>LeanInfoviewToggle<cr>", "Lean Infoview")
            map("<leader>lt", "<cmd>LeanTermGoal<cr>", "Lean Term Goal")
            map("<leader>ld", vim.lsp.buf.definition, "Lean Definition")
            map("<leader>lh", vim.lsp.buf.hover, "Lean Hover")
            map("<leader>la", vim.lsp.buf.code_action, "Lean Code Action")
          end,
        },
        mappings = true,
      }
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "lean", "markdown", "markdown_inline" })
    end,
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>l", group = "lean" },
      },
    },
  },
}
