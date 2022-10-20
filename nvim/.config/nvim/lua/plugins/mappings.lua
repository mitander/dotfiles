local util = require("plugins.util")

local M = {}

M.lsp = function(bufnr)
	util.map_buf(bufnr, "n", "gD", "lua vim.lsp.buf.declaration()")
	util.map_buf(bufnr, "n", "gd", "lua vim.lsp.buf.definition()")
	util.map_buf(bufnr, "n", "<leader>rn", "lua vim.lsp.buf.rename()")
	util.map_buf(bufnr, "n", "gi", "lua vim.lsp.buf.implementation()")
	util.map_buf(bufnr, "n", "go", "lua vim.diagnostic.open_float()")
	util.map_buf(bufnr, "n", "[d", "lua vim.diagnostic.goto_prev()")
	util.map_buf(bufnr, "n", "]d", "lua vim.diagnostic.goto_next()")
	util.map_buf(bufnr, "n", "<leader>d", "lua vim.diagnostic.setloclist()")
	util.map_buf(bufnr, "n", "K", "lua vim.lsp.buf.hover()")
	util.map_buf(bufnr, "n", "ga", "lua vim.lsp.buf.code_action()")
end

M.fzf = function()
	vim.cmd([[command! Files exec (len(system('git rev-parse'))) ? ':FzfLua files' : ':FzfLua git_files']])
	util.map("n", "<c-p>", "Files")
	util.map("n", "<c-f>", "lua require('fzf-lua').live_grep()")
	util.map("n", "gr", "FzfLua lsp_references")
	util.map("n", "<c-b>", "FzfLua buffers")
	util.map("n", "<leader>gs", "FzfLua git_status")
	util.map("n", "<leader>gl", "FzfLua git_commits")
end

M.nvimtree = function()
	util.map("n", "<c-n>", "NvimTreeToggle")
end

M.symbolsoutline = function()
	util.map("n", "<leader>ss", "SymbolsOutline")
end

M.toggleterm = function()
	util.map("n", "<leader>gg", "lua _lazygit_toggle()")
end

M.fugitive = function()
	util.map("n", "gb", "Git blame")
end

M.undotree = function()
	util.map("n", "<leader>u", "UndotreeToggle")
end

M.commentary = function()
	vim.cmd([[map <silent> <space>/ :Commentary<enter>]])
end

M.bufferline = function()
	util.map("n", "<leader>q", "BufferLineCloseRight<enter> <cmd>BufferLineCloseLeft")
end

M.gitsigns = function()
	util.map("n", "gp", "Gitsigns preview_hunk")
	util.map("n", "g.", "Gitsigns toggle_signs")
	util.map("n", "g,", "Gitsigns toggle_current_line_blame")
	util.map("n", "gl", "Gitsigns blame_line")
	util.map("n", "<leader><bs>", "Gitsigns reset_hunk")
end

util.map("n", "<leader><enter>", "make")

return M
