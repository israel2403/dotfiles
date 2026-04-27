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

-- Read the `package` declaration out of an existing .java file. Returns nil
-- if the file has no package (default package) or can't be read.
local function read_package_from_file(path)
  local fh = io.open(path, "r")
  if not fh then
    return nil
  end
  for _ = 1, 80 do
    local line = fh:read("*l")
    if line == nil then
      break
    end
    local pkg = line:match("^%s*package%s+([%w_%.]+)%s*;")
    if pkg then
      fh:close()
      return pkg
    end
  end
  fh:close()
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

-- Look at the existing source tree under <project_root>/src/main/java (or
-- src/test/java) and infer the "base package" by reading a representative
-- file. We pick the .java file with the shortest absolute path so we land
-- on something close to the project's top-level package, then read its
-- `package ...;` declaration.
local function detect_base_package(project_root)
  for _, src_root in ipairs({ "src/main/java", "src/test/java" }) do
    local java_root = project_root .. "/" .. src_root
    if vim.fn.isdirectory(java_root) == 1 then
      local files = vim.fn.globpath(java_root, "**/*.java", false, true)
      if #files > 0 then
        table.sort(files, function(a, b)
          return #a < #b
        end)
        local pkg = read_package_from_file(files[1])
        if pkg then
          return pkg, java_root
        end
      end
    end
  end
  return nil, nil
end

-- Resolve (package, target_dir) from the directory the user invoked Jc in:
--
--   * Inside .../src/main/java/<pkg>          -> derive package from path,
--                                                 target stays = dir.
--   * Exactly .../src/main/java               -> default package (""),
--                                                 target stays = dir.
--   * Anywhere else within a Maven/Gradle root-> detect base package from
--                                                 the project's own sources;
--                                                 retarget to that dir so
--                                                 the file lands sensibly.
--   * No project root, no package detectable  -> nil package, current dir.
local function resolve_pkg_and_dir(dir)
  -- Case A: already inside a Java source root
  local pkg = get_package_name(dir)
  if pkg ~= nil then
    return pkg, dir
  end

  -- Case B: dir is the source root itself -> default package
  if dir:match("/src/main/java$") or dir:match("/src/test/java$") then
    return "", dir
  end

  -- Case C: outside src/main/java but still inside a project
  local root = find_project_root()
  if root then
    local detected_pkg, java_root = detect_base_package(root)
    if detected_pkg and java_root then
      local pkg_path = detected_pkg:gsub("%.", "/")
      return detected_pkg, java_root .. "/" .. pkg_path
    end
    -- Project found but no existing .java file -> seed at src/main/java
    -- with default package.
    if vim.fn.isdirectory(root .. "/src/main/java") == 1 then
      return "", root .. "/src/main/java"
    end
  end

  -- Case D: last resort -- write where we are with no package declaration
  return nil, dir
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

        -- Fully auto-resolve package + target dir. No prompt for package.
        local pkg, target_dir = resolve_pkg_and_dir(dir)
        -- write_java_file expects nil to mean "no package declaration".
        -- We use "" internally to mean "default package" (also nil at write
        -- time). Anything else is a real package and gets emitted.
        local pkg_for_write = (pkg ~= nil and pkg ~= "") and pkg or nil

        local where = vim.fn.fnamemodify(target_dir, ":~")
        local pkg_label = pkg_for_write or "<default package>"
        vim.notify(
          string.format("Creating %s '%s' in %s (package: %s)", choice.label, name, where, pkg_label),
          vim.log.levels.INFO
        )

        write_java_file(choice, name, pkg_for_write, target_dir)
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
        { "<leader>Jc", create_java_type, desc = "Create Java type" },
      },
    },
  },
}
