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
vim.opt.cmdheight = 0
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
vim.keymap.set("c", "<enter>", function()
    local cmdtype = vim.fn.getcmdtype()
    if cmdtype ~= "/" and cmdtype ~= "?" then
        return "<cr>"
    end

    local pattern = vim.fn.getcmdline()
    if pattern == "" then
        return "<cr>"
    end

    local flags = cmdtype == "?" and "bn" or "n"
    local ok, line = pcall(vim.fn.search, pattern, flags)
    if ok and line == 0 then
        pcall(vim.fn.histadd, cmdtype, pattern)
        vim.fn.setreg("/", pattern)
        return "<c-c>"
    end

    return "<cr>"
end, { expr = true, desc = "Cancel failed searches silently" })

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

-- Helper to record plugin spec modification times
local function get_plugin_mtimes()
    local mtimes = {}
    local plugins_dir = vim.fn.stdpath("config") .. "/lua/mitander/plugins"
    if vim.fn.isdirectory(plugins_dir) == 1 then
        for name, kind in vim.fs.dir(plugins_dir) do
            if kind == "file" and name:match("%.lua$") then
                local path = plugins_dir .. "/" .. name
                local stat = vim.uv.fs_stat(path)
                if stat then
                    mtimes[name] = { sec = stat.mtime.sec, nsec = stat.mtime.nsec }
                end
            end
        end
    end
    return mtimes
end

_G.plugin_spec_mtimes = _G.plugin_spec_mtimes or get_plugin_mtimes()

-- reload configuration
vim.keymap.set("n", "<leader>rl", function()
    -- Automatically save all buffers and sync external changes to prevent prompts
    vim.cmd("silent! wa")
    pcall(vim.cmd, "checktime")

    -- 1. Scan lua/mitander/plugins/ to find changed spec files
    local plugins_dir = vim.fn.stdpath("config") .. "/lua/mitander/plugins"
    local plugin_names = {}
    local changed_spec_files = {}

    if vim.fn.isdirectory(plugins_dir) == 1 then
        for name, kind in vim.fs.dir(plugins_dir) do
            if kind == "file" and name:match("%.lua$") then
                local filepath = plugins_dir .. "/" .. name
                local stat = vim.uv.fs_stat(filepath)
                if stat then
                    local cached = _G.plugin_spec_mtimes[name]
                    local changed = false
                    if not cached then
                        changed = true
                    elseif cached.sec ~= stat.mtime.sec or cached.nsec ~= stat.mtime.nsec then
                        changed = true
                    end

                    if changed then
                        table.insert(changed_spec_files, name)
                        _G.plugin_spec_mtimes[name] = { sec = stat.mtime.sec, nsec = stat.mtime.nsec }

                        local modname = "mitander.plugins." .. name:gsub("%.lua$", "")
                        package.loaded[modname] = nil
                        local ok, spec = pcall(require, modname)
                        if ok and type(spec) == "table" then
                            local is_list = false
                            if #spec > 0 then
                                if type(spec[1]) == "table" then
                                    is_list = true
                                end
                            end

                            if is_list then
                                for _, subspec in ipairs(spec) do
                                    if type(subspec) == "table" then
                                        local sub_name = subspec.name
                                        if not sub_name and type(subspec[1]) == "string" then
                                            local sub_pkg = subspec[1]
                                            sub_name = sub_pkg:match("/([^/]+)$") or sub_pkg
                                        end
                                        if sub_name and sub_name ~= "" then
                                            table.insert(plugin_names, sub_name)
                                        end
                                    end
                                end
                            else
                                local plugin_name = spec.name
                                if not plugin_name and type(spec[1]) == "string" then
                                    local raw_pkg = spec[1]
                                    plugin_name = raw_pkg:match("/([^/]+)$") or raw_pkg
                                end
                                if plugin_name and plugin_name ~= "" then
                                    table.insert(plugin_names, plugin_name)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 2. Clear cached custom user configs
    for name, _ in pairs(package.loaded) do
        if name:match("^mitander") or name:match("^flume") then
            local is_spec = name:match("^mitander%.plugins%.")
            local spec_filename = is_spec and (name:gsub("^mitander%.plugins%.", "") .. ".lua")

            local should_clear = true
            if is_spec then
                should_clear = false
                for _, file_name in ipairs(changed_spec_files) do
                    if file_name == spec_filename then
                        should_clear = true
                        break
                    end
                end
            end

            if should_clear then
                package.loaded[name] = nil
            end
        end
    end

    if #plugin_names > 0 then
        -- 3. Reload specs using lazy core
        local ok_core, plugin_core = pcall(require, "lazy.core.plugin")
        if ok_core then
            pcall(plugin_core.load)
        end

        -- 4. Wipe cache for ONLY the changed plugins to force option re-evaluation
        local ok_config, config = pcall(require, "lazy.core.config")
        if ok_config and config.plugins then
            for _, name in ipairs(plugin_names) do
                local plugin = config.plugins[name]
                if plugin and plugin._ then
                    plugin._.cache = nil
                end
            end
        end
    end

    -- 5. Reload init.lua
    dofile(vim.env.MYVIMRC)

    -- 6. Reload flume colorscheme and generated external themes.
    -- flume.reload() recompiles extras and only reloads Ghostty/Tmux when
    -- their generated files actually changed.
    local ok, flume = pcall(require, "flume")
    if ok and type(flume.reload) == "function" then
        pcall(flume.reload)
    elseif ok then
        pcall(flume.setup)
    else
        pcall(vim.cmd, "colorscheme flume")
    end

    -- 7. Trigger lazy.nvim's official reload mechanism for ONLY the changed plugins
    if #plugin_names > 0 then
        local lazy = require("lazy")
        local ok_util, util = pcall(require, "lazy.core.util")
        local orig_warn
        if ok_util and util.warn then
            orig_warn = util.warn
            util.warn = function() end
        end

        for _, name in ipairs(plugin_names) do
            local is_loaded = false
            for _, p in ipairs(lazy.plugins()) do
                if p.name == name and p._.loaded ~= nil then
                    is_loaded = true
                    break
                end
            end
            if is_loaded then
                pcall(lazy.reload, { plugins = { name } })
            end
        end

        if orig_warn and util then
            util.warn = orig_warn
        end
    end

    vim.notify("nvim config reloaded", vim.log.levels.INFO)
end, { desc = "Reload Neovim configuration" })

local group = vim.api.nvim_create_augroup("mitander", { clear = true })
local startup_scratch_ns = vim.api.nvim_create_namespace("startup_scratch")
vim.api.nvim_set_hl(0, "StartupScratchMessage", { fg = "#a3be8c", italic = true })

-- calm startup scratch
local startup_messages = {
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

local function random_startup_message()
    math.randomseed(vim.uv.hrtime())
    return startup_messages[math.random(#startup_messages)]
end

local function is_empty_unnamed_buffer()
    if vim.api.nvim_buf_get_name(0) ~= "" or vim.api.nvim_buf_line_count(0) > 1 then
        return false
    end
    return vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == ""
end

local function is_startup_scratch(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].startup_scratch == true
end

local function apply_startup_scratch_window_options(winid)
    winid = winid == 0 and vim.api.nvim_get_current_win() or winid
    if not vim.api.nvim_win_is_valid(winid) then
        return
    end

    if not vim.w[winid].startup_scratch_options then
        vim.w[winid].startup_scratch_options = {
            number = vim.wo[winid].number,
            relativenumber = vim.wo[winid].relativenumber,
            cursorline = vim.wo[winid].cursorline,
            signcolumn = vim.wo[winid].signcolumn,
        }
    end

    vim.wo[winid].number = false
    vim.wo[winid].relativenumber = false
    vim.wo[winid].cursorline = false
    vim.wo[winid].signcolumn = "no"
end

local function restore_startup_scratch_window_options(winid)
    winid = winid == 0 and vim.api.nvim_get_current_win() or winid
    if not vim.api.nvim_win_is_valid(winid) then
        return
    end

    local opts = vim.w[winid].startup_scratch_options
    if opts then
        vim.wo[winid].number = opts.number
        vim.wo[winid].relativenumber = opts.relativenumber
        vim.wo[winid].cursorline = opts.cursorline
        vim.wo[winid].signcolumn = opts.signcolumn
        vim.w[winid].startup_scratch_options = nil
    else
        vim.wo[winid].number = vim.o.number
        vim.wo[winid].relativenumber = vim.o.relativenumber
        vim.wo[winid].cursorline = vim.o.cursorline
        vim.wo[winid].signcolumn = vim.o.signcolumn
    end
end

local function clear_startup_scratch(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "" })
    vim.api.nvim_buf_clear_namespace(bufnr, startup_scratch_ns, 0, -1)
    vim.b[bufnr].startup_scratch = nil
    vim.b[bufnr].startup_scratch_message = nil
    vim.bo[bufnr].buflisted = true
    vim.bo[bufnr].bufhidden = ""
    vim.bo[bufnr].filetype = ""
    vim.bo[bufnr].modified = false
end

local function render_startup_scratch(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not is_startup_scratch(bufnr) then
        return
    end

    vim.api.nvim_buf_clear_namespace(bufnr, startup_scratch_ns, 0, -1)

    local message = vim.b[bufnr].startup_scratch_message
    if not message then
        return
    end

    local height = vim.o.lines - vim.o.cmdheight - 2
    local row = math.max(math.floor(height / 2), 0)
    local col = math.max(math.floor((vim.o.columns - vim.fn.strdisplaywidth(message)) / 2), 0)
    local lines = {}

    for _ = 1, row do
        lines[#lines + 1] = ""
    end
    lines[#lines + 1] = string.rep(" ", col) .. message

    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.bo[bufnr].modifiable = false
    vim.bo[bufnr].modified = false
    vim.api.nvim_buf_add_highlight(bufnr, startup_scratch_ns, "StartupScratchMessage", row, col, -1)
end

local function promote_startup_scratch(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not is_startup_scratch(bufnr) then
        return
    end

    clear_startup_scratch(bufnr)
    for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
        restore_startup_scratch_window_options(winid)
    end
end

function _G.mitander_dismiss_startup_scratch()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if is_startup_scratch(bufnr) then
            for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
                if vim.api.nvim_win_is_valid(winid) then
                    local replacement = vim.api.nvim_create_buf(true, false)
                    vim.api.nvim_win_set_buf(winid, replacement)
                    restore_startup_scratch_window_options(winid)
                end
            end

            if vim.api.nvim_buf_is_valid(bufnr) then
                pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
            end
        end
    end
end

local function show_startup_scratch()
    if vim.fn.argc() > 0 or vim.bo.filetype == "lazy" or not is_empty_unnamed_buffer() then
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    vim.b[bufnr].startup_scratch = true
    vim.b[bufnr].startup_scratch_message = random_startup_message()
    vim.bo[bufnr].buflisted = false
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "startup"
    vim.bo[bufnr].modified = false
    apply_startup_scratch_window_options(0)
    render_startup_scratch(bufnr)

    vim.api.nvim_create_autocmd("InsertEnter", {
        group = group,
        buffer = bufnr,
        once = true,
        callback = function()
            promote_startup_scratch(bufnr)
        end,
    })
    vim.api.nvim_create_autocmd("BufWinLeave", {
        group = group,
        buffer = bufnr,
        callback = function(args)
            if is_startup_scratch(args.buf) then
                restore_startup_scratch_window_options(0)
            end
        end,
    })
    vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        buffer = bufnr,
        once = true,
        callback = function()
            vim.api.nvim_buf_clear_namespace(bufnr, startup_scratch_ns, 0, -1)
        end,
    })
end

vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = show_startup_scratch,
})

vim.api.nvim_create_autocmd("WinResized", {
    group = group,
    callback = function()
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local bufnr = vim.api.nvim_win_get_buf(winid)
            if is_startup_scratch(bufnr) then
                render_startup_scratch(bufnr)
            end
        end
    end,
})

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
        if vim.bo.filetype ~= "startup" then
            vim.opt_local.cursorline = true
        end
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

-- Auto-compile flume theme and reload external apps on write
vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*/flume.nvim/lua/flume/*.lua",
    callback = function()
        local ok, flume = pcall(require, "flume")
        if ok and type(flume.reload) == "function" then
            pcall(flume.reload)
        elseif ok then
            pcall(flume.setup)
        else
            pcall(vim.cmd, "colorscheme flume")
        end
    end,
})

-- bootstrap lazy if needed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_init = lazypath .. "/lua/lazy/init.lua"
if not vim.uv.fs_stat(lazy_init) then
    vim.fn.delete(lazypath, "rf")
    local out = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
    if vim.v.shell_error ~= 0 then
        error("Failed to clone lazy.nvim:\n" .. out)
    end
end
vim.opt.rtp:prepend(lazypath)

-- initiate lazy
if not _G.lazy_initialized then
    local ok, lazy = pcall(require, "lazy")
    if not ok then
        error("Failed to load lazy.nvim from " .. lazypath .. ":\n" .. lazy)
    end
    lazy.setup({
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
    _G.lazy_initialized = true
end
