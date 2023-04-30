vim.opt.guicursor = ""
vim.opt.nu = true
vim.opt.rnu = true
vim.opt.ruler = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.errorbells = false
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.scrolloff = 8
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.showcmd = false
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.virtualedit = "block"
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.cmdheight = 1
vim.opt.virtualedit = "block"
vim.opt.updatetime = 50
vim.opt.shortmess:append "c"
vim.opt.shell = "/bin/zsh"
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.switchbuf = { "useopen", "usetab" }
vim.opt.undodir = os.getenv "HOME" .. "/.vim/tmp/undodir"
vim.opt.laststatus = 2
vim.opt.showmode = false
vim.opt.ruler = false
