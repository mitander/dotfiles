local handlers = require("plugins.lsp.handlers")
local mappings = require("plugins.mappings")
local cmp = require('cmp_nvim_lsp')

local status_installer, lsp_installer = pcall(require, "nvim-lsp-installer")
if not status_installer then
	return
end

local status_config, lspconfig = pcall(require, "lspconfig")
if not status_config then
	return
end

-- Capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.offsetEncoding = { "utf-16" }

for _, server in ipairs(lsp_installer.get_installed_servers()) do
  lspconfig[server.name].setup{
    on_attach = function(client, bufnr)
        mappings.lsp(bufnr)
        handlers.lsp_highlight_document(client)
        handlers.disable_formatting(client)

    end,
    flags = {
      debounce_text_changes = 150,
    },
    capabilities = cmp.update_capabilities(capabilities)
  }
end
