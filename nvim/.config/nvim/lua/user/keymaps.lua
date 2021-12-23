local keymap = vim.api.nvim_set_keymap

local opts = { noremap = true, silent = true }
local term_opts = { silent = true }

--Remap space as leader
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)
keymap("v", "p", '"_dP', opts)

-- Move text up and down
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)
keymap("n", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
keymap("n", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)
keymap("v", "<A-j>", ":m .+1<CR>==", opts)
keymap("v", "<A-k>", ":m .-2<CR>==", opts)

-- Clear highlights
keymap("n", "<leader>/", ":noh <CR>", opts)

-- Vim terminal navigation
keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

-- Git
keymap("n", "gs", ":Git<CR>", opts)
keymap("n", "gb", ":Git blame<CR>", opts)
keymap("n", "gl", ":Commits<CR>", opts)

-- Telescope
keymap("n", "<C-t>", ":Telescope <cr>", opts)
keymap("n", "<C-p>", "<cmd>lua require('telescope.builtin')<cr>", opts)
keymap("n", "<C-p>", "<cmd>lua require('telescope.builtin').find_files()<cr>", opts)
keymap("n", "<C-f>", "<cmd>lua require('telescope.builtin').live_grep()<cr>", opts)

-- NvimTree
keymap("n", "<C-n>", "<cmd>lua require 'nvim-tree'.toggle()<cr>", opts)

-- UndoTree
keymap("n", "<leader>u", ":UndoTreeToggle<CR>", opts)

-- Quickfix
keymap("n", "<C-q>", ":lua vim.lsp.diagnostic.set_loclist()<cr>", opts)
