-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.nvim_start_cwd = vim.uv.cwd()

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UI & DISPLAY OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.opt.relativenumber = false
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- Line numbers
vim.opt.number = true
vim.opt.numberwidth = 4

-- Cursor options
vim.opt.cursorline = true
vim.opt.cursorcolumn = false

-- Display options for better readability with Tokyo Night theme
vim.opt.background = "dark"
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes:2"

-- Improved visibility
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.cmdheight = 1
vim.opt.pumheight = 20

-- Status line configuration
vim.opt.showmode = false
vim.opt.showcmd = true
vim.opt.laststatus = 3

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- EDITOR OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Indentation (2 spaces by default, matches most web projects)
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Search options
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Undo/Backup
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.swapfile = false

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- WINDOW & SPLIT OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.equalalways = true

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GHOSTTY TERMINAL INTEGRATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Support for true color in terminal
vim.g.t_Co = 256
vim.env.COLORTERM = "truecolor"

-- Mouse support for Ghosty
vim.opt.mouse = "a"
vim.opt.mousemodel = "extend"

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ENVIRONMENT & TOOL INTEGRATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Use zsh for Neovim terminal buffers, including Snacks <Ctrl/> terminal.
vim.opt.shell = "/usr/bin/zsh"

-- SDKMAN Java for jdtls
vim.env.JAVA_HOME = vim.fn.expand("~/.sdkman/candidates/java/current")
vim.env.PATH = vim.env.JAVA_HOME .. "/bin:" .. vim.env.PATH

-- NVM Node.js support
local nvm_dir = os.getenv("HOME") .. "/.nvm"
if vim.fn.isdirectory(nvm_dir) == 1 then
  vim.env.PATH = nvm_dir .. "/versions/node/*/bin:" .. vim.env.PATH
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- OMARCHY THEME HOTRELOAD SUPPORT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Allow dynamic theme reloading
vim.opt.autoread = true
vim.opt.autowrite = true
