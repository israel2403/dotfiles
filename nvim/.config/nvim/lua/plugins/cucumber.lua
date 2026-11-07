-- Gherkin editing with Java step discovery, using LazyVim's completion/LSP UI.
return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.filetype.add({ extension = { feature = "cucumber" } })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "cucumber",
        callback = function()
          vim.bo.expandtab = true
          vim.bo.shiftwidth = 2
          vim.bo.softtabstop = 2
          vim.bo.commentstring = "# %s"
        end,
      })
    end,
    opts = {
      servers = {
        cucumber_language_server = {
          mason = false,
          cmd = function(dispatchers, config)
            return vim.lsp.rpc.start(
              { vim.fn.expand("~/.local/bin/cucumber-language-server"), "--stdio" },
              dispatchers,
              { cwd = config.root_dir }
            )
          end,
          filetypes = { "cucumber" },
          -- Prefer the service root over the enclosing monorepo.
          root_dir = function(bufnr, on_dir)
            local root = vim.fs.root(bufnr, { "pom.xml", "build.gradle", "build.gradle.kts" })
              or vim.fs.root(bufnr, { ".git" })
            if root then
              on_dir(root)
            end
          end,
          settings = {
            cucumber = {
              parameterTypes = {},
              snippetTemplates = {},
              features = { "src/test/resources/**/*.feature", "features/**/*.feature" },
              glue = { "src/test/java/**/*.java", "src/test/kotlin/**/*.kt" },
            },
          },
        },
      },
    },
  },
  {
    "L3MON4D3/LuaSnip",
    opts = function()
      local ls = require("luasnip")
      local s, t, i = ls.snippet, ls.text_node, ls.insert_node
      ls.add_snippets("cucumber", {
        s("feature", { t("Feature: "), i(1, "description"), t({ "", "", "  Scenario: " }),
          i(2, "behavior"), t({ "", "    Given " }), i(3, "a precondition"),
          t({ "", "    When " }), i(4, "an action"), t({ "", "    Then " }), i(5, "an outcome") }),
        s("scenario", { t("Scenario: "), i(1, "behavior"), t({ "", "  Given " }),
          i(2, "a precondition"), t({ "", "  When " }), i(3, "an action"),
          t({ "", "  Then " }), i(4, "an outcome") }),
        s("outline", { t("Scenario Outline: "), i(1, "behavior"),
          t({ "", "  Given " }), i(2, "a <value>"), t({ "", "  When " }), i(3, "an action"),
          t({ "", "  Then " }), i(4, "an outcome"),
          t({ "", "", "  Examples:", "    | value |", "    | " }), i(5, "example"), t(" |") }),
        s("background", { t({ "Background:", "  Given " }), i(1, "a shared precondition") }),
      }, { key = "cucumber-java" })
    end,
  },
}
