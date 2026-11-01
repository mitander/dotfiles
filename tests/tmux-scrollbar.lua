-- Observe the native tmux grid through Neovim's terminal, not pane-content captures.
local socket, palette_path = arg[1], arg[2]
local colors = vim.json.decode(table.concat(vim.fn.readfile(palette_path), "\n")).colors
local session = "scroll-colors-" .. vim.fn.getpid()
local job

local function tmux(...)
    local command = { "tmux", "-L", socket }
    vim.list_extend(command, { ... })
    local output = vim.fn.system(command)
    assert(vim.v.shell_error == 0, output)
    return vim.trim(output)
end

local function rgb(role)
    return tonumber(colors[role]:sub(2), 16)
end

local ok, err = xpcall(function()
    vim.o.columns, vim.o.lines = 100, 22
    vim.o.laststatus, vim.o.showtabline = 0, 0
    vim.o.termguicolors = true
    vim.o.scrolloff = 0
    vim.wo.number, vim.wo.relativenumber = false, false

    tmux("new-session", "-d", "-x", "100", "-y", "21", "-s", session, "sleep 300")
    tmux("set-option", "-w", "-t", session .. ":0", "pane-scrollbars", "auto-hide")
    tmux("set-option", "-w", "-t", session .. ":0", "pane-scrollbars-timeout", "60000")
    tmux(
        "respawn-pane",
        "-k",
        "-t",
        session .. ":0",
        'seq 1 6100; printf "SCROLL_READY\n"; sleep 300'
    )
    assert(
        vim.wait(3000, function()
            return tmux("capture-pane", "-p", "-t", session .. ":0"):find("SCROLL_READY", 1, true)
        end, 20),
        "scroll fixture did not produce history"
    )

    job = vim.fn.termopen({
        "tmux",
        "-u",
        "-L",
        socket,
        "-T",
        "RGB",
        "attach-session",
        "-t",
        session,
    })
    assert(job > 0, "could not attach private terminal client")
    vim.cmd("startinsert")
    assert(
        vim.wait(3000, function()
            return table
                .concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
                :find("SCROLL_READY", 1, true)
        end, 20),
        "attached client did not render fixture"
    )

    local height, width = vim.api.nvim_win_get_height(0), vim.api.nvim_win_get_width(0)
    local function cell(row, column)
        vim.cmd("redraw!")
        local inspected = vim.api.nvim__inspect_cell(1, row - 1, column - 1)
        return inspected[1], inspected[2]
    end

    tmux("copy-mode", "-t", session .. ":0")
    for _, offset in ipairs({ 1, 5 }) do
        tmux("send-keys", "-X", "-t", session .. ":0", "history-bottom")
        tmux("send-keys", "-X", "-N", tostring(offset), "-t", session .. ":0", "scroll-up")
        assert(
            vim.wait(3000, function()
                local line = vim.api.nvim_buf_get_lines(0, height - 1, height, false)[1] or ""
                return line:find("≡ " .. offset .. "/", 1, true)
            end, 20),
            "scroll position did not render"
        )

        local text, attributes = cell(height, width)
        assert(text == " ", "status gutter contains text")
        assert(attributes.background == rgb("bg"), "status gutter joins the accent thumb")
        local _, thumb = cell(height - 1, width)
        assert(
            thumb.background == rgb("accent"),
            "bottom thumb is not visible above the status row"
        )
    end
end, debug.traceback)

if job then
    vim.fn.jobstop(job)
end
vim.fn.system({ "tmux", "-L", socket, "kill-session", "-t", session })
if not ok then
    io.stderr:write(err .. "\n")
    vim.cmd("cquit 1")
end
print("PASS: native scroll thumb stays visible above a blank status gutter at small offsets")
vim.cmd("qa!")
