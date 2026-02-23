-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_php_lsp = "intelephense"

-- Disable swapfiles
vim.opt.swapfile = false -- disable swap files

-- Prettier requires local config to run
vim.g.lazyvim_prettier_needs_config = false
