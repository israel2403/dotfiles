local function current_path()
  local path = vim.api.nvim_buf_get_name(0)
  return path ~= "" and path or vim.uv.cwd()
end

local function find_maven_root()
  return vim.fs.root(current_path(), "pom.xml")
end

local function package_from_path(path, source_root)
  local relative = path:sub(#source_root + 2)
  if relative == "" then
    return ""
  end
  return relative:gsub("/", ".")
end

local function read_package(path)
  if vim.fn.filereadable(path) ~= 1 then
    return
  end
  for _, line in ipairs(vim.fn.readfile(path, "", 100)) do
    local package = line:match("^%s*package%s+([%a_$][%w_$.]*)%s*;")
    if package then
      return package
    end
  end
end

local function buffer_package(bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 100, false)) do
    local package = line:match("^%s*package%s+([%a_$][%w_$.]*)%s*;")
    if package then
      return package
    end
  end
  return ""
end

local function valid_package_name(package)
  if package == "" or package:sub(1, 1) == "." or package:sub(-1) == "." or package:find("..", 1, true) then
    return false
  end
  for segment in package:gmatch("[^.]+") do
    if not segment:match("^[%a_$][%w_$]*$") then
      return false
    end
  end
  return true
end

local function available_packages(root)
  local packages = {}

  for _, relative_root in ipairs({ "src/main/java", "src/test/java" }) do
    local source_root = root .. "/" .. relative_root
    if vim.fn.isdirectory(source_root) == 1 then
      for _, path in ipairs(vim.fn.globpath(source_root, "**/*.java", false, true)) do
        local package = read_package(path)
        if package then
          packages[package] = true
        end
      end

      -- Empty package directories are useful choices too, even before their
      -- first Java source file has been added.
      for _, path in ipairs(vim.fn.globpath(source_root, "**", false, true)) do
        if vim.fn.isdirectory(path) == 1 then
          local package = package_from_path(path, source_root)
          if valid_package_name(package) then
            packages[package] = true
          end
        end
      end
    end
  end

  local current_package = read_package(current_path())
  if current_package then
    packages[current_package] = true
  end

  local result = vim.tbl_keys(packages)
  table.sort(result)
  return result
end

local function valid_type_name(name)
  return name:match("^[%a_$][%w_$]*$") ~= nil
end

local function target_path(root, package, name)
  local dir = root .. "/src/main/java"
  if package ~= "" then
    dir = dir .. "/" .. package:gsub("%.", "/")
  end
  return dir, dir .. "/" .. name .. ".java"
end

local function ensure_origin_import(bufnr, package, name)
  local import = "import " .. package .. "." .. name .. ";"
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local package_line
  local first_import

  for index, line in ipairs(lines) do
    if vim.trim(line) == import then
      return
    end
    if not package_line and line:match("^%s*package%s+") then
      package_line = index
    elseif not first_import and line:match("^%s*import%s+") then
      first_import = index
    end
  end

  if first_import then
    local inserted = lines[first_import]:match("^%s*import%s+static%s+") and { import, "" } or { import }
    vim.api.nvim_buf_set_lines(bufnr, first_import - 1, first_import - 1, false, inserted)
  elseif package_line and lines[package_line + 1] and vim.trim(lines[package_line + 1]) == "" then
    vim.api.nvim_buf_set_lines(bufnr, package_line + 1, package_line + 1, false, { import, "" })
  elseif package_line then
    vim.api.nvim_buf_set_lines(bufnr, package_line, package_line, false, { "", import, "" })
  else
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { import, "" })
  end
end

local function organize_origin_import(origin, package, name, path, on_complete)
  if package == "" or buffer_package(origin.bufnr) == package then
    on_complete()
    return
  end

  local client = vim.iter(vim.lsp.get_clients({ bufnr = origin.bufnr })):find(function(candidate)
    return candidate.name == "jdtls"
  end)
  if not client then
    vim.notify("Created " .. name .. ", but JDTLS is not attached to the original file", vim.log.levels.WARN)
    ensure_origin_import(origin.bufnr, package, name)
    on_complete()
    return
  end

  if client:supports_method("workspace/didCreateFiles") then
    client:notify("workspace/didCreateFiles", { files = { { uri = vim.uri_from_fname(path) } } })
  end

  local position = {
    line = origin.cursor[1] - 1,
    character = origin.cursor[2],
  }
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(origin.bufnr) },
    range = { start = position, ["end"] = position },
    context = { diagnostics = {} },
  }

  client:request("java/organizeImports", params, function(error, edit)
    if error then
      vim.notify("Created " .. name .. ", but JDTLS could not add its import: " .. error.message, vim.log.levels.WARN)
    elseif edit then
      vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding)
    end
    -- A newly written source file may not be indexed by JDTLS quickly enough
    -- for organizeImports to resolve it. Preserve the LSP-first behavior, but
    -- guarantee the requested import when the server returned no such edit.
    ensure_origin_import(origin.bufnr, package, name)
    on_complete()
  end, origin.bufnr)
end

local function open_java_type(path, package)
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { package ~= "" and 4 or 2, 0 })
end

local function write_java_type(root, package, name, declaration, origin)
  local dir, path = target_path(root, package, name)
  if vim.fn.filereadable(path) == 1 then
    vim.notify(vim.fn.fnamemodify(path, ":~") .. " already exists", vim.log.levels.ERROR)
    return
  end

  local lines = {}
  if package ~= "" then
    vim.list_extend(lines, { "package " .. package .. ";", "" })
  end
  vim.list_extend(lines, { declaration:format(name), "", "}", "" })

  vim.fn.mkdir(dir, "p")
  local ok, error = pcall(vim.fn.writefile, lines, path)
  if not ok then
    vim.notify("Could not create " .. path .. ": " .. tostring(error), vim.log.levels.ERROR)
    return
  end

  if origin and vim.api.nvim_buf_is_valid(origin.bufnr) then
    organize_origin_import(origin, package, name, path, function()
      open_java_type(path, package)
    end)
  else
    open_java_type(path, package)
  end
end

local function choose_package(root, callback)
  local packages = available_packages(root)
  if vim.tbl_isempty(packages) then
    vim.notify("No Java packages found in this Maven project", vim.log.levels.WARN)
    return
  end
  vim.ui.select(packages, { prompt = "Select production package:" }, callback)
end

local java_types = {
  { label = "Class", declaration = "public class %s {" },
  { label = "Interface", declaration = "public interface %s {" },
  { label = "Enum", declaration = "public enum %s {" },
  { label = "Record", declaration = "public record %s() {" },
  { label = "Annotation", declaration = "public @interface %s {" },
}

local function choose_java_type(callback)
  vim.ui.select(java_types, {
    prompt = "Select Java type:",
    format_item = function(item)
      return item.label
    end,
  }, callback)
end

local function create_type_from_cursor()
  local root = find_maven_root()
  if not root then
    vim.notify("Create Java Type requires a Maven project (pom.xml not found)", vim.log.levels.WARN)
    return
  end

  local proposed_name = vim.fn.expand("<cword>")
  if not valid_type_name(proposed_name) then
    proposed_name = ""
  end

  local origin = {
    bufnr = vim.api.nvim_get_current_buf(),
    cursor = vim.api.nvim_win_get_cursor(0),
  }

  vim.ui.input({ prompt = "Type name: ", default = proposed_name }, function(name)
    name = name and vim.trim(name) or ""
    if name == "" then
      return
    end
    if not valid_type_name(name) then
      vim.notify("Invalid Java type name: " .. name, vim.log.levels.ERROR)
      return
    end

    choose_package(root, function(package)
      if package then
        choose_java_type(function(choice)
          if choice then
            write_java_type(root, package, name, choice.declaration, origin)
          end
        end)
      end
    end)
  end)
end

-- Keep the original general-purpose creator on Jt. Unlike the cursor-driven
-- TDD path, it also offers abstract classes and does not modify another file.
local function create_java_type()
  local types = {
    { label = "Class", declaration = "public class %s {" },
    { label = "Abstract Class", declaration = "public abstract class %s {" },
    { label = "Interface", declaration = "public interface %s {" },
    { label = "Enum", declaration = "public enum %s {" },
    { label = "Record", declaration = "public record %s() {" },
    { label = "Annotation", declaration = "public @interface %s {" },
  }
  local root = find_maven_root()
  if not root then
    vim.notify("Create Java Type requires a Maven project (pom.xml not found)", vim.log.levels.WARN)
    return
  end

  vim.ui.select(types, {
    prompt = "Select Java type:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    vim.ui.input({ prompt = choice.label .. " name: " }, function(name)
      name = name and vim.trim(name) or ""
      if name == "" then
        return
      end
      if not valid_type_name(name) then
        vim.notify("Invalid Java type name: " .. name, vim.log.levels.ERROR)
        return
      end
      choose_package(root, function(package)
        if package then
          write_java_type(root, package, name, choice.declaration)
        end
      end)
    end)
  end)
end

vim.keymap.set("n", "<leader>Jc", create_type_from_cursor, { desc = "Create Missing Java Type" })
vim.keymap.set("n", "<leader>Jt", create_java_type, { desc = "Create Java Type" })

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>J", group = "Java", icon = "" },
        { "<leader>Jc", create_type_from_cursor, desc = "Create Missing Java Type" },
        { "<leader>Jt", create_java_type, desc = "Create Java Type" },
      },
    },
  },
}
