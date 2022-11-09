local ok, indent_blankline = pcall(require, "indent_blankline")
if not ok then
	print("error: could not load indent_blankline")
	return
end

vim.g.indent_blankline_buftype_exclude = {
	"nofile",
	"terminal",
	"lsp-installer",
	"lspinfo",
	"fzf",
}

vim.g.indent_blankline_filetype_exclude = {
	"help",
	"packer",
	"NvimTree",
	"fzf",
}

vim.g.indent_blankline_context_patterns = {
	"class",
	"return",
	"function",
	"method",
	"^if",
	"^while",
	"jsx_element",
	"^for",
	"^object",
	"^table",
	"block",
	"arguments",
	"if_statement",
	"else_clause",
	"jsx_element",
	"jsx_self_closing_element",
	"try_statement",
	"catch_clause",
	"import_statement",
	"operation_type",
}

indent_blankline.setup({
	show_current_context = false,
	show_current_context_start = false,
	use_treesitter = true,
	show_trailing_blankline_indent = false,
	show_first_indent_level = true,
	char = "|",
})
