local function java_range_params(bufnr, client)
  local offset_encoding = client.offset_encoding or "utf-16"
  local params = vim.lsp.util.make_range_params(0, offset_encoding)
  params.context = { diagnostics = {} }
  params.textDocument.uri = vim.uri_from_bufnr(bufnr)
  return params
end

local function diagnostics_at_cursor(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local diagnostics = {}

  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, { lnum = line })) do
    local lsp_diagnostic = diagnostic.user_data and diagnostic.user_data.lsp
    if lsp_diagnostic then
      table.insert(diagnostics, lsp_diagnostic)
    end
  end

  return diagnostics
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

local function command_from_action(action)
  if type(action.command) == "table" then
    return action.command
  elseif type(action.command) == "string" then
    return action
  end
end

local function workspace_edits(action)
  local edits = {}
  if action.edit then
    table.insert(edits, action.edit)
  end

  local command = command_from_action(action)
  if command and command.command == "java.apply.workspaceEdit" then
    for _, argument in ipairs(command.arguments or {}) do
      if type(argument) == "table" and (argument.changes or argument.documentChanges) then
        table.insert(edits, argument)
      end
    end
  end
  return edits
end

local function each_text_edit(workspace_edit, callback)
  for uri, edits in pairs(workspace_edit.changes or {}) do
    for _, edit in ipairs(edits) do
      callback(uri, edit)
    end
  end
  for _, change in ipairs(workspace_edit.documentChanges or {}) do
    if change.textDocument and change.edits then
      for _, edit in ipairs(change.edits) do
        callback(change.textDocument.uri, edit)
      end
    end
  end
end

local function escape_pattern(value)
  return (value:gsub("([^%w])", "%%%1"))
end

local function proposed_method(edits, method_name)
  local escaped_name = escape_pattern(method_name)
  for _, workspace_edit in ipairs(edits) do
    local found
    each_text_edit(workspace_edit, function(uri, edit)
      if found or type(edit.newText) ~= "string" then
        return
      end
      local _, _, start, indent, signature =
        edit.newText:find("()([ \t]*)([^\n{};]-[%w_$<>%[%]]+[ \t]+" .. escaped_name .. "[ \t]*%b())[ \t]*{")
      if start then
        signature = vim.trim(signature)
        if signature:match("^private%s+") or signature:match("^protected%s+") then
          signature = signature:gsub("^%w+", "public", 1)
        elseif not signature:match("^public%s+") then
          signature = "public " .. signature
        end
        found = { uri = uri, edit = edit, start = start, indent = indent, signature = signature }
      end
    end)
    if found then
      return found
    end
  end
end

local function replace_generated_method(proposal, signature)
  local text = proposal.edit.newText
  local open = text:find("{", proposal.start, true)
  local body_start, body_end
  if open then
    body_start, body_end = text:find("%b{}", open)
  end
  if not body_start then
    return false
  end

  local indent = proposal.indent
  local replacement = table.concat({
    indent .. signature .. " {",
    indent .. '  throw new UnsupportedOperationException("Not implemented yet");',
    indent .. "}",
  }, "\n")
  proposal.edit.newText = text:sub(1, proposal.start - 1) .. replacement .. text:sub(body_end + 1)
  return true
end

local function jump_to_method(uri, method_name)
  vim.cmd.edit(vim.fn.fnameescape(vim.uri_to_fname(uri)))
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local pattern = "\\<" .. vim.fn.escape(method_name, "\\") .. "\\>\\s*("
  local line = vim.fn.search(pattern, "W")
  if line > 0 then
    vim.api.nvim_win_set_cursor(0, { line + 1, 0 })
  end
end

local function confirm_and_apply(action, client, method_name)
  local edits = workspace_edits(action)
  local proposal = proposed_method(edits, method_name)
  if not proposal then
    vim.notify("JDTLS did not provide a previewable create-method edit", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "Create method signature: ", default = proposal.signature }, function(signature)
    signature = signature and vim.trim(signature) or ""
    if signature == "" then
      return
    end
    if not signature:match("%s" .. escape_pattern(method_name) .. "%s*%b()$") then
      vim.notify("Signature must declare " .. method_name .. "(...) without a method body", vim.log.levels.ERROR)
      return
    end
    if not replace_generated_method(proposal, signature) then
      vim.notify("Could not update the method generated by JDTLS", vim.log.levels.ERROR)
      return
    end

    for _, edit in ipairs(edits) do
      vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding or "utf-16")
    end
    jump_to_method(proposal.uri, method_name)
  end)
end

local function resolve_and_confirm(action, client, method_name)
  if #workspace_edits(action) > 0 then
    confirm_and_apply(action, client, method_name)
  elseif client:supports_method("codeAction/resolve") and action.data then
    client:request("codeAction/resolve", action, function(error, resolved)
      if error or not resolved then
        vim.notify("JDTLS could not resolve the create-method action", vim.log.levels.WARN)
        return
      end
      confirm_and_apply(resolved, client, method_name)
    end)
  else
    vim.notify("JDTLS found a create-method action but supplied no editable workspace edit", vim.log.levels.WARN)
  end
end

local function create_missing_method(bufnr, client)
  local method_name = vim.fn.expand("<cword>")
  if not method_name:match("^[%a_$][%w_$]*$") then
    vim.notify("Place the cursor on the unresolved method name", vim.log.levels.WARN)
    return
  end

  local params = java_range_params(bufnr, client)
  params.context.diagnostics = diagnostics_at_cursor(bufnr)
  params.context.only = { "quickfix" }
  vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(responses)
    local choices = {}
    for client_id, response in pairs(responses or {}) do
      for _, action in ipairs(response.result or {}) do
        if is_create_method_action(action) then
          table.insert(choices, { action = action, client = vim.lsp.get_client_by_id(client_id) or client })
        end
      end
    end

    if #choices == 0 then
      vim.notify("JDTLS found no create-method action at the cursor", vim.log.levels.WARN)
    elseif #choices == 1 then
      resolve_and_confirm(choices[1].action, choices[1].client, method_name)
    else
      vim.ui.select(choices, {
        prompt = "Select JDTLS create-method action:",
        format_item = function(choice)
          return choice.action.title
        end,
      }, function(choice)
        if choice then
          resolve_and_confirm(choice.action, choice.client, method_name)
        end
      end)
    end
  end)
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
            create_missing_method(args.buf, client)
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
