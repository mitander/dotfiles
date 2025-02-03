vim.loader.enable()

-- options
vim.opt.mouse = "a"
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.termguicolors = true
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
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.virtualedit = "block"
vim.opt.shell = "/bin/zsh"
vim.opt.synmaxcol = 300
vim.opt.updatetime = 400
vim.opt.gdefault = true
vim.opt.formatoptions = "rqnlj"
vim.opt.jumpoptions = "stack"
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/tmp/undodir"

-- shortmess options
vim.opt.shortmess:append("c")
vim.opt.shortmess:append("a")

-- window options
vim.opt.fillchars = {
    fold = " ",
    vert = "┃",
    horiz = "━",
    horizup = "┻",
    horizdown = "┳",
    vertleft = "┫",
    vertright = "┣",
    verthoriz = "╋",
}

-- disable ftplugins maps
vim.g.no_plugin_maps = true
vim.cmd.filetype({ args = { "plugin", "on" } })
vim.cmd.filetype({ args = { "plugin", "indent", "on" } })

-- leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- disable ex mode
vim.keymap.set("n", "q", "<nop>")

-- expand %% to cwd in command mode
vim.cmd.cabbr({ args = { "<expr>", "%%", "&filetype == 'oil' ? bufname('%')[6:] : expand('%:p:h')" } })

-- just exit pls
vim.cmd.abbr({ args = { "W", "w" } })
vim.cmd.abbr({ args = { "Q", "q" } })
vim.cmd.abbr({ args = { "Wq", "wq" } })
vim.cmd.abbr({ args = { "wQ", "wq" } })
vim.cmd.abbr({ args = { "WQ", "wq" } })

-- bash shortcuts in command line
vim.keymap.set("c", "<c-a>", "<home>")
vim.keymap.set("c", "<c-b>", "<left>")
vim.keymap.set("c", "<c-f>", "<right>")
vim.keymap.set("c", "<c-d>", "<delete>")
vim.keymap.set("c", "<m-b>", "<s-left>")
vim.keymap.set("c", "<m-f>", "<s-right>")
vim.keymap.set("c", "<m-d>", "<s-right><delete>")
vim.keymap.set("c", "<esc>b", "<s-left>")
vim.keymap.set("c", "<esc>f", "<s-right>")
vim.keymap.set("c", "<esc>d", "<s-right><delete>")
vim.keymap.set("c", "<c-g>", "<c-c>")

-- better line navigation
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- keep visual block on indentation
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<tab>", ">gv")
vim.keymap.set("v", "<s-tab>", "<gv")

-- clear highlight
vim.keymap.set("n", "<enter>", vim.cmd.noh)

-- tab navigation
vim.keymap.set("n", "<s-h>", vim.cmd.tabp)
vim.keymap.set("n", "<s-l>", vim.cmd.tabn)
vim.keymap.set("n", "<s-q>", vim.cmd.tabc)
vim.keymap.set("n", "<c-t>", vim.cmd.tabe)

-- compile
vim.keymap.set("n", "<leader><enter>", vim.cmd.make)

-- keep centered on jumps
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- toggle colorcolumn
vim.keymap.set("n", "<leader>.", "<cmd>exec 'set cc=' . (&colorcolumn == '' ? '100' : '')<enter>")

-- replace word globally
vim.keymap.set("n", "<leader>rw", [[*N:s//<c-r>=expand("<cword>")<enter>]])

local group = vim.api.nvim_create_augroup("mitander", {})

-- remove whitespace
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    group = group,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- nopaste on insert leave
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    group = group,
    pattern = "*",
    command = "set nopaste",
})

-- 4 space indentation
vim.api.nvim_create_autocmd({ "FileType" }, {
    group = group,
    pattern = { "zig", "go", "rust", "c", "cpp" },
    command = [[ setlocal tabstop=4 shiftwidth=4 ]],
})

-- no line numbers in terminal
vim.api.nvim_create_autocmd({ "TermOpen" }, {
    group = group,
    pattern = "*",
    command = [[ setlocal norelativenumber nonumber ]],
})

-- quickfix binds
vim.api.nvim_create_autocmd({ "FileType" }, {
    group = group,
    pattern = "qf",
    command = [[
        nnoremap <silent> <buffer> q :close<enter>
        nnoremap <silent> <buffer> <esc> :close<enter>
        nnoremap <silent> <buffer> <enter> <enter>:cclose<enter>
    ]],
})

-- auto chdir to root
local root_cache = {}
vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
        local path = vim.api.nvim_buf_get_name(0)
        if path == "" then
            return
        end
        path = vim.fs.dirname(path)
        if root_cache[path] == nil then
            local root_file = vim.fs.find({ ".git", "Makefile" }, { path = path, upward = true })[1]
            if root_file == nil then
                return
            end
            if path ~= nil then
                root_cache[path] = vim.fs.dirname(root_file)
            end
        end
        vim.fn.chdir(root_cache[path])
    end,
})

-- better cursorline
vim.cmd([[
    au VimEnter * setlocal cursorline
    au WinEnter * setlocal cursorline
    au BufWinEnter * setlocal cursorline
    au WinLeave * setlocal nocursorline
]])

-- bootstrap lazy if needed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- initate lazy
require("lazy").setup({
    install = { colorscheme = { "duskfox" } },
    spec = "mitander",
    change_detection = { notify = false },
    performance = {
        rtp = {
            disabled_plugins = {
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tohtml",
                "tutor",
            },
        },
    },
})
