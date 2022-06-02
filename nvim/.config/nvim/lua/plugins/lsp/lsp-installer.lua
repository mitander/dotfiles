local handlers = require("plugins.lsp.handlers")
local mappings = require("plugins.mappings")
local cmp = require("cmp_nvim_lsp")

local lspinstall_ok, lspinstall = pcall(require, "nvim-lsp-installer")
if not lspinstall_ok then
	return
end

local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_ok then
	return
end

-- Capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.offsetEncoding = { "utf-16" }

for _, server in ipairs(lspinstall.get_installed_servers()) do
	lspconfig[server.name].setup({
		on_attach = function(client, bufnr)
			mappings.lsp(bufnr)
			handlers.lsp_highlight_document(client)
			handlers.disable_formatting(client)
		end,
		flags = {
			debounce_text_changes = 150,
		},
		capabilities = cmp.update_capabilities(capabilities),
	})
end

lspconfig.sumneko_lua.setup({
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
})
