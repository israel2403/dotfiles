-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = false
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- SDKMAN Java for jdtls
vim.env.JAVA_HOME = vim.fn.expand("~/.sdkman/candidates/java/current")
vim.env.PATH = vim.env.JAVA_HOME .. "/bin:" .. vim.env.PATH
