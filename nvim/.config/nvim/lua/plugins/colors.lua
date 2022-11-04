local M = {
	black = "#30302c",
	red = "#cf6a4c",
	green = "#99ad6a",
	yellow = "#d8ad4c",
	blue = "#8197bf",
	magneta = "#8787af",
	cyan = "#71b9f8",
	white = "#e8e8de",
	gray = "#36363b",
	gray2 = "#9c9c9c",
	gray3 = "#39393e",
	gray4 = "#4c4c52",
	none = "NONE",
}

-- Colorscheme
vim.cmd([[colorscheme jellybeans]])

-- General vim highlights
local util = require("plugins.util")
util.highlight({
	{ group = "SpecialKey", bg = M.none, fg = M.yellow },
	{ group = "ModeMsg", bg = M.none, fg = M.yellow },
	{ group = "StatusLine", bg = M.gray, fg = M.white },
	{ group = "StatusLineNC", bg = M.gray, fg = M.gray2 },
	{ group = "CursorLineNr", bg = M.none, fg = M.yellow },
	{ group = "CursorLine", bg = M.none, fg = M.none },
	{ group = "Comment", bg = M.gray3, fg = M.none },
	{ group = "Pmenu", bg = M.none, fg = M.white },
	{ group = "FloatBorder", bg = M.none, fg = M.gray2 },
	{ group = "Normal", bg = M.none, fg = M.none },
	{ group = "LineNr", bg = M.none, fg = M.white },
	{ group = "NonText", bg = M.none, fg = M.white },
	{ group = "VertSplit", bg = M.none, fg = M.gray },
	{ group = "SignColumn", bg = M.none, fg = M.none },
	{ group = "ColorColumn", bg = M.gray3, fg = M.none },
	{ group = "Comment", bg = M.none, fg = M.gray2 },
	{ group = "IndentBlanklineChar", bg = M.none, fg = M.gray4 },
})

return M
