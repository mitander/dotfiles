local M = {}

function M.map(mode, keys, command)
	vim.g.mapleader = " "
	local opts = { noremap = true, silent = true }
	local cmd = "<cmd>" .. command .. "<enter>"
	vim.api.nvim_set_keymap(mode, keys, cmd, opts)
end

function M.map_buf(buf, mode, keys, command)
	vim.g.mapleader = " "
	local opts = { noremap = true, silent = true }
	local cmd = "<cmd>" .. command .. "<enter>"
	vim.api.nvim_buf_set_keymap(buf, mode, keys, cmd, opts)
end

function M.highlight(list)
	for _, v in ipairs(list) do
		vim.cmd("au ColorScheme * hi " .. v.group .. " guibg=" .. v.bg .. " guifg=" .. v.fg .. " ")
	end
end

return M
