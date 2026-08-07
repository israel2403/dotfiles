local Source = {}

local function maven_root(bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  return vim.fs.root(filename ~= "" and filename or vim.uv.cwd(), "pom.xml")
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

local function jsp_web_path(root, bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local webapp = root .. "/src/main/webapp"
  if filename:sub(1, #webapp + 1) ~= webapp .. "/" then
    return nil
  end
  return "/" .. filename:sub(#webapp + 2)
end

local function forwarded_attributes(root, jsp_path)
  local attributes = {}
  local java_root = root .. "/src/main/java"
  local java_files = vim.fn.globpath(java_root, "**/*.java", false, true)

  for _, path in ipairs(java_files) do
    local content = read_file(path)
    if content then
      local forwards_here = false
      for target in content:gmatch('getRequestDispatcher%s*%(%s*"([^"]+)"%s*%)') do
        if target == jsp_path then
          forwards_here = true
          break
        end
      end

      if forwards_here then
        for name in content:gmatch('setAttribute%s*%(%s*"([%a_][%w_]*)"%s*,') do
          attributes[name] = path
        end
      end
    end
  end

  return attributes
end

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source:enabled()
  return vim.bo.filetype == "jsp"
end

function Source:get_trigger_characters()
  return { "{" }
end

function Source:get_completions(context, callback)
  local before_cursor = context.line:sub(1, context.cursor[2])
  if not before_cursor:match("%${[%w_]*$") then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local root = maven_root(context.bufnr)
  local jsp_path = root and jsp_web_path(root, context.bufnr)
  if not jsp_path then
    callback({ items = {}, is_incomplete_forward = false, is_incomplete_backward = false })
    return
  end

  local items = {}
  local kind = require("blink.cmp.types").CompletionItemKind.Variable
  for name, java_path in pairs(forwarded_attributes(root, jsp_path)) do
    table.insert(items, {
      label = name,
      insertText = name,
      kind = kind,
      detail = "JSP request attribute",
      documentation = {
        kind = "markdown",
        value = ("Set in `%s` before forwarding to `%s`."):format(vim.fs.basename(java_path), jsp_path),
      },
    })
  end
  table.sort(items, function(a, b)
    return a.label < b.label
  end)

  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
end

return Source
