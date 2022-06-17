local handlers = require("plugins.lsp.handlers")
local cmp = require("cmp_nvim_lsp")

local lspinstall_ok, lspinstall = pcall(require, "nvim-lsp-installer")
if not lspinstall_ok then
	return
end

local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_ok then
	return
end

local servers = {
	"clangd",
	"gopls",
	"rust_analyzer",
	"zls",
	"sumneko_lua",
	"jsonls",
}

local settings = {
	ensure_installed = servers,
	ui = {
		keymaps = {
			toggle_server_expand = "<CR>",
			install_server = "i",
			update_server = "u",
			check_server_version = "c",
			update_all_servers = "U",
			check_outdated_servers = "C",
			uninstall_server = "X",
		},
	},

	log_level = vim.log.levels.INFO,
}

lspinstall.setup(settings)

local opts = {}

for _, server in ipairs(servers) do
	opts = {
		on_attach = handlers.on_attach,
		capabilities = cmp.update_capabilities(handlers.capabilities),
		flags = {
			debounce_text_changes = 150,
		},
	}

	if server == "sumneko_lua" then
		local sumneko_lua = require("plugins.lsp.settings.sumneko_lua")
		opts = vim.tbl_deep_extend("force", sumneko_lua, opts)
	end

	if server == "rust_analyzer" then
		local rust_analyzer = require("plugins.lsp.settings.rust_analyzer")
		opts = vim.tbl_deep_extend("force", rust_analyzer, opts)
	end

	if server == "clangd" then
		opts.capabilities.offsetEncoding = { "utf-16" }
	end

	lspconfig[server].setup(opts)
end
