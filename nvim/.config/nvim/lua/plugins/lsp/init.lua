local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  return
end

require "plugins.lsp.lsp-installer"
require("plugins.lsp.handlers").setup()

local colors_ok, colors = pcall(require, "plugins.colors")
if not colors_ok then
  return
end

-- Hint
colors.highlight("DiagnosticHint", colors.none, colors.white)
colors.highlight("DiagnosticFloatingHint", colors.none, colors.white)
colors.highlight("DiagnosticSignHint", colors.none, colors.white)
colors.highlight("DiagnosticUnderlineHint", colors.none, colors.white)

-- Info
colors.highlight("DiagnosticInfo", colors.none, colors.white)
colors.highlight("DiagnosticFloatingInfo", colors.none, colors.white)
colors.highlight("DiagnosticSignInfo", colors.none, colors.white)
colors.highlight("DiagnosticUnderlineInfo", colors.none, colors.white)

--Warn
colors.highlight("DiagnosticWarn", colors.none, colors.yellow)
colors.highlight("DiagnosticFloatingWarn", colors.none, colors.yellow)
colors.highlight("DiagnosticSignWarn", colors.none, colors.yellow)
colors.highlight("DiagnosticUnderlineWarn", colors.none, colors.yellow)

-- Error
colors.highlight("DiagnosticError", colors.none, colors.red)
colors.highlight("DiagnosticFloatingError", colors.none, colors.red)
colors.highlight("DiagnosticSignError", colors.none, colors.red)
colors.highlight("DiagnosticUnderlineError", colors.none, colors.red)

