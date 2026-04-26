local function find_project_root()
  local markers = { "pom.xml", "build.gradle", "build.gradle.kts" }
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

local function get_main_class()
  local filepath = vim.fn.expand("%:p")
  if not filepath:match("%.java$") then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Extract package name (Java identifiers can contain underscores; Lua's %w does not match _)
  local pkg = nil
  for _, line in ipairs(lines) do
    pkg = line:match("^%s*package%s+([%w_%.]+)%s*;")
    if pkg then
      break
    end
  end

  -- Find which class/interface contains the main method
  -- Track nesting of classes/interfaces
  local class_stack = {}
  local brace_depth = 0
  local main_class = nil

  for _, line in ipairs(lines) do
    -- Detect class/interface/enum declarations
    local class_name = line:match("class%s+([%w_]+)") or line:match("interface%s+([%w_]+)") or line:match("enum%s+([%w_]+)")
    if class_name then
      table.insert(class_stack, { name = class_name, depth = brace_depth })
    end

    -- Track braces
    for _ in line:gmatch("{") do
      brace_depth = brace_depth + 1
    end
    for _ in line:gmatch("}") do
      brace_depth = brace_depth - 1
      -- Pop classes that have been closed
      while #class_stack > 0 and class_stack[#class_stack].depth >= brace_depth do
        if main_class then
          break
        end
        table.remove(class_stack)
      end
    end

    -- Detect main method
    if line:match("public%s+static%s+void%s+main%s*%(") then
      -- Build the fully qualified inner class name
      local parts = {}
      for _, entry in ipairs(class_stack) do
        table.insert(parts, entry.name)
      end
      if #parts > 0 then
        -- First part is the outer class, rest are joined with $
        local outer = table.remove(parts, 1)
        main_class = outer
        if #parts > 0 then
          main_class = outer .. "$" .. table.concat(parts, "$")
        end
      end
    end
  end

  if not main_class then
    return nil
  end

  if pkg then
    return pkg .. "." .. main_class
  end
  return main_class
end

-- Store last run so we can reopen it
local last_run_term = nil

local function run_java_main()
  local main_class = get_main_class()
  if not main_class then
    vim.notify("No main method found in current file", vim.log.levels.WARN)
    return
  end

  local project_root = find_project_root()
  if not project_root then
    vim.notify("No Maven/Gradle project found", vim.log.levels.ERROR)
    return
  end

  local options = {
    { label = " Run (skip tests)", cmd = "mvn -q compile exec:java -DskipTests -Dexec.mainClass=\"" .. main_class .. "\"" },
    { label = "󰤑 Run (with tests)", cmd = "mvn -q test exec:java -Dexec.mainClass=\"" .. main_class .. "\"" },
  }

  vim.ui.select(options, {
    prompt = "Run: " .. main_class,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end

    -- Close previous run terminal if still open
    if last_run_term then
      pcall(function() last_run_term:close() end)
    end

    last_run_term = Snacks.terminal.open(choice.cmd, {
      cwd = project_root,
      interactive = false,
      start_insert = false,
      win = {
        border = "rounded",
        title = " " .. main_class .. " ",
        title_pos = "center",
        padding = { top = 1, bottom = 1, left = 2, right = 2 },
      },
    })
  end)
end

local function reopen_last_run()
  if last_run_term then
    last_run_term:toggle()
  else
    vim.notify("No previous run to reopen", vim.log.levels.INFO)
  end
end

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>Jr", run_java_main, desc = "Run main class" },
        { "<leader>Jo", reopen_last_run, desc = "Reopen last run" },
      },
    },
  },
}
