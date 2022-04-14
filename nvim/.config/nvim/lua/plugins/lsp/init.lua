local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
	return
end

require("plugins.lsp.lsp-installer")
require("plugins.lsp.handlers").setup()

local util = require("plugins.util")
local colors = require("plugins.colors")

util.highlight({
	{ group = "DiagnosticsHint", bg = colors.none, fg = colors.white },
	{ group = "DiagnosticFloatingHint", bg = colors.none, fg = colors.white },
	{ group = "DiagnosticSignHint", bg = colors.none, fg = colors.white },
	{ group = "DiagnosticUnderlineHint", bg = colors.none, fg = colors.white },
	{ group = "DiagnosticInfo", bg = colors.none, fg = colors.white },
	{ group = "DiagnosticFloatingInfo", bg = colors.none, fg = colors.white },
	{ group = "DiagnosticSignInfo", bg = colors.none, fg = colors.white },
	{ group = "DiagnosticUnderlineInfo", bg = colors.none, fg = colors.white },
	{ group = "DiagnosticWarn", bg = colors.none, fg = colors.yellow },
	{ group = "DiagnosticFloatingWarn", bg = colors.none, fg = colors.yellow },
	{ group = "DiagnosticSignWarn", bg = colors.none, fg = colors.yellow },
	{ group = "DiagnosticUnderlineWarn", bg = colors.none, fg = colors.yellow },
	{ group = "DiagnosticError", bg = colors.none, fg = colors.red },
	{ group = "DiagnosticFloatingError", bg = colors.none, fg = colors.red },
	{ group = "DiagnosticSignError", bg = colors.none, fg = colors.red },
	{ group = "DiagnosticUnderlineError", bg = colors.none, fg = colors.red },
})
