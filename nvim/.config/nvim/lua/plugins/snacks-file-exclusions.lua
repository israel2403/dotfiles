return {
  "folke/snacks.nvim",
  opts = function(_, opts)
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    opts.picker.sources.files = opts.picker.sources.files or {}
    local files = opts.picker.sources.files
    files.exclude = files.exclude or {}
    -- Hide Maven build output and compiled Java classes, including nested modules.
    vim.list_extend(files.exclude, { "**/target/**", "*.class" })
  end,
}
