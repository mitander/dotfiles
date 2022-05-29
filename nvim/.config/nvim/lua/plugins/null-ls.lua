local ok, null_ls = pcall(require, "null-ls")
if not ok then
	return
end

local formatting = null_ls.builtins.formatting

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

null_ls.setup({
	debug = true,
	sources = {
		formatting.clang_format,
		formatting.gofmt,
		formatting.zigfmt,
		formatting.rustfmt,
		formatting.json_tool,
		formatting.stylua,
	},
	on_attach = function(client, bufnr)
            if client.supports_method("textDocument/formatting") then
                print('wtf')
                vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = augroup,
                    buffer = bufnr,
                    callback = function()
                        vim.lsp.buf.format({ bufnr = bufnr })
                    end,
                })
        end
	end,
	offset_encoding = "utf-8",
})
