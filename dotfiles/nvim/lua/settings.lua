-- Basic editor settings
vim.opt.number = true              -- Show line numbers
vim.opt.relativenumber = true      -- Relative line numbers
vim.opt.tabstop = 4                -- 4 spaces for tabs (common in C)
vim.opt.shiftwidth = 4             -- 4 spaces for indentation
vim.opt.expandtab = true           -- Convert tabs to spaces
vim.opt.smartindent = true         -- Smart auto-indenting
vim.opt.wrap = false               -- Don't wrap lines
vim.opt.signcolumn = "yes"         -- Always show sign column
vim.opt.termguicolors = false -- True color support

-- Search settings
vim.opt.ignorecase = true          -- Ignore case in search
vim.opt.smartcase = true           -- Unless uppercase is used

-- Split windows
vim.opt.splitbelow = true          -- Horizontal splits below
vim.opt.splitright = true          -- Vertical splits to the right
