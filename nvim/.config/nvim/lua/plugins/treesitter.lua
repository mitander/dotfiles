local ok, configs = pcall(require, "nvim-treesitter.configs")
if not ok then
	return
end

configs.setup({
	ensure_installed = { "go", "zig", "rust", "lua", "vim", "python", "c", "cpp", "javascript", "typescript" },
	sync_install = false,
	autopairs = {
		enable = true,
	},
	highlight = {
		enable = true,
		disable = { "" },
		additional_vim_regex_highlighting = true,
	},
	context_commentstring = {
		enable = true,
		enable_autocmd = false,
	},
})
