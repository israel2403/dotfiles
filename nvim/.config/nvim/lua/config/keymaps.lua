-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Duplicate line (using <leader>D to avoid Ctrl-d conflicts and LazyVim <leader>d prefix)
vim.keymap.set("n", "<leader>D", '"zyy"zp', { desc = "Duplicate Line" })

-- Disable Shift+C in normal/visual mode.
-- Vim's default C is `c$` (change-to-end-of-line) -- it deletes from the cursor
-- to the line end and drops you into insert mode. Remapped to <Nop> so an
-- accidental Shift+C is a no-op. Use `c$` (or visual-select then `c`)
-- explicitly when that behaviour is actually wanted.
vim.keymap.set({ "n", "x" }, "C", "<Nop>", { desc = "Disabled (was: change to end of line)" })

-- Disable Shift+R in normal/visual mode.
-- Vim's default R enters Replace mode (overwrite characters under the cursor).
-- It's easy to hit by accident when reaching for r (single-char replace) or R
-- when shift is still held. Remapped to <Nop>; if you genuinely need Replace
-- mode, type `:set noinsertmode | exec "normal! gR"` or use single-char `r`.
vim.keymap.set({ "n", "x" }, "R", "<Nop>", { desc = "Disabled (was: Replace mode)" })

-- Notes / Obsidian
local map = vim.keymap.set
local start_cwd = vim.g.nvim_start_cwd or vim.uv.cwd()

local function set_move_line_keymaps(opts)
  opts = opts or {}
  map("n", "J", ":move .+1<CR>==", vim.tbl_extend("force", opts, { desc = "Move line down" }))
  map("n", "K", ":move .-2<CR>==", vim.tbl_extend("force", opts, { desc = "Move line up" }))
  map("x", "J", ":move '>+1<CR>gv=gv", vim.tbl_extend("force", opts, { desc = "Move selection down" }))
  map("x", "K", ":move '<-2<CR>gv=gv", vim.tbl_extend("force", opts, { desc = "Move selection up" }))
end

set_move_line_keymaps()

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("move_line_keymaps_after_lsp_attach", { clear = true }),
  callback = function(event)
    set_move_line_keymaps({ buffer = event.buf })
  end,
})

-- TeamViewer can intercept <Esc>. Use `jk` as a remote-friendly insert-mode
-- escape chord; blink.cmp adds matching completion-dismiss behavior.
map("i", "jk", "<Esc>", { desc = "Exit Insert Mode" })

map("i", "<S-CR>", function()
  local line = vim.api.nvim_get_current_line()
  local indent, leader = line:match("^(%s*)(//)%s?")

  if leader then
    return "<CR>" .. indent .. leader .. " "
  end

  return "<CR>"
end, { expr = true, desc = "Continue Line Comment" })

-- Snacks picker can receive invalid line positions from some Kotlin stdlib LSP targets.
-- Use the built-in LSP jump for definitions so gd still works for those symbols.
map("n", "gd", function()
  vim.lsp.buf.definition({ reuse_win = true })
end, { desc = "Goto Definition" })

map("n", "<leader>ff", function()
  LazyVim.pick("files", { cwd = start_cwd, root = false })()
end, { desc = "Find Files (Start Dir)" })

map("n", "<leader><space>", function()
  LazyVim.pick("files", { cwd = start_cwd, root = false })()
end, { desc = "Find Files (Start Dir)" })

local function maven_spotless_apply()
  vim.cmd("MavenSpotlessApply")
end

map({ "n", "x" }, "<M-f>", maven_spotless_apply, { desc = "Maven Spotless Apply", remap = false })
map("i", "<M-f>", function()
  vim.cmd.stopinsert()
  vim.schedule(maven_spotless_apply)
end, { desc = "Maven Spotless Apply", remap = false })
map({ "n", "x" }, "<F4>", maven_spotless_apply, { desc = "Maven Spotless Apply", remap = false })
map("i", "<F4>", function()
  vim.cmd.stopinsert()
  vim.schedule(maven_spotless_apply)
end, { desc = "Maven Spotless Apply", remap = false })
map({ "n", "x" }, "<leader>Jf", maven_spotless_apply, { desc = "Maven Spotless Apply", remap = false })

map("n", "<leader>nf", "<cmd>Telescope find_files cwd=~/notes<cr>", { desc = "Find notes" })
map("n", "<leader>ng", "<cmd>Telescope live_grep cwd=~/notes<cr>", { desc = "Grep notes" })

map("n", "<leader>ot", "<cmd>Obsidian today<cr>", { desc = "Open today's daily note" })
map("n", "<leader>oy", "<cmd>Obsidian yesterday<cr>", { desc = "Open yesterday's daily note" })
map("n", "<leader>on", "<cmd>Obsidian new<cr>", { desc = "Create new note" })
map("n", "<leader>oq", "<cmd>Obsidian quick_switch<cr>", { desc = "Quick switch note" })
map("n", "<leader>ob", "<cmd>Obsidian backlinks<cr>", { desc = "Show backlinks" })
map("n", "<leader>ol", "<cmd>Obsidian links<cr>", { desc = "Show links in current note" })
map("n", "<leader>or", "<cmd>Obsidian rename<cr>", { desc = "Rename note and backlinks" })
map("n", "<leader>op", "<cmd>Obsidian paste_img<cr>", { desc = "Paste image with obsidian.nvim" })
