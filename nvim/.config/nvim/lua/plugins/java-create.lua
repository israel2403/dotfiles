local function get_package_name(dir)
  for _, src_root in ipairs({ "src/main/java/", "src/test/java/" }) do
    local _, end_idx = dir:find(src_root, 1, true)
    if end_idx then
      local pkg_path = dir:sub(end_idx + 1)
      if pkg_path ~= "" then
        return (pkg_path:gsub("/", "."))
      end
    end
  end
  return nil
end

local function find_project_root()
  local markers = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" }
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or dir == "." then
    dir = vim.fn.getcwd()
  end
  while dir ~= "/" do
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(dir .. "/" .. marker) == 1 then
        return dir
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return nil
end

local function write_java_file(choice, name, pkg, dir)
  local lines = {}
  if pkg then
    table.insert(lines, "package " .. pkg .. ";")
    table.insert(lines, "")
  end
  table.insert(lines, string.format(choice.decl, name))
  table.insert(lines, "")
  table.insert(lines, "}")
  table.insert(lines, "")

  local filepath = dir .. "/" .. name .. ".java"
  if vim.fn.filereadable(filepath) == 1 then
    vim.notify(name .. ".java already exists!", vim.log.levels.ERROR)
    return
  end

  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(lines, filepath)
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))

  local cursor_line = pkg and 4 or 2
  vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
end

local function get_target_dir()
  -- If in neo-tree, get the selected node's directory
  if vim.bo.filetype == "neo-tree" then
    local ok, manager = pcall(require, "neo-tree.sources.manager")
    if ok then
      local state = manager.get_state("filesystem")
      if state and state.tree then
        local node = state.tree:get_node()
        if node then
          local path = node:get_id()
          if node.type == "directory" then
            return path
          else
            return vim.fn.fnamemodify(path, ":h")
          end
        end
      end
    end
  end

  local dir = vim.fn.expand("%:p:h")
  if dir ~= "" and dir ~= "." then
    return dir
  end
  return vim.fn.getcwd()
end

local function create_java_type()
  local types = {
    { label = "Class", decl = "public class %s {" },
    { label = "Abstract Class", decl = "public abstract class %s {" },
    { label = "Interface", decl = "public interface %s {" },
    { label = "Enum", decl = "public enum %s {" },
    { label = "Record", decl = "public record %s() {" },
    { label = "Annotation", decl = "public @interface %s {" },
  }

  -- Capture the directory BEFORE opening any UI (while still in neo-tree)
  local dir = get_target_dir()

  vim.ui.select(types, {
    prompt = "Select Java type:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end

    vim.schedule(function()
      vim.ui.input({ prompt = choice.label .. " name: " }, function(name)
        if not name or name == "" then
          return
        end

        local pkg = get_package_name(dir)

        if pkg then
          -- Already inside src/main/java/... — auto-detect package, create here
          write_java_file(choice, name, pkg, dir)
        else
          -- Not in a source dir — prompt for package name
          vim.schedule(function()
            vim.ui.input({ prompt = "Package: " }, function(pkg_input)
              if not pkg_input or pkg_input == "" then
                -- No package given, create in current dir without package
                write_java_file(choice, name, nil, dir)
                return
              end

              local project_root = find_project_root() or vim.fn.getcwd()
              local pkg_path = pkg_input:gsub("%.", "/")
              local target_dir = project_root .. "/src/main/java/" .. pkg_path

              write_java_file(choice, name, pkg_input, target_dir)
            end)
          end)
        end
      end)
    end)
  end)
end

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>J", group = "Java", icon = "" },
        { "<leader>Jn", create_java_type, desc = "New Java type" },
      },
    },
  },
}
