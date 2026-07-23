local current_terminal = 1
local max_terminals = 9
local opened_terminals = {}

local function terminal_opts(slot)
  return {
    count = slot,
    shell = vim.o.shell,
    win = {
      position = "bottom",
      height = 0.35,
      wo = {
        winbar = "Terminal " .. slot .. " / " .. max_terminals .. " | zsh",
      },
    },
  }
end

local function hide_terminal(slot)
  local terminal = Snacks.terminal.get(nil, vim.tbl_extend("force", terminal_opts(slot), { create = false }))
  if terminal then
    terminal:hide()
  end
end

local function focus_terminal(slot)
  if slot ~= current_terminal then
    hide_terminal(current_terminal)
  end
  current_terminal = slot
  opened_terminals[slot] = true
  Snacks.terminal.focus(nil, terminal_opts(slot))
end

local function toggle_terminal()
  opened_terminals[current_terminal] = true
  Snacks.terminal.toggle(nil, terminal_opts(current_terminal))
end

local function new_terminal()
  for offset = 1, max_terminals do
    local slot = ((current_terminal + offset - 1) % max_terminals) + 1
    if not opened_terminals[slot] then
      focus_terminal(slot)
      return
    end
  end

  focus_terminal(current_terminal % max_terminals + 1)
end

local function next_terminal()
  focus_terminal(current_terminal % max_terminals + 1)
end

local function previous_terminal()
  focus_terminal((current_terminal - 2) % max_terminals + 1)
end

local function terminal_status()
  vim.notify("Terminal " .. current_terminal .. " / " .. max_terminals, vim.log.levels.INFO)
end

vim.keymap.set({ "n", "t" }, "<C-/>", toggle_terminal, { desc = "Toggle Terminal" })
vim.keymap.set({ "n", "t" }, "<C-_>", toggle_terminal, { desc = "Toggle Terminal" })
vim.keymap.set({ "n", "t" }, "<C-t>", new_terminal, { desc = "New terminal tab" })
vim.keymap.set({ "n", "t" }, "<M-t>", new_terminal, { desc = "New terminal tab" })
vim.keymap.set({ "n", "t" }, "<M-]>", next_terminal, { desc = "Next terminal" })
vim.keymap.set({ "n", "t" }, "<M-[>", previous_terminal, { desc = "Previous terminal" })
vim.keymap.set("n", "<leader>tc", toggle_terminal, { desc = "Toggle terminal" })
vim.keymap.set("n", "<leader>tN", new_terminal, { desc = "New terminal tab" })
vim.keymap.set("n", "<leader>tn", next_terminal, { desc = "Next terminal" })
vim.keymap.set("n", "<leader>tp", previous_terminal, { desc = "Previous terminal" })
vim.keymap.set("n", "<leader>tt", terminal_status, { desc = "Current terminal" })

for slot = 1, max_terminals do
  vim.keymap.set("n", "<leader>t" .. slot, function()
    focus_terminal(slot)
  end, { desc = "Terminal " .. slot })
  vim.keymap.set({ "n", "t" }, "<M-" .. slot .. ">", function()
    focus_terminal(slot)
  end, { desc = "Terminal " .. slot })
end

return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      spec = {
        { "<leader>t", group = "Terminal", icon = "" },
      },
    },
  },
}
