local M = {
	black = "#30302c",
	red = "#cf6a4c",
	green = "#99ad6a",
	yellow = "#d8ad4c",
	blue = "#8197bf",
	magneta = "#8787af",
	cyan = "#71b9f8",
	white = "#e8e8de",
	gray = "#4a4a4f",
	gray2 = "#b0b0b0",
	gray3 = "#36363b",
	none = "NONE",
}

-- Colorscheme
vim.cmd([[colorscheme jellybeans]])

-- General vim highlights
local util = require("plugins.util")
util.highlight({
	{ group = "CursorLineNr", bg = M.none, fg = M.yellow },
	{ group = "CursorLine", bg = M.none, fg = M.none },
	{ group = "Comment", bg = M.gray3, fg = M.none },
	{ group = "Pmenu", bg = M.gray3, fg = M.white },
	{ group = "Normal", bg = M.none, fg = M.none },
	{ group = "LineNr", bg = M.none, fg = M.white },
	{ group = "NonText", bg = M.none, fg = M.white },
	{ group = "VertSplit", bg = M.none, fg = M.gray },
	{ group = "SignColumn", bg = M.none, fg = M.none },
	{ group = "ColorColumn", bg = M.gray3, fg = M.none },
	{ group = "StatusLine", bg = M.none, fg = M.none },
	{ group = "StatusLineNC", bg = M.none, fg = M.none },
	{ group = "Comment", bg = M.none, fg = M.gray2 },
	{ group = "IndentBlanklineChar", bg = M.none, fg = M.gray },
})

return M
