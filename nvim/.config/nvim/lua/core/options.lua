local M = {}

local set = vim.opt
vim.cmd("colorscheme onedark")
set.swapfile = false -- Disable use of swapfile for the buffer
set.backup = false -- Disable making a backup file
set.writebackup = false -- Disable making a backup before overwriting a file
set.undofile = true -- Enable persistent undo
set.hlsearch = true -- Highlight all the matches of search pattern
set.hidden = true -- Ignore unsaved buffers
set.mouse = "a" -- Enable mouse support
set.number = true -- Show numberline
set.ruler = true -- Enable ruler
set.shiftwidth = 2 -- Number of space inserted for indentation
set.tabstop = 2 -- Number of space in a tab
set.smartindent = true -- Do auto indenting when starting a new line
set.smartcase = true -- Case sensitivie searching
set.ignorecase = true -- Case insensitive searching
set.scrolloff = 8 -- Number of lines to keep above and below the cursor
set.sidescrolloff = 8 -- Number of columns to keep at the sides of the cursor
set.timeoutlen = 300 -- Length of time to wait for a mapped sequence
set.updatetime = 300 -- Length of time to wait before triggering the plugin
set.expandtab = true -- Enable the use of space in tab
set.history = 100 -- Number of commands to remember in a history table
set.virtualedit = "block"
set.splitbelow = true -- Splitting a new window below the current one
set.splitright = true -- Splitting a new window at the right of the current one
set.signcolumn = "yes" -- Always show the sign column
set.fileencoding = "utf-8" -- File content encoding for the buffer
set.spelllang = "en" -- Support US english
set.clipboard = "unnamedplus" -- Connection to the system clipboard
set.foldmethod = "manual" -- Create folds manually
set.completeopt = { "menuone", "noselect" } -- Options for insert mode completion
set.colorcolumn = "99999" -- Fix for the indentline problem
set.spell = false -- Disable spelling checking and highlighting
set.showmode = false -- Disable showing modes in command line
set.termguicolors = true -- Enable 24-bit RGB color in the TUI
set.cursorline = true -- Highlight the text line of the cursor

set.relativenumber = false -- Show relative numberline
set.wrap = false -- Disable wrapping of lines longer than the width of window
set.conceallevel = 0 -- Show text normally
set.cmdheight = 1 -- Number of screen lines to use for the command line
set.pumheight = 10 -- Height of the pop up menu
set.laststatus = 2 -- laststatus

return M
