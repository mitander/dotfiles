local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  return
end
local cmp = require'cmp'

require("user.lsp.lsp-installer")
require("user.lsp.handlers").setup()
require("user.lsp.null-ls")
