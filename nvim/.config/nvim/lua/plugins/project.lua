local status_ok, project = pcall(require, "project_nvim")
if not status_ok then
	return
end

project.setup({
	manual_mode = false,
	detection_methods = { "lsp", "pattern" },
	patterns = { ".git/", ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", ".gitignore" },
	ignore_lsp = {},
	exclude_dirs = {},
	show_hidden = true,
	silent_chdir = true,
	datapath = vim.fn.stdpath("data"),
})
