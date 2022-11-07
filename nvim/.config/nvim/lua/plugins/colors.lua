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

local highlight = function(list)
	for _, v in ipairs(list) do
		vim.cmd("au ColorScheme * hi " .. v.group .. " guibg=" .. v.bg .. " guifg=" .. v.fg .. " gui='NONE'")
	end
end

-- General vim highlights
highlight({
	{ group = "Fzf1", fg = M.white, bg = M.gray },
	{ group = "Fzf2", fg = M.white, bg = M.gray },
	{ group = "Fzf3", fg = M.white, bg = M.gray },
	{ group = "SpecialKey", bg = M.none, fg = M.yellow },
	{ group = "ModeMsg", bg = M.none, fg = M.yellow },
	{ group = "StatusLine", bg = M.gray, fg = M.white },
	{ group = "StatusLineNC", bg = M.gray, fg = M.gray2 },
	{ group = "CursorLineNr", bg = M.none, fg = M.yellow },
	{ group = "CursorLine", bg = M.none, fg = M.none },
	{ group = "Comment", bg = M.gray3, fg = M.none },
	{ group = "Pmenu", bg = M.gray, fg = M.white },
	{ group = "FloatBorder", bg = M.gray, fg = M.gray2 },
	{ group = "FzfBorder", bg = M.none, fg = M.gray2 },
	{ group = "Normal", bg = M.none, fg = M.none },
	{ group = "LineNr", bg = M.none, fg = M.white },
	{ group = "NonText", bg = M.none, fg = M.white },
	{ group = "VertSplit", bg = M.none, fg = M.gray },
	{ group = "SignColumn", bg = M.none, fg = M.none },
	{ group = "ColorColumn", bg = M.gray3, fg = M.none },
	{ group = "Comment", bg = M.none, fg = M.gray2 },
	{ group = "IndentBlanklineChar", bg = M.none, fg = M.gray4 },
})

M.tabs = function()
	highlight({
		{ group = "TabLineFill", bg = M.gray, fg = M.none },
		{ group = "TabLine", bg = M.gray, fg = M.gray2 },
		{ group = "TabLineSel", bg = M.none, fg = M.white },
	})
end

M.diagnostics = function()
	highlight({
		{ group = "DiagnosticsHint", bg = M.none, fg = M.white },
		{ group = "DiagnosticFloatingHint", bg = M.none, fg = M.white },
		{ group = "DiagnosticSignHint", bg = M.none, fg = M.white },
		{ group = "DiagnosticUnderlineHint", bg = M.none, fg = M.white },
		{ group = "DiagnosticInfo", bg = M.none, fg = M.white },
		{ group = "DiagnosticFloatingInfo", bg = M.none, fg = M.white },
		{ group = "DiagnosticSignInfo", bg = M.none, fg = M.white },
		{ group = "DiagnosticUnderlineInfo", bg = M.none, fg = M.white },
		{ group = "DiagnosticWarn", bg = M.none, fg = M.yellow },
		{ group = "DiagnosticFloatingWarn", bg = M.none, fg = M.yellow },
		{ group = "DiagnosticSignWarn", bg = M.none, fg = M.yellow },
		{ group = "DiagnosticUnderlineWarn", bg = M.none, fg = M.yellow },
		{ group = "DiagnosticError", bg = M.none, fg = M.red },
		{ group = "DiagnosticFloatingError", bg = M.none, fg = M.red },
		{ group = "DiagnosticSignError", bg = M.none, fg = M.red },
		{ group = "DiagnosticUnderlineError", bg = M.none, fg = M.red },
	})
end

M.gitsigns = function()
	highlight({
		{ group = "GitSignsAdd", bg = M.none, fg = M.green },
		{ group = "GitSignsDelete", bg = M.none, fg = M.red },
		{ group = "GitSignsChange", bg = M.none, fg = M.yellow },
		{ group = "DiffAdd", bg = M.none, fg = M.green },
		{ group = "DiffChange", bg = M.none, fg = M.yellow },
		{ group = "DiffDelete", bg = M.none, fg = M.red },
		{ group = "GitSignsCurrentLineBlame", bg = M.none, fg = M.gray2 },
	})
end

M.nvimtree = function()
	highlight({
		{ group = "NvimTreeSymlink", bg = M.none, fg = M.blue },
		{ group = "NvimTreeFolderName", bg = M.none, fg = M.white },
		{ group = "NvimTreeRootFolder", bg = M.none, fg = M.blue },
		{ group = "LspDiagnosticsError", bg = M.none, fg = M.red },
		{ group = "LspDiagnosticsWarning", bg = M.none, fg = M.yellow },
		{ group = "LspDiagnosticsInformation", bg = M.none, fg = M.white },
		{ group = "LspDiagnosticsHint", bg = M.none, fg = M.white },
	})
end

return M
