return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        html = { "prettier_html" },
      },
      formatters = {
        prettier_html = {
          inherit = "prettier",
          prepend_args = {
            "--single-attribute-per-line",
            "--html-whitespace-sensitivity",
            "ignore",
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "prettier",
      },
    },
  },
}
