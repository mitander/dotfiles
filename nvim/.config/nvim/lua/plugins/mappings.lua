local util = require("plugins.util")

local M = {}

function M.lsp(bufnr)
	util.map_buf(bufnr, "n", "gD", "lua vim.lsp.buf.declaration()")
	util.map_buf(bufnr, "n", "gd", "lua vim.lsp.buf.definition()")
	util.map_buf(bufnr, "n", "gr", "Telescope lsp_references")
	util.map_buf(bufnr, "n", "<leader>rn", "lua vim.lsp.buf.rename()")
	util.map_buf(bufnr, "n", "gi", "lua vim.lsp.buf.implementation()")
	util.map_buf(bufnr, "n", "go", "lua vim.diagnostic.open_float()")
	util.map_buf(bufnr, "n", "[d", 'lua vim.diagnostic.goto_prev({ border = "rounded" })')
	util.map_buf(bufnr, "n", "]d", 'lua vim.diagnostic.goto_next({ border = "rounded" })')
	util.map_buf(bufnr, "n", "<leader>d", "lua vim.diagnostic.setloclist()")
	util.map_buf(bufnr, "n", "K", "lua vim.lsp.buf.hover()")
	util.map_buf(bufnr, "n", "ga", "lua vim.lsp.buf.code_action()")
end

function M.telescope()
	vim.cmd([[command! Files exec (len(system('git rev-parse'))) ? ':Telescope find_files' : ':Telescope git_files']])
	util.map("n", "<c-p>", "Files ")
	util.map("n", "<c-f>", "Telescope live_grep")
	util.map("n", "<c-b>", "Telescope buffers")
	util.map("n", "<leader>p", "Telescope projects")
	util.map("n", "<leader>gs", "Telescope git_status")
	util.map("n", "<leader>gl", "Telescope git_commits")
end

function M.nvimtree()
	util.map("n", "<c-n>", "NvimTreeToggle")
end

function M.symbolsoutline()
	util.map("n", "<leader>ss", "SymbolsOutline")
end

function M.toggleterm()
	util.map("n", "<leader>gg", "_lazygit_toggle()")
end

function M.fugitive()
	util.map("n", "gb", "Git blame")
end

function M.undotree()
	util.map("n", "<leader>u", "UndotreeToggle")
end

function M.commentary()
	vim.cmd([[map <silent> <leader>/ :Commentary<enter>]])
end

function M.bufferline()
	util.map("n", "<leader>q", "BufferLineCloseRight<enter> <cmd>BufferLineCloseLeft")
end
function M.gitsigns()
	util.map("n", "gp", "Gitsigns preview_hunk")
	util.map("n", "g.", "Gitsigns toggle_signs")
	util.map("n", "gl", "Gitsigns blame_line")
end

return M