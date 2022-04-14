local M = {}

function M.setup()
	local signs = {
		{ name = "DiagnosticSignError", text = "" },
		{ name = "DiagnosticSignWarn", text = "" },
		{ name = "DiagnosticSignHint", text = "" },
		{ name = "DiagnosticSignInfo", text = "" },
	}

	for _, sign in ipairs(signs) do
		vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
	end

	local config = {
		virtual_text = true,
		signs = {
			active = signs,
		},
		update_in_insert = true,
		underline = true,
		severity_sort = true,
		float = {
			focusable = false,
			style = "minimal",
			border = "rounded",
			source = "always",
			header = "",
			prefix = "",
		},
	}

	vim.diagnostic.config(config)

	vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
		border = "rounded",
	})

	vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
		border = "rounded",
	})
end

local function lsp_highlight_document(client)
	if client.resolved_capabilities.document_highlight then
		vim.api.nvim_exec(
			[[
              augroup lsp_document_highlight
                autocmd! * <buffer>
                autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
                autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
              augroup END
            ]],
			false
		)
	end
end

local function disable_formatting(client)
	local disabled_clients = {
		"clangd",
		"gopls",
		"rust_analyzer",
		"zls",
		"sumneko_lua",
		"jsonls",
	}
	for _, client_name in ipairs(disabled_clients) do
		if client.name == client_name then
			client.resolved_capabilities.document_formatting = false
		end
	end
end

M.on_attach = function(client, bufnr)
	require("plugins.mappings").lsp(bufnr)
	lsp_highlight_document(client)
	disable_formatting(client)
end

local status_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not status_ok then
	return
end

M.capabilities = cmp_nvim_lsp.update_capabilities(vim.lsp.protocol.make_client_capabilities())

return M
