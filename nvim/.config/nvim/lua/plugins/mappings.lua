local M = {}

local map = function(mode, keys, command)
	vim.g.mapleader = " "
	local opts = { noremap = true, silent = true }
	local cmd = "<cmd>" .. command .. "<enter>"
	vim.api.nvim_set_keymap(mode, keys, cmd, opts)
end

local map_buf = function(buf, mode, keys, command)
	vim.g.mapleader = " "
	local opts = { noremap = true, silent = true }
	local cmd = "<cmd>" .. command .. "<enter>"
	vim.api.nvim_buf_set_keymap(buf, mode, keys, cmd, opts)
end

M.lsp = function(bufnr)
	map_buf(bufnr, "n", "gr", "lua vim.lsp.buf.references()")
	map_buf(bufnr, "n", "gd", "lua vim.lsp.buf.definition()")
	map_buf(bufnr, "n", "<leader>rn", "lua vim.lsp.buf.rename()")
	map_buf(bufnr, "n", "gi", "lua vim.lsp.buf.implementation()")
	map_buf(bufnr, "n", "go", "lua vim.diagnostic.open_float()")
	map_buf(bufnr, "n", "[d", "lua vim.diagnostic.goto_prev()")
	map_buf(bufnr, "n", "]d", "lua vim.diagnostic.goto_next()")
	map_buf(bufnr, "n", "<leader>d", "lua vim.diagnostic.setloclist()")
	map_buf(bufnr, "n", "K", "lua vim.lsp.buf.hover()")
	map_buf(bufnr, "n", "ga", "lua vim.lsp.buf.code_action()")
end

M.nvimtree = function()
	map("n", "<c-n>", "NvimTreeToggle")
end

M.toggleterm = function()
	map("n", "<leader>gg", "lua _lazygit_toggle()")
end

M.fugitive = function()
	map("n", "gb", "Git blame")
end

M.undotree = function()
	map("n", "<leader>u", "UndotreeToggle")
end

M.commentary = function()
	vim.cmd([[map <silent> <space>/ :Commentary<enter>]])
end

M.bufferline = function()
	map("n", "<leader>q", "BufferLineCloseRight<enter> <cmd>BufferLineCloseLeft")
end

M.gitsigns = function()
	map("n", "gp", "Gitsigns preview_hunk")
	map("n", "g.", "Gitsigns toggle_signs")
	map("n", "g,", "Gitsigns toggle_current_line_blame")
	map("n", "gl", "Gitsigns blame_line")
	map("n", "<leader><bs>", "Gitsigns reset_hunk")
end

return M
