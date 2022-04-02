local M = {
	red = "#cf6a4c",
	green = "#99ad6a",
	yellow = "#d8ad4c",
	magneta = "#8197bf",
	cyan = "#71b9f8",
	white = "#e8e8de",
	gray = "#3b3b3b",
	dark_gray = "#30302c",
	light_gray = "#b0b0b0",
	none = "NONE",
}

function M.highlight(list)
	for _, v in ipairs(list) do
		vim.cmd("au ColorScheme * hi " .. v.group .. " guibg=" .. v.bg .. " guifg=" .. v.fg .. " ")
	end
end

-- General vim highlights
local vim_colors = {
	{ group = "Pmenu", bg = M.none, fg = M.white },
	{ group = "Normal", bg = M.none, fg = M.white },
	{ group = "LineNr", bg = M.none, fg = M.white },
	{ group = "NonText", bg = M.none, fg = M.white },
	{ group = "VertSplit", bg = M.none, fg = M.gray },
	{ group = "SignColumn", bg = M.none, fg = M.none },
	{ group = "ColorColumn", bg = M.gray, fg = M.gray },
	{ group = "StatusLine", bg = M.none, fg = M.none },
	{ group = "StatusLineNC", bg = M.none, fg = M.none },
	{ group = "Comment", bg = M.none, fg = M.light_gray },
}

M.highlight(vim_colors)

return M
