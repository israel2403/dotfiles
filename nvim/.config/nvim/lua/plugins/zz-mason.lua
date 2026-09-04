return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      -- LazyVim extras and local language specs can request the same tool.
      -- Remove duplicates so Mason does not start one package twice.
      local seen = {}
      opts.ensure_installed = vim.tbl_filter(function(tool)
        if seen[tool] then
          return false
        end
        seen[tool] = true
        return true
      end, opts.ensure_installed or {})
    end,
  },
}
