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
vim.opt.synmaxcol = 300
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.gdefault = true
vim.opt.formatoptions = "rqnlj"
vim.opt.jumpoptions = "stack"
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/tmp/undodir"
vim.opt.showmode = false
vim.opt.shortmess:append("casI")

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

-- disable built-in plugins
vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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

-- comment line / visual selection
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, silent = true })
vim.keymap.set("v", "<leader>/", "gc", { remap = true, silent = true })

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
vim.keymap.set("n", "<leader>.", function()
    local cc = vim.opt_local.colorcolumn:get()
    if #cc > 0 and cc[1] == "100" then
        vim.opt_local.colorcolumn = ""
    else
        vim.opt_local.colorcolumn = "100"
    end
end, { desc = "Toggle colorcolumn" })

-- replace word globally
vim.keymap.set("n", "<leader>rw", [[*N:s//<c-r>=expand("<cword>")<enter>]])

local group = vim.api.nvim_create_augroup("mitander", { clear = true })

-- nopaste on insert leave
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    group = group,
    pattern = "*",
    callback = function()
        vim.opt.paste = false
    end,
})

-- 4 space indentation
vim.api.nvim_create_autocmd({ "FileType" }, {
    group = group,
    pattern = { "zig", "go", "rust", "c", "cpp" },
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})

-- no line numbers in terminal
vim.api.nvim_create_autocmd({ "TermOpen" }, {
    group = group,
    pattern = "*",
    callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
    end,
})

-- quickfix binds
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "qf",
    callback = function()
        vim.keymap.set("n", "q", ":close<cr>", { buffer = true, silent = true })
        vim.keymap.set("n", "<esc>", ":close<cr>", { buffer = true, silent = true })
        vim.keymap.set("n", "<enter>", "<enter>:cclose<cr>", { buffer = true, silent = true })
    end,
})

-- better cursorline
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
    group = group,
    callback = function()
        vim.opt_local.cursorline = true
    end,
})

vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    callback = function()
        vim.opt_local.cursorline = false
    end,
})

-- auto chdir to root
local root_cache = {}
vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
        local path = vim.api.nvim_buf_get_name(0)
        if path == "" or vim.bo.buftype ~= "" or path:match("^%w+://") then
            return
        end
        if root_cache[path] == nil then
            root_cache[path] = vim.fs.root(path, { ".git", "Makefile" }) or false
        end
        if root_cache[path] then
            vim.api.nvim_set_current_dir(root_cache[path])
        end
    end,
})

-- bootstrap lazy if needed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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
    install = { colorscheme = {} },
    spec = "mitander.plugins",
    change_detection = { notify = false },
    performance = {
        cache = {
            enabled = true,
        },
        rtp = {
            disabled_plugins = {
                "gzip",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
                "netrwPlugin",
            },
        },
    },
})
