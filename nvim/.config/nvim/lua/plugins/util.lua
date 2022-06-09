local M = {}

M.map = function(mode, keys, command)
	vim.g.mapleader = " "
	local opts = { noremap = true, silent = true }
	local cmd = "<cmd>" .. command .. "<enter>"
	vim.api.nvim_set_keymap(mode, keys, cmd, opts)
end

M.map_buf = function(buf, mode, keys, command)
	vim.g.mapleader = " "
	local opts = { noremap = true, silent = true }
	local cmd = "<cmd>" .. command .. "<enter>"
	vim.api.nvim_buf_set_keymap(buf, mode, keys, cmd, opts)
end

M.highlight = function(list)
	for _, v in ipairs(list) do
		vim.cmd("au ColorScheme * hi " .. v.group .. " guibg=" .. v.bg .. " guifg=" .. v.fg .. " gui='NONE'")
	end
end

return M
