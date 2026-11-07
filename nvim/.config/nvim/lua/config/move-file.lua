local M = {}

local function inside(path, root)
  return path == root or path:sub(1, #root + 1) == root .. "/" or root == "/"
end

function M.move()
  local uv = vim.uv
  local root = uv.fs_realpath(vim.g.nvim_start_cwd or uv.cwd())
  local buf = vim.api.nvim_get_current_buf()
  local source = vim.api.nvim_buf_get_name(buf)
  local real_source = uv.fs_realpath(source)
  if vim.bo[buf].buftype ~= "" or not real_source or not root or not inside(real_source, root) then
    vim.notify("Open a file inside the Neovim launch directory first", vim.log.levels.WARN)
    return
  end
  if uv.fs_lstat(source).type ~= "file" then
    vim.notify("Only regular files can be moved", vim.log.levels.WARN)
    return
  end

  local folders = { root }
  local function scan(dir)
    local handle = uv.fs_scandir(dir)
    if not handle then
      return
    end
    while true do
      local name, kind = uv.fs_scandir_next(handle)
      if not name then
        break
      end
      if kind == "directory" and name ~= ".git" then
        local child = dir .. "/" .. name
        folders[#folders + 1] = child
        scan(child)
      end
    end
  end
  scan(root)
  table.sort(folders)
  vim.ui.select(folders, {
    prompt = "Move file to folder (launch directory)",
    format_item = function(dir)
      return dir == root and "." or dir:sub(#root + (root == "/" and 1 or 2))
    end,
  }, function(dir)
    if not dir then
      return
    end
    local real_dir = uv.fs_realpath(dir)
    if not real_dir or not inside(real_dir, root) then
      vim.notify("Destination must remain inside the launch directory", vim.log.levels.ERROR)
      return
    end
    if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_buf_get_name(buf) ~= source then
      return
    end
    local target = real_dir .. "/" .. vim.fs.basename(source)
    if target == source then
      return
    end
    if uv.fs_lstat(target) or vim.fn.bufnr(target) ~= -1 then
      vim.notify("Destination already exists or is open: " .. target, vim.log.levels.WARN)
      return
    end
    local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
      vim.cmd("write")
    end)
    if not ok then
      vim.notify("Could not save file: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    Snacks.rename.rename_file({
      from = source,
      to = target,
      on_rename = function(_, _, moved)
        if moved then
          vim.notify("Moved file to " .. target)
        end
      end,
    })
  end)
end

return M
