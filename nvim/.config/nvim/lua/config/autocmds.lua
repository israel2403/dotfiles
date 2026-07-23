-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("manual_comment_continuation", { clear = true }),
  callback = function()
    vim.opt_local.formatoptions:remove("r")
  end,
})

-- Auto-save like IntelliJ: save on focus lost, buffer leave, and after text changes
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave", "InsertLeave", "TextChanged" }, {
  group = vim.api.nvim_create_augroup("autosave", { clear = true }),
  callback = function(event)
    local buf = event.buf
    if vim.bo[buf].modified and vim.bo[buf].buftype == "" and vim.fn.bufname(buf) ~= "" then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent! write")
      end)
    end
  end,
})

local math_symbols = {
  [";0"] = "⁰",
  [";1"] = "¹",
  [";2"] = "²",
  [";3"] = "³",
  [";4"] = "⁴",
  [";5"] = "⁵",
  [";6"] = "⁶",
  [";7"] = "⁷",
  [";8"] = "⁸",
  [";9"] = "⁹",
  [";N"] = "ℕ",
  [";Z"] = "ℤ",
  [";Q"] = "ℚ",
  [";R"] = "ℝ",
  [";C"] = "ℂ",
  [";in"] = "∈",
  [";elem"] = "∈",
  [";notin"] = "∉",
  [";sub"] = "⊆",
  [";subset"] = "⊆",
  [";psub"] = "⊂",
  [";sup"] = "⊇",
  [";supset"] = "⊇",
  [";psup"] = "⊃",
  [";empty"] = "∅",
  [";cup"] = "∪",
  [";union"] = "∪",
  [";cap"] = "∩",
  [";inter"] = "∩",
  [";diff"] = "∖",
  [";setminus"] = "∖",
  [";prod"] = "×",
  [";pow"] = "℘",
  [";and"] = "∧",
  [";or"] = "∨",
  [";not"] = "¬",
  [";all"] = "∀",
  [";ex"] = "∃",
  [";iff"] = "↔",
  [";->"] = "→",
  [";<-"] = "←",
  [";<->"] = "↔",
  [";=>"] = "⇒",
  [";<="] = "≤",
  [";>="] = "≥",
  [";!="] = "≠",
}

local math_symbol_filetypes = {
  lean = true,
  markdown = true,
  plaintex = true,
  tex = true,
  text = true,
}

local function set_math_symbol_maps(buf)
  if vim.b[buf].math_symbol_maps_set then
    return
  end

  if not math_symbol_filetypes[vim.bo[buf].filetype] then
    return
  end

  for lhs, rhs in pairs(math_symbols) do
    vim.keymap.set("i", lhs, rhs, {
      buffer = buf,
      desc = "Math symbol " .. lhs .. " -> " .. rhs,
    })
  end
  vim.b[buf].math_symbol_maps_set = true
end

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("discrete_math_abbreviations", { clear = true }),
  callback = function(event)
    set_math_symbol_maps(event.buf)
  end,
})
