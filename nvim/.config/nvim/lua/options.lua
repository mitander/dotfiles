local opt = vim.opt

opt.guicursor = ""
opt.nu = true
opt.rnu = true
opt.ruler = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.errorbells = false
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.scrolloff = 8
opt.expandtab = true
opt.smartindent = true
opt.smartcase = true
opt.ignorecase = true
opt.showcmd = false
opt.wrap = false
opt.swapfile = false
opt.backup = false
opt.virtualedit = "block"
opt.hlsearch = true
opt.incsearch = true
opt.termguicolors = true
opt.scrolloff = 8
opt.cmdheight = 1
opt.virtualedit = "block"
opt.updatetime = 50
opt.shortmess:append("c")
opt.shell = "/bin/zsh"
opt.splitbelow = true
opt.splitright = true
opt.undofile = true
opt.switchbuf = { "useopen", "usetab" }
opt.undodir = os.getenv("HOME") .. "/.vim/tmp/undodir"
opt.laststatus = 2
opt.statusline = "%{expand('%:p:h:t')}/%t%m %r %= %l/%L"
