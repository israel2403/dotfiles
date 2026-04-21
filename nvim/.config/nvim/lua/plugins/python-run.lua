-- Python file runner: run scripts and modules in Snacks terminal
-- Equivalent of java-run.lua for Python projects

local function find_project_root()
  local markers = {
    "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg",
    ".venv", "venv", "requirements.txt", "Pipfile",
  }
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or dir == "." then
    dir = vim.fn.getcwd()
  end
  while dir ~= "/" do
    for _, m in ipairs(markers) do
      local p = dir .. "/" .. m
      if vim.fn.filereadable(p) == 1 or vim.fn.isdirectory(p) == 1 then
        return dir
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return vim.fn.getcwd()
end

local function get_python(root)
  for _, name in ipairs({ ".venv", "venv", "env" }) do
    local py = root .. "/" .. name .. "/bin/python"
    if vim.fn.executable(py) == 1 then
      return py
    end
  end
  return "python3"
end

local function get_module_name(filepath, root)
  -- /root/path/to/file.py → path.to.file
  if filepath:sub(1, #root) ~= root then
    return nil
  end
  local rel = filepath:sub(#root + 2)
  rel = rel:gsub("%.py$", ""):gsub("/", "."):gsub("%.__init__$", "")
  return rel
end

local last_run_term = nil

local function run_python()
  local filepath = vim.fn.expand("%:p")
  if not filepath:match("%.py$") then
    vim.notify("Not a Python file", vim.log.levels.WARN)
    return
  end

  -- Save before running
  vim.cmd("silent! write")

  local root = find_project_root()
  local python = get_python(root)
  local filename = vim.fn.expand("%:t")
  local module = get_module_name(filepath, root)

  local options = {
    { label = " Run file", cmd = python .. " " .. vim.fn.shellescape(filepath) },
  }

  if module then
    table.insert(options, {
      label = "󰏗 Run as module (-m " .. module .. ")",
      cmd = python .. " -m " .. module,
    })
  end

  table.insert(options, { label = " Run with args", needs_input = true })

  vim.ui.select(options, {
    prompt = "Run: " .. filename,
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end

    local function execute(cmd)
      if last_run_term then
        pcall(function()
          last_run_term:close()
        end)
      end
      last_run_term = Snacks.terminal.open(cmd, {
        cwd = root,
        interactive = false,
        start_insert = false,
        win = {
          border = "rounded",
          title = "  " .. filename .. " ",
          title_pos = "center",
          padding = { top = 1, bottom = 1, left = 2, right = 2 },
        },
      })
    end

    if choice.needs_input then
      vim.schedule(function()
        vim.ui.input({ prompt = "Arguments: " }, function(args)
          if not args then
            return
          end
          execute(python .. " " .. vim.fn.shellescape(filepath) .. " " .. args)
        end)
      end)
    else
      execute(choice.cmd)
    end
  end)
end

local function reopen_last_run()
  if last_run_term then
    last_run_term:toggle()
  else
    vim.notify("No previous Python run", vim.log.levels.INFO)
  end
end

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>Pr", run_python, desc = "Run Python file" },
        { "<leader>Po", reopen_last_run, desc = "Reopen last run" },
      },
    },
  },
}
