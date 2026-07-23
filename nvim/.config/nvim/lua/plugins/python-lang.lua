-- Python project support: venv detection, LSP tuning, project initialization
-- Enhances LazyVim Python extra (lazyvim.plugins.extras.lang.python)

local function find_project_root()
  local markers = {
    "pyrightconfig.json", "pyproject.toml", "setup.py", "setup.cfg",
    ".venv", "venv", "requirements.txt", "Pipfile", "tox.ini",
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
  return nil
end

local function find_venv()
  local root = find_project_root() or vim.fn.getcwd()
  for _, name in ipairs({ ".venv", "venv", "env" }) do
    local py = root .. "/" .. name .. "/bin/python"
    if vim.fn.executable(py) == 1 then
      return root .. "/" .. name, py
    end
  end
  return nil, nil
end

local function get_python_path()
  local _, py = find_venv()
  return py or vim.fn.exepath("python3") or vim.fn.exepath("python") or "python3"
end

-- Create .venv and install dev tools
local function create_venv()
  local root = find_project_root() or vim.fn.getcwd()
  if vim.fn.isdirectory(root .. "/.venv") == 1 then
    vim.notify(".venv already exists at " .. root, vim.log.levels.INFO)
    return
  end
  Snacks.terminal.open(
    "python3 -m venv .venv && source .venv/bin/activate && pip install --upgrade pip && pip install pyright ruff black debugpy",
    {
      cwd = root,
      interactive = false,
      win = {
        border = "rounded",
        title = "  Creating venv ",
        title_pos = "center",
        padding = { top = 1, bottom = 1, left = 2, right = 2 },
      },
    }
  )
end

-- Show active venv info
local function show_venv()
  local venv, py = find_venv()
  if venv then
    vim.notify("  Venv: " .. venv .. "\n  Python: " .. py, vim.log.levels.INFO)
  else
    local sys_py = vim.fn.exepath("python3") or "python3"
    vim.notify("  No venv detected\n  System: " .. sys_py, vim.log.levels.WARN)
  end
end

-- Initialize Python project: pyrightconfig.json + .gitignore + .venv
local function init_project()
  local root = vim.fn.getcwd()

  local cfg = root .. "/pyrightconfig.json"
  if vim.fn.filereadable(cfg) == 0 then
    vim.fn.writefile({
      "{",
      '  "venvPath": ".",',
      '  "venv": ".venv",',
      '  "reportMissingImports": true,',
      '  "reportMissingTypeStubs": false,',
      '  "pythonVersion": "3.12",',
      '  "typeCheckingMode": "basic"',
      "}",
    }, cfg)
    vim.notify("Created pyrightconfig.json", vim.log.levels.INFO)
  end

  local gi = root .. "/.gitignore"
  if vim.fn.filereadable(gi) == 0 then
    vim.fn.writefile({
      "__pycache__/",
      "*.py[cod]",
      ".venv/",
      "*.egg-info/",
      "dist/",
      "build/",
      ".ruff_cache/",
    }, gi)
    vim.notify("Created .gitignore", vim.log.levels.INFO)
  end

  if vim.fn.isdirectory(root .. "/.venv") == 0 then
    create_venv()
  else
    vim.notify("  Python project ready!", vim.log.levels.INFO)
  end
end

vim.keymap.set("n", "<leader>Pv", show_venv, { desc = "Show venv info" })
vim.keymap.set("n", "<leader>Pc", create_venv, { desc = "Create venv" })
vim.keymap.set("n", "<leader>Pi", init_project, { desc = "Init Python project" })

return {
  -- Pyright: enhanced settings + venv auto-detection
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          before_init = function(_, config)
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = get_python_path()
          end,
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoImportCompletions = true,
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = true,
                autoSearchPaths = true,
              },
            },
          },
        },
      },
    },
  },

  -- Which-key: Python group + project commands
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>P", group = "Python", icon = "" },
        { "<leader>Pv", show_venv, desc = "Show venv info" },
        { "<leader>Pc", create_venv, desc = "Create venv" },
        { "<leader>Pi", init_project, desc = "Init Python project" },
      },
    },
  },
}
