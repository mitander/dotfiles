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

-- Custom diagnostics colors
-- Hint
colors.hl("DiagnosticHint", colors.none, colors.white)
colors.hl("DiagnosticFloatingHint", colors.none, colors.white)
colors.hl("DiagnosticSignHint", colors.none, colors.white)
colors.hl("DiagnosticUnderlineHint", colors.none, colors.white)
-- Info
colors.hl("DiagnosticInfo", colors.none, colors.white)
colors.hl("DiagnosticFloatingInfo", colors.none, colors.white)
colors.hl("DiagnosticSignInfo", colors.none, colors.white)
colors.hl("DiagnosticUnderlineInfo", colors.none, colors.white)
--Warn
colors.hl("DiagnosticWarn", colors.none, colors.yellow)
colors.hl("DiagnosticFloatingWarn", colors.none, colors.yellow)
colors.hl("DiagnosticSignWarn", colors.none, colors.yellow)
colors.hl("DiagnosticUnderlineWarn", colors.none, colors.yellow)
-- Error
colors.hl("DiagnosticError", colors.none, colors.red)
colors.hl("DiagnosticFloatingError", colors.none, colors.red)
colors.hl("DiagnosticSignError", colors.none, colors.red)
colors.hl("DiagnosticUnderlineError", colors.none, colors.red)

