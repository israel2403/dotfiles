local function java_range_params(bufnr, client)
  local offset_encoding = client.offset_encoding or "utf-16"
  local params = vim.lsp.util.make_range_params(0, offset_encoding)
  params.context = { diagnostics = {} }
  params.textDocument.uri = vim.uri_from_bufnr(bufnr)
  return params
end

local function implement_methods(bufnr, client)
  local ok, jdtls = pcall(require, "jdtls")
  if not ok then
    vim.notify("nvim-jdtls is not loaded", vim.log.levels.WARN)
    return
  end

  local command = jdtls.commands and jdtls.commands["java.action.overrideMethodsPrompt"]
  if type(command) ~= "function" then
    vim.notify("JDTLS override-method action is not available", vim.log.levels.WARN)
    return
  end

  command(nil, {
    bufnr = bufnr,
    params = java_range_params(bufnr, client),
  })
end

local function is_create_method_action(action)
  local title = (action.title or ""):lower()
  return title:find("create method", 1, true) ~= nil
    or title:find("create local function", 1, true) ~= nil
    or title:find("add method", 1, true) ~= nil
end

local function create_missing_method(bufnr)
  vim.lsp.buf.code_action({
    bufnr = bufnr,
    context = {
      only = { "quickfix" },
    },
    filter = is_create_method_action,
    apply = true,
  })
end

return {
  {
    "mfussenegger/nvim-jdtls",
    optional = true,
    init = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("java_implement_methods_keymap", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "jdtls" then
            return
          end

          vim.keymap.set("n", "<leader>Ji", function()
            implement_methods(args.buf, client)
          end, {
            buffer = args.buf,
            desc = "Implement methods",
          })

          vim.keymap.set("n", "<leader>Jm", function()
            create_missing_method(args.buf)
          end, {
            buffer = args.buf,
            desc = "Create missing method",
          })
        end,
      })
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>Ji", desc = "Implement methods" },
        { "<leader>Jm", desc = "Create missing method" },
      },
    },
  },
}
