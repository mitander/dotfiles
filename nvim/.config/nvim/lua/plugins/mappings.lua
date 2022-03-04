local M = {}

local opts = { noremap = true, silent = true }
local map = vim.api.nvim_set_keymap

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

return M

