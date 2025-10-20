-- Neovim Configuration File (init.lua)
-- Location: $HOME\AppData\Local\nvim\init.lua

-- Basic Settings
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Show relative line numbers
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.shiftwidth = 2          -- Number of spaces for indentation
vim.opt.tabstop = 2             -- Number of spaces a tab represents
vim.opt.smartindent = true      -- Smart indentation
vim.opt.wrap = true             -- Don't wrap lines
vim.opt.ignorecase = true       -- Case insensitive search
vim.opt.smartcase = true        -- Case sensitive if uppercase is used
vim.opt.hlsearch = true         -- Highlight search results
vim.opt.incsearch = true        -- Incremental search
vim.opt.termguicolors = true    -- Enable 24-bit RGB colors
vim.opt.scrolloff = 8           -- Keep 8 lines visible above/below cursor
vim.opt.sidescrolloff = 8       -- Keep 8 columns visible left/right of cursor

-- Key Mappings
vim.g.mapleader = " "           -- Set space as leader key

-- Delete word backwards in insert mode (Ctrl+Backspace)
vim.keymap.set('i', '<C-BS>', '<C-w>')
vim.keymap.set('i', '<C-H>', '<C-w>')  -- Fallback for terminals that send Ctrl+H

-- Clear search highlighting
vim.keymap.set('n', '<leader>h', ':nohlsearch<CR>')

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Save file
vim.keymap.set('n', '<leader>w', ':w<CR>')

-- Quit
vim.keymap.set('n', '<leader>q', ':q<CR>')