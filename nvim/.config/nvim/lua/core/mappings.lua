local M = {}

local opts = { noremap = true, silent = true }
local map = vim.api.nvim_set_keymap

-- Space as leader
map("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

--  Config
map("n", "<leader>so", "<cmd>luafile ~/.config/nvim/init.lua<CR>", opts)
map("n", "<leader>rc", "<cmd>vsp ~/.config/nvim/init.lua<CR>", opts)

-- Navigate windows
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- Resize windows
map("n", "<Up>", "<cmd>resize -2<CR>", opts)
map("n", "<Down>", "<cmd>resize +2<CR>", opts)
map("n", "<Left>", "<cmd>vertical resize -2<CR>", opts)
map("n", "<Right>", "<cmd>vertical resize +2<CR>", opts)

-- Navigate buffers
map("n", "<S-l>", "<cmd>bnext<CR>", opts)
map("n", "<S-h>", "<cmd>bprevious<CR>", opts)

-- Clear highlight
map("n", "<CR>", "<cmd>noh<CR>", opts)

-- NvimTree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", opts)

-- GitSigns
map("n", "<leader>gt", "<cmd>Gitsigns toggle_signs<CR>", opts)
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>", opts)

-- Telescope
map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts) -- use telescope instead of nvim-lsp for references
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", opts)
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", opts)
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", opts)
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", opts)
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", opts)
map("n", "<leader>gs", "<cmd>Telescope git_status<CR>", opts)
map("n", "<leader>h", "<cmd>Telescope help_tags<CR>", opts)

-- Lspsaga
map("n", "gl", "<cmd>Lspsaga show_line_diagnostics<CR>", opts)
map("n", "ca", "<cmd>Lspsaga code_action<CR>", opts)
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", opts)
map("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", opts)
map("n", "gj", "<cmd>Lspsaga diagnostic_jump_next<cr>", opts)
map("n", "gk", "<cmd>Lspsaga diagnostic_jump_prev<cr>", opts)
map("n", "<C-u>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<cr>", opts)
map("n", "<C-d>", "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<cr>", opts)

-- Comment
map("n", "<leader>/", "<cmd>lua require('Comment.api').toggle_current_linewise()<CR>", opts)
map("v", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle_linewise_op(vim.fn.visualmode())<CR>", opts)

-- Terminal
map("n", "<C-t>", "<cmd>ToggleTerm<CR>", opts)
map("t", "<C-t>", "<esc><cmd>ToggleTerm<CR>", opts)

-- SymbolsOutline
map("n", "<leader>ss", "<cmd>SymbolsOutline<CR>", opts)

-- Stay in indent mode
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- Paste without copy
map("v", "p", '"_dP', opts)

-- Move text up and down
map("n", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", opts)
map("n", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", opts)
map("x", "J", "<cmd>move '>+1<CR>gv-gv", opts)
map("x", "K", "<cmd>move '<-2<CR>gv-gv", opts)
map("x", "<A-j>", "<cmd>move '>+1<CR>gv-gv", opts)
map("x", "<A-k>", "<cmd>move '<-2<CR>gv-gv", opts)
map("v", "<A-j>", "<cmd>m .+1<CR>==", opts)
map("v", "<A-k>", "<cmd>m .-2<CR>==", opts)

-- disable this shit
map("n", "Q", "<Nop>", opts)
map("n", "q", "<Nop>", opts)

return M
