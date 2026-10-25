-- Run with: nvim --clean --headless -l tests/nvim-clipboard.lua
-- Uses a disposable tmux server with no clients; never touches the live clipboard.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local directory = vim.fn.tempname()
local socket = "dotfiles-clipboard-" .. vim.fn.getpid()
local tmux_binary = vim.fn.exepath("tmux")
local server_started = false

local function command(args, stdin)
    local result = vim.system(args, { text = true, stdin = stdin }):wait()
    assert(result.code == 0, result.stderr)
    return result.stdout
end

local function tmux(...)
    return command({ tmux_binary, "-L", socket, ... })
end

local function check()
    -- Record provider calls without retaining clipboard text or arguments.
    vim.fn.mkdir(directory .. "/bin", "p")
    local log = directory .. "/calls"
    vim.fn.writefile({
        "#!/bin/sh",
        "printf '%s\\n' \"$1\" >> " .. vim.fn.shellescape(log),
        "exec " .. vim.fn.shellescape(tmux_binary) .. ' "$@"',
    }, directory .. "/bin/tmux")
    assert(vim.fn.setfperm(directory .. "/bin/tmux", "rwx------") == 1)

    vim.env.PATH = directory .. "/bin:" .. vim.env.PATH
    vim.env.TMUX = nil
    tmux("-f", "/dev/null", "new-session", "-d", "-s", "test", "sleep", "300")
    server_started = true
    vim.env.TMUX = vim.trim(tmux("display-message", "-p", "#{socket_path},#{pid},0"))
    local plugin = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/tmux.lua")
    plugin.init()
    assert(plugin.opts.copy_sync.enable == false)
    assert(vim.fn.has("clipboard") == 1)

    local function buffer(lines, row)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.api.nvim_win_set_cursor(0, { row or 1, 0 })
    end

    local function clipboard()
        return tmux("save-buffer", "-")
    end

    buffer({ "alpha", "beta" })
    vim.cmd.normal({ args = { "yy" }, bang = true })
    assert(clipboard() == "alpha\n", "ordinary yank did not reach tmux")
    assert(vim.fn.getreg("0") == "alpha\n", "native yank register was lost")
    assert(vim.fn.getregtype("+") == "V", "linewise register type was lost")

    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd.normal({ args = { '"ayy' }, bang = true })
    assert(clipboard() == "alpha\n", "named yank unexpectedly replaced the clipboard")
    vim.cmd.normal({ args = { "dd" }, bang = true })
    assert(clipboard() == "beta\n", "ordinary delete did not reach tmux")
    assert(vim.fn.getreg("a") == "beta\n", "named register was replaced")
    assert(vim.fn.getreg("0") == "alpha\n", "named yank replaced the native yank register")
    assert(vim.fn.getreg("1") == "beta\n", "native delete history was lost")

    -- External tmux copies affect ordinary paste, not numbered/named history.
    command({ tmux_binary, "-L", socket, "load-buffer", "-" }, "outside")
    buffer({ "here" })
    vim.cmd.normal({ args = { "p" }, bang = true })
    assert(vim.api.nvim_get_current_line() == "houtsideere", "external clipboard paste failed")
    assert(vim.fn.getreg("a") == "beta\n" and vim.fn.getreg("1") == "beta\n")
    local calls = vim.fn.readfile(log)
    assert(not vim.tbl_contains(calls, "list-buffers"), "clipboard imported tmux history")
    assert(not vim.tbl_contains(calls, "show-buffer"), "clipboard imported numbered registers")

    -- Clipboard text travels on stdin, including shell metacharacters and quotes.
    local marker = directory .. "/must-not-exist"
    local payload = "$(touch " .. marker .. ') `false` ; "quoted" \\ text'
    buffer({ payload })
    vim.cmd.normal({ args = { "yy" }, bang = true })
    assert(clipboard() == payload .. "\n", "clipboard text was altered")
    assert(not vim.uv.fs_stat(marker), "clipboard text was interpreted by a shell")

    buffer({ "start" })
    vim.cmd.normal({ args = { "p" }, bang = true })
    assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "start", payload }))

    vim.fn.setreg("+", { "AB", "CD" }, "\0222")
    assert(vim.fn.getregtype("+") == "\0222", "blockwise register type was lost")
    buffer({ "xx", "yy" })
    vim.cmd.normal({ args = { "p" }, bang = true })
    assert(
        vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "xABx", "yCDy" }),
        "blockwise paste must preserve both rows"
    )
end

local ok, failure = xpcall(check, debug.traceback)
local stopped = vim.system({ tmux_binary, "-L", socket, "kill-server" }):wait()

vim.fn.delete(directory, "rf")

assert(ok, failure)
-- No server is expected when setup failed before new-session completed.
assert(not server_started or stopped.code == 0, stopped.stderr)
print("PASS: native tmux clipboard, external paste, register types/history, literal text")
vim.cmd("qa!")
