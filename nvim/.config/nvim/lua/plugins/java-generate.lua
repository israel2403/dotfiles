-- Generate real Java members through JDTLS, using the class at the cursor.
local function notify(message)
  vim.notify(message, vim.log.levels.WARN, { title = "Generate Java members" })
end

-- vim.ui.select works with the configured Snacks UI. Enter toggles a field;
-- Generate applies the selection. Escape always cancels without editing.
local function select_fields(fields, label, callback)
  local selected = {}
  local function show()
    local choices = {
      { action = "done", label = "Generate selected fields" },
      { action = "all", label = "Select all" },
      { action = "none", label = "Clear selection" },
    }
    for index, field in ipairs(fields) do
      choices[#choices + 1] = {
        index = index,
        label = (selected[index] and "[x] " or "[ ] ") .. label(field),
      }
    end
    vim.ui.select(choices, {
      prompt = "Fields: Enter to toggle; choose Generate when ready",
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if not choice then
        return
      end
      if choice.action == "done" then
        local result = {}
        for index, field in ipairs(fields) do
          if selected[index] then
            result[#result + 1] = field
          end
        end
        if #result == 0 then
          notify("Select at least one field, or press Escape to cancel")
        else
          callback(result)
          return
        end
      elseif choice.action == "all" then
        for index in ipairs(fields) do
          selected[index] = true
        end
      elseif choice.action == "none" then
        selected = {}
      else
        selected[choice.index] = not selected[choice.index]
      end
      vim.schedule(show)
    end)
  end
  show()
end

local function generate()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "java" then
    notify("Open a Java file and place the cursor inside the class")
    return
  end
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })[1]
  if not client then
    notify("JDTLS is not attached yet; wait for the Java project to load")
    return
  end
  local tick = vim.api.nvim_buf_get_changedtick(bufnr)
  local context = vim.lsp.util.make_range_params(0, client.offset_encoding or "utf-16")
  context.context = { diagnostics = {} }
  local function unchanged()
    if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
      notify("The Java buffer changed; run Generate again")
      return false
    end
    return true
  end
  local function request(method, params, callback)
    if not unchanged() then
      return
    end
    client:request(method, params, function(err, result)
      if err then
        notify("JDTLS: " .. (err.message or tostring(err)))
      elseif unchanged() then
        callback(result)
      end
    end, bufnr)
  end
  local function apply(edit)
    if not edit or (not next(edit.changes or {}) and not next(edit.documentChanges or {})) then
      notify("JDTLS returned no changes; the members may already exist")
      return
    end
    vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding or "utf-16")
  end
  local function accessors(kind)
    local params = vim.deepcopy(context)
    params.kind = kind
    request("java/resolveUnimplementedAccessors", params, function(fields)
      if not fields or #fields == 0 then
        notify("No missing accessors available for this class")
        return
      end
      select_fields(fields, function(field)
        local methods = {}
        if field.generateGetter then
          methods[#methods + 1] = "getter"
        end
        if field.generateSetter then
          methods[#methods + 1] = "setter"
        end
        return field.fieldName .. ": " .. field.typeName .. " (" .. table.concat(methods, " + ") .. ")"
      end, function(selected)
        request("java/generateAccessors", { context = context, accessors = selected }, apply)
      end)
    end)
  end
  local function constructors(empty)
    request("java/checkConstructorsStatus", context, function(status)
      local available = status and status.constructors or {}
      if empty then
        available = vim.tbl_filter(function(item)
          return #(item.parameters or {}) == 0
        end, available)
      end
      if #available == 0 then
        notify(
          empty and "No accessible no-argument superclass constructor is available"
            or "No constructors available; place the cursor inside a class"
        )
        return
      end
      local function choose_fields(constructor)
        if not constructor then
          return
        end
        local function submit(fields)
          request("java/generateConstructors", {
            context = context,
            constructors = { constructor },
            fields = fields,
          }, apply)
        end
        if empty then
          submit({})
        elseif not status.fields or #status.fields == 0 then
          notify("No fields available; use Empty constructor instead")
        else
          select_fields(status.fields, function(field)
            return field.name .. ": " .. field.type
          end, submit)
        end
      end
      if #available == 1 then
        choose_fields(available[1])
      else
        vim.ui.select(available, {
          prompt = "Superclass constructor (its parameters are included):",
          format_item = function(item)
            return item.name .. "(" .. table.concat(item.parameters or {}, ", ") .. ")"
          end,
        }, choose_fields)
      end
    end)
  end
  vim.ui.select({
    { label = "Getters", kind = "GETTER" },
    { label = "Setters", kind = "SETTER" },
    { label = "Getters and setters", kind = "BOTH" },
    { label = "Empty constructor", empty = true },
    { label = "Constructor with selected fields", empty = false },
  }, {
    prompt = "Generate Java members:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice or not unchanged() then
      return
    end
    if choice.kind then
      accessors(choice.kind)
    else
      constructors(choice.empty)
    end
  end)
end

vim.keymap.set("n", "<leader>Jg", generate, { desc = "Generate Java members" })

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>Jg", generate, desc = "Generate Java members" },
      },
    },
  },
}
