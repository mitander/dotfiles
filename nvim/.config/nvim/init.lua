-- Files and undo
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undodir = os.getenv("HOME") .. "/.vim/tmp/undodir"

-- Editing and indentation
vim.opt.mouse = "a"
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.formatoptions = "rqnlj"
vim.opt.virtualedit = "block"
vim.opt.jumpoptions = "stack"

-- Search and substitution
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.gdefault = true

-- Display and windows
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.termguicolors = true
vim.opt.ruler = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.cmdheight = 1
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.errorbells = false
vim.opt.showcmd = false
vim.opt.showmode = false
vim.opt.shortmess:append("casI")

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

-- Timing and performance
vim.opt.synmaxcol = 300
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
require("mitander.buffer_limits").setup_treesitter()

-- Built-in plugins
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

-- Command shell
-- fzf-lua builds POSIX command strings and spawns sh. Don't inherit Fish quoting.
vim.opt.shell = "/bin/sh"

-- Command-line shortcuts
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set("n", "q", "<nop>")

-- Expand %% to the current file's directory.
vim.cmd.cabbr({
    args = { "<expr>", "%%", "&filetype == 'oil' ? bufname('%')[6:] : expand('%:p:h')" },
})

-- Accept common write/quit capitalization mistakes.
vim.cmd.abbr({ args = { "W", "w" } })
vim.cmd.abbr({ args = { "Q", "q" } })
vim.cmd.abbr({ args = { "Wq", "wq" } })
vim.cmd.abbr({ args = { "wQ", "wq" } })
vim.cmd.abbr({ args = { "WQ", "wq" } })

-- Use familiar shell navigation while editing commands.
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
vim.keymap.set("c", "<enter>", function()
    local command_type = vim.fn.getcmdtype()
    if command_type ~= "/" and command_type ~= "?" then
        return "<cr>"
    end

    local pattern = vim.fn.getcmdline()
    if pattern == "" then
        return "<cr>"
    end

    local flags = command_type == "?" and "bn" or "n"
    local ok, line = pcall(vim.fn.search, pattern, flags)
    if ok and line == 0 then
        pcall(vim.fn.histadd, command_type, pattern)
        vim.fn.setreg("/", pattern)
        return "<c-c>"
    end

    return "<cr>"
end, { expr = true, desc = "Cancel failed searches silently" })

-- Editing keybindings
-- Move by displayed lines when wrapping.
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- Comment the current line or selection.
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, silent = true })
vim.keymap.set("v", "<leader>/", "gc", { remap = true, silent = true })

-- Keep the selection while changing indentation.
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("v", "<tab>", ">gv")
vim.keymap.set("v", "<s-tab>", "<gv")

-- Clear search highlighting.
vim.keymap.set("n", "<enter>", vim.cmd.noh)

-- Tab navigation
vim.keymap.set("n", "<s-h>", vim.cmd.tabp)
vim.keymap.set("n", "<s-l>", vim.cmd.tabn)
vim.keymap.set("n", "<s-q>", vim.cmd.tabc)
vim.keymap.set("n", "<c-t>", vim.cmd.tabe)

-- Build and navigation
vim.keymap.set("n", "<leader><enter>", vim.cmd.make)

-- Keep the cursor centered after jumps.
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<c-d>", "<c-d>zz")
vim.keymap.set("n", "<c-u>", "<c-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Toggle the 100-column guide.
vim.keymap.set("n", "<leader>.", function()
    -- Neovim's dynamic option accessor supports get(), but its metadata misses this field.
    ---@diagnostic disable-next-line: undefined-field
    local columns = vim.opt_local.colorcolumn:get()
    if #columns > 0 and columns[1] == "100" then
        vim.opt_local.colorcolumn = ""
    else
        vim.opt_local.colorcolumn = "100"
    end
end, { desc = "Toggle colorcolumn" })

-- Start a substitution for the word under the cursor.
vim.keymap.set("n", "<leader>rw", [[*N:s//<c-r>=expand("<cword>")<enter>]])

-- Startup and welcome
local group = vim.api.nvim_create_augroup("mitander", { clear = true })

-- Show a calm welcome without changing the editing buffer or its window options.
local welcome_messages = {
    "slow down and make the small thing work",
    "boring code is a kindness",
    "fun counts",
    "it is only computer",
    "technology is cool and so are small steps",
    "read the error, not your fears",
    "make it work, make it clear, then stop",
    "pragmatic beats impressive",
    "touch grass, then touch keys",
    "ship the simple thing",
    "computers are toys and tools",
    "leave the code calmer than you found it",
    "every bug is a little door",
    "small programs are real programs",
    "enjoy the machine",
    "build gently",
    "keep the sharp edges kind",
    "the terminal is a place to play",
}

local function show_welcome()
    if
        vim.fn.argc() > 0
        or vim.api.nvim_buf_get_name(0) ~= ""
        or vim.api.nvim_buf_line_count(0) ~= 1
    then
        return
    end
    if vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] ~= "" then
        return
    end

    local source_buf = vim.api.nvim_get_current_buf()
    math.randomseed(vim.uv.hrtime())
    local message = welcome_messages[math.random(#welcome_messages)]
    local width = vim.fn.strdisplaywidth(message)

    local welcome_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(welcome_buf, 0, -1, false, { message })
    vim.bo[welcome_buf].modifiable = false

    local welcome_win = vim.api.nvim_open_win(welcome_buf, false, {
        relative = "editor",
        row = math.max(math.floor((vim.o.lines - 1) / 2), 0),
        col = math.max(math.floor((vim.o.columns - width) / 2), 0),
        width = width,
        height = 1,
        style = "minimal",
        focusable = false,
        noautocmd = true,
        zindex = 1,
    })
    vim.wo[welcome_win].winhighlight = "Normal:WelcomeMessage,NormalFloat:WelcomeMessage"

    local function dismiss_welcome()
        if vim.api.nvim_win_is_valid(welcome_win) then
            vim.api.nvim_win_close(welcome_win, true)
        end
    end

    vim.api.nvim_create_autocmd(
        { "InsertEnter", "CmdlineEnter", "BufLeave", "WinLeave", "BufWipeout" },
        {
            group = group,
            buffer = source_buf,
            once = true,
            callback = dismiss_welcome,
        }
    )
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        once = true,
        callback = dismiss_welcome,
    })
end

local function apply_welcome_highlight()
    vim.api.nvim_set_hl(0, "WelcomeMessage", { fg = "#a3be8c", italic = true })
end

apply_welcome_highlight()
vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = apply_welcome_highlight,
})
vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = show_welcome,
})

-- Buffer and window behavior
-- Reset paste mode after leaving insert mode.
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    group = group,
    pattern = "*",
    callback = function()
        vim.opt.paste = false
    end,
})

-- Keep four-space indentation for these filetypes.
vim.api.nvim_create_autocmd({ "FileType" }, {
    group = group,
    pattern = { "zig", "go", "rust", "c", "cpp" },
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})

-- Hide line numbers in terminal buffers.
vim.api.nvim_create_autocmd({ "TermOpen" }, {
    group = group,
    pattern = "*",
    callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
    end,
})

-- Close quickfix after selecting a result.
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "qf",
    callback = function()
        vim.keymap.set("n", "q", ":close<cr>", { buffer = true, silent = true })
        vim.keymap.set("n", "<esc>", ":close<cr>", { buffer = true, silent = true })
        vim.keymap.set("n", "<enter>", "<enter>:cclose<cr>", { buffer = true, silent = true })
    end,
})

-- Show the cursor line only in the focused window.
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

-- Project directory
-- Cache root discovery for each file.
local root_cache = {}
vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function()
        if vim.env.NVIM_SCREENSHOT_MODE == "1" then
            return
        end

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

-- Tmux navigation
-- Claim pane navigation for nested editors such as `git commit`. Dedicated edit
-- panes are already identified by their workspace role; this covers editors
-- launched from ordinary shell panes without adding work to the keypress path.
local function set_tmux_navigation(owned)
    if not vim.env.TMUX_PANE or vim.fn.executable("tmux") ~= 1 then
        return
    end

    local command
    if owned then
        command = {
            "tmux",
            "set-option",
            "-pq",
            "-t",
            vim.env.TMUX_PANE,
            "@workspace_navigation",
            "application",
        }
    else
        command = { "tmux", "set-option", "-pu", "-t", vim.env.TMUX_PANE, "@workspace_navigation" }
    end

    vim.fn.system(command)
end

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
        set_tmux_navigation(true)
    end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
        set_tmux_navigation(false)
    end,
})

-- Plugin loading
-- Restart Neovim after configuration changes. Plugin setup is not safely reloadable.
local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_init = lazy_path .. "/lua/lazy/init.lua"
if not vim.uv.fs_stat(lazy_init) then
    vim.fn.delete(lazy_path, "rf")
    local clone_output = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazy_path,
    })
    if vim.v.shell_error ~= 0 then
        error("Failed to clone lazy.nvim:\n" .. clone_output)
    end
end
vim.opt.rtp:prepend(lazy_path)

require("lazy").setup({
    install = { colorscheme = {} },
    spec = "mitander.plugins",
    change_detection = { enabled = false },
    performance = {
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
