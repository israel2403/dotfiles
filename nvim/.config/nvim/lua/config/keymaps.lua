-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Duplicate line (using <leader>D to avoid tmux Ctrl-d conflict and LazyVim <leader>d prefix)
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
