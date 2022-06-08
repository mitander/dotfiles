local ok, project = pcall(require, "project_nvim")
if not ok then
    return
end

project.setup({
    manual_mode = false,
    detection_methods = { "lsp", "pattern" },
    patterns = { ".git/", ".git", "Makefile", "package.json", ".gitignore" },
    ignore_lsp = {},
    exclude_dirs = {},
    show_hidden = true,
    silent_chdir = true,
    datapath = vim.fn.stdpath("data"),
})
