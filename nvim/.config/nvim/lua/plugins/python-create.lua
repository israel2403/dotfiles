-- Python file/package creator: mirrors java-create.lua
-- Create modules, classes, packages, tests with proper boilerplate

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

local function write_python_file(filepath, lines)
  if vim.fn.filereadable(filepath) == 1 then
    vim.notify(vim.fn.fnamemodify(filepath, ":t") .. " already exists!", vim.log.levels.ERROR)
    return
  end

  local dir = vim.fn.fnamemodify(filepath, ":h")
  vim.fn.mkdir(dir, "p")
  vim.fn.writefile(lines, filepath)
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

local function to_class_name(name)
  -- snake_case → PascalCase: my_class → MyClass
  return name:gsub("(%a)([%w]*)", function(first, rest)
    return first:upper() .. rest
  end):gsub("_", "")
end

local function create_python_type()
  local types = {
    {
      label = "Script (with main)",
      template = function(name)
        return {
          '"""' .. name .. '."""',
          "",
          "",
          "def main():",
          "    pass",
          "",
          "",
          'if __name__ == "__main__":',
          "    main()",
          "",
        }
      end,
    },
    {
      label = "Class",
      template = function(name)
        local cls = to_class_name(name)
        return {
          '"""' .. cls .. ' module."""',
          "",
          "",
          "class " .. cls .. ":",
          '    """' .. cls .. '."""',
          "",
          "    def __init__(self):",
          "        pass",
          "",
        }
      end,
    },
    {
      label = "Dataclass",
      template = function(name)
        local cls = to_class_name(name)
        return {
          '"""' .. cls .. ' module."""',
          "",
          "from dataclasses import dataclass",
          "",
          "",
          "@dataclass",
          "class " .. cls .. ":",
          '    """' .. cls .. '."""',
          "",
          '    name: str = ""',
          "",
        }
      end,
    },
    {
      label = "Abstract class (ABC)",
      template = function(name)
        local cls = to_class_name(name)
        return {
          '"""' .. cls .. ' abstract module."""',
          "",
          "from abc import ABC, abstractmethod",
          "",
          "",
          "class " .. cls .. "(ABC):",
          '    """' .. cls .. '."""',
          "",
          "    @abstractmethod",
          "    def execute(self):",
          "        pass",
          "",
        }
      end,
    },
    {
      label = "Enum",
      template = function(name)
        local cls = to_class_name(name)
        return {
          '"""' .. cls .. ' enum module."""',
          "",
          "from enum import Enum",
          "",
          "",
          "class " .. cls .. "(Enum):",
          '    """' .. cls .. '."""',
          "",
          '    VALUE = "value"',
          "",
        }
      end,
    },
    {
      label = "Module (empty)",
      template = function(name)
        return {
          '"""' .. name .. ' module."""',
          "",
        }
      end,
    },
    {
      label = "Package",
      is_package = true,
      template = function(name)
        return {
          '"""' .. name .. ' package."""',
          "",
        }
      end,
    },
    {
      label = "Test class",
      prefix = "test_",
      template = function(name)
        local cls = to_class_name(name)
        return {
          '"""Tests for ' .. name .. '."""',
          "",
          "",
          "class Test" .. cls .. ":",
          '    """Test suite for ' .. cls .. '."""',
          "",
          "    def test_example(self):",
          "        assert True",
          "",
        }
      end,
    },
  }

  -- Capture the directory BEFORE opening any UI (while still in neo-tree)
  local dir = get_target_dir()

  vim.ui.select(types, {
    prompt = "Select Python type:",
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

        local lines = choice.template(name)

        if choice.is_package then
          write_python_file(dir .. "/" .. name .. "/__init__.py", lines)
        else
          local prefix = choice.prefix or ""
          write_python_file(dir .. "/" .. prefix .. name .. ".py", lines)
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
        { "<leader>Pn", create_python_type, desc = "New Python file" },
      },
    },
  },
}
