vim.opt.updatetime = 50
vim.opt.guicursor = ""
vim.opt.termguicolors = true

vim.opt.nu = true
vim.opt.rnu = false
vim.opt.ruler = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.errorbells = false

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.scrolloff = 8
vim.opt.cmdheight = 1

vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.smartcase = true
vim.opt.ignorecase = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.showcmd = false
vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false

vim.opt.virtualedit = "block"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.shell = "/bin/zsh"
vim.opt.isfname:append("@-@")

vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/tmp/undodir"
