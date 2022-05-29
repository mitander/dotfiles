local ok, null_ls = pcall(require, "null-ls")
if not ok then
	return
end

local formatting = null_ls.builtins.formatting

null_ls.setup({
	debug = false,
	sources = {
		formatting.clang_format,
		formatting.gofmt,
		formatting.zigfmt,
		formatting.rustfmt,
		formatting.json_tool,
		formatting.stylua,
	},
	on_attach = function()
		vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()")
	end,
	offset_encoding = "utf-8",
})
