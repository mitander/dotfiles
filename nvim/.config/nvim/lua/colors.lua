-- Colorscheme
vim.cmd([[set background=dark]])

local c = {
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
	gray4 = "#333338",
	none = "NONE",
}

for _, v in ipairs({
	-- vim
	{ group = "SpecialKey", bg = c.none, fg = c.yellow },
	{ group = "ModeMsg", bg = c.none, fg = c.yellow },
	{ group = "StatusLine", bg = c.gray, fg = c.white },
	{ group = "StatusLineNC", bg = c.gray, fg = c.gray2 },
	{ group = "CursorLineNr", bg = c.gray, fg = c.yellow },
	{ group = "CursorLine", bg = c.gray4, fg = c.none },
	{ group = "Pmenu", bg = c.none, fg = c.white },
	{ group = "FloatBorder", bg = c.none, fg = c.white },
	{ group = "Normal", bg = c.none, fg = c.none },
	{ group = "LineNr", bg = c.none, fg = c.white },
	{ group = "NonText", bg = c.none, fg = c.white },
	{ group = "VertSplit", bg = c.none, fg = c.gray },
	{ group = "ColorColumn", bg = c.gray3, fg = c.none },
	{ group = "TabLineFill", bg = c.gray, fg = c.none },
	{ group = "TabLine", bg = c.gray, fg = c.gray2 },
	{ group = "TabLineSel", bg = c.none, fg = c.white },
	{ group = "SignColumn", bg = c.none, fg = c.none },
	{ group = "QuickFixLine", bg = c.none, fg = c.none },

	-- diagnostics
	{ group = "DiagnosticsHint", bg = c.none, fg = c.white },
	{ group = "DiagnosticFloatingHint", bg = c.none, fg = c.white },
	{ group = "DiagnosticSignHint", bg = c.none, fg = c.white },
	{ group = "DiagnosticUnderlineHint", bg = c.none, fg = c.white },
	{ group = "DiagnosticInfo", bg = c.none, fg = c.white },
	{ group = "DiagnosticFloatingInfo", bg = c.none, fg = c.white },
	{ group = "DiagnosticSignInfo", bg = c.none, fg = c.white },
	{ group = "DiagnosticUnderlineInfo", bg = c.none, fg = c.white },
	{ group = "DiagnosticWarn", bg = c.none, fg = c.yellow },
	{ group = "DiagnosticFloatingWarn", bg = c.none, fg = c.yellow },
	{ group = "DiagnosticSignWarn", bg = c.none, fg = c.yellow },
	{ group = "DiagnosticUnderlineWarn", bg = c.none, fg = c.yellow },
	{ group = "DiagnosticError", bg = c.none, fg = c.red },
	{ group = "DiagnosticFloatingError", bg = c.none, fg = c.red },
	{ group = "DiagnosticSignError", bg = c.none, fg = c.red },
	{ group = "DiagnosticUnderlineError", bg = c.none, fg = c.red },

	-- gitsigns
	{ group = "GitSignsAdd", bg = c.none, fg = c.green },
	{ group = "GitSignsDelete", bg = c.none, fg = c.red },
	{ group = "GitSignsChange", bg = c.none, fg = c.yellow },
	{ group = "DiffAdd", bg = c.none, fg = c.green },
	{ group = "DiffChange", bg = c.none, fg = c.yellow },
	{ group = "DiffDelete", bg = c.none, fg = c.red },
	{ group = "GitSignsCurrentLineBlame", bg = c.none, fg = c.gray2 },

	-- nvimtree
	{ group = "NvimTreeSymlink", bg = c.none, fg = c.blue },
	{ group = "NvimTreeFolderName", bg = c.none, fg = c.white },
	{ group = "NvimTreeRootFolder", bg = c.none, fg = c.blue },

	-- lsp
	{ group = "LspDiagnosticsError", bg = c.none, fg = c.red },
	{ group = "LspDiagnosticsWarning", bg = c.none, fg = c.yellow },
	{ group = "LspDiagnosticsInformation", bg = c.none, fg = c.white },
	{ group = "LspDiagnosticsHint", bg = c.none, fg = c.white },

	-- telescope
	{ group = "TelescopeBorder", fg = c.gray2, bg = c.none },

	-- indent
	{ group = "IndentBlanklineChar", bg = c.none, fg = c.gray },

	-- bqf
	{ group = "BqfPreviewRange", bg = c.none, fg = c.none },
	{ group = "BqfPreviewFloat", bg = c.none, fg = c.white },
	{ group = "BqfPreviewBorder", bg = c.none, fg = c.white },

	-- cmp
	{ group = " CmpItemKindKeyword", bg = c.none, fg = c.blue },
	{ group = " CmpItemAbbrDeprecated", bg = c.none, fg = c.red },
	{ group = " CmpItemAbbrMatch", bg = c.none, fg = c.yellow },
	{ group = " CmpItemKindVariable", bg = c.none, fg = c.cyan },
	{ group = " CmpItemKindFunction", bg = c.none, fg = c.green },
}) do
	vim.cmd("hi! " .. v.group .. " guibg=" .. v.bg .. " guifg=" .. v.fg .. " gui='NONE'")
end

-- links
vim.cmd([[
    highlight! link CmpItemAbbrMatchFuzzy CmpItemAbbrMatch
    highlight! link CmpItemKindInterface CmpItemKindVariable
    highlight! link CmpItemKindText CmpItemKindVariable
    highlight! link CmpItemKindMethod CmpItemKindFunction
    highlight! link CmpItemKindProperty CmpItemKindKeyword
    highlight! link CmpItemKindUnit CmpItemKindKeyword
]])
