-- Run with: scripts/check fzf
-- Load the real configuration and installed picker without installing other plugins.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugins = vim.fn.stdpath("data") .. "/lazy"
assert(
    vim.fn.filereadable(plugins .. "/lazy.nvim/lua/lazy/init.lua") == 1,
    "install Lazy separately"
)
package.loaded.lazy = { setup = function() end }
vim.opt.runtimepath:prepend(root .. "/nvim/.config/nvim")
vim.env.TMUX, vim.env.TMUX_PANE = nil, nil
dofile(root .. "/nvim/.config/nvim/init.lua")
vim.opt.runtimepath:append(plugins .. "/fzf-lua")
local spec = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/fzf.lua")
spec.config(nil, spec.opts)
local picker = require("fzf-lua.make_entry")
local options = require("fzf-lua.config").globals.grep
local directory = vim.fn.tempname()

local function grep(query)
    local opts = vim.deepcopy(options)
    opts.rg_opts = opts.rg_opts .. " --color=never"
    local command = picker.get_grep_cmd(opts, query, true)
    return vim.system({ "/bin/sh", "-c", command }, { cwd = directory, text = true }):wait()
end

local ok, failure = xpcall(function()
    local config = require("fzf-lua.config")
    local actions = require("fzf-lua.actions")
    local globals = config.globals
    for _, name in ipairs({
        "files",
        "grep",
        "live_grep",
        "buffers",
        "git.files",
        "git.status",
        "git.commits",
        "git.branches",
        "helptags",
    }) do
        local opts = config.normalize_opts({}, name)
        assert(opts.previewer ~= false, "picker must retain its previewer")
        assert(not opts.winopts.preview.hidden, "previews must start visible")
        assert(opts.keymap.builtin["<f4>"] == "toggle-preview")
        assert(opts.keymap.fzf.f4 == "toggle-preview")
    end
    assert(globals.git.status.previewer == "git_diff", "Git status must retain diff previews")
    assert(globals.actions.files.enter == actions.file_edit_or_qf)
    if vim.fn.has("macunix") == 1 then
        for _, name in ipairs({ "files", "grep", "buffers", "git.status" }) do
            local opts = config.normalize_opts({}, name)
            assert(opts.actions["ctrl-o"], name .. " must inherit Finder reveal")
            assert(globals[name]._actions()["ctrl-o"] == spec.opts.actions.files["ctrl-o"], name)
        end
        for _, name in ipairs({ "git.commits", "git.branches" }) do
            local opts = config.normalize_opts({}, name)
            assert(
                not opts.actions["ctrl-o"],
                name .. " must not reveal a commit or branch in Finder"
            )
        end
    end

    vim.fn.mkdir(directory, "p")
    for _, name in ipairs({ "keep.rs", "keep_test.rs", "keep.lua" }) do
        vim.fn.writefile({ "error" }, directory .. "/" .. name)
    end

    local result = grep("err(or|ata) -- *.rs !*_test.rs")
    assert(result.code == 0 and result.stderr == "", vim.inspect(result))
    local lines = vim.split(vim.trim(result.stdout), "\n", { plain = true })
    assert(#lines == 1 and lines[1]:find("keep.rs:", 1, true), result.stdout)

    -- Use fzf-lua's real entry decoder, but never launch Finder from a test.
    if vim.fn.has("macunix") == 1 then
        local system = vim.system
        local request, completion
        vim.system = function(command, opts, callback)
            assert(opts.text)
            request, completion = command, callback
        end
        local reveal = spec.opts.actions.files["ctrl-o"]
        local names = { "image with spaces.png", "quote'$(literal).jpg" }
        reveal(names, { cwd = directory })
        assert(
            vim.deep_equal(request, {
                "open",
                "-R",
                directory .. "/" .. names[1],
                directory .. "/" .. names[2],
            }),
            vim.inspect(request)
        )
        completion({ code = 0 })
        local notify = vim.notify
        local failure_message
        vim.notify = function(message)
            failure_message = message
        end
        completion({ code = 1, stderr = "cannot reveal\n" })
        assert(vim.wait(100, function()
            return failure_message ~= nil
        end))
        assert(failure_message == "Finder reveal failed: cannot reveal")
        vim.notify = notify
        request = nil
        reveal({}, { cwd = directory })
        assert(request == nil, "empty selection must not launch Finder")

        local buffer = vim.api.nvim_create_buf(true, false)
        local nbsp = require("fzf-lua.utils").nbsp
        local entry = "[" .. buffer .. "]" .. nbsp .. "[No Name]"
        reveal({ entry }, {})
        assert(request == nil, "unnamed buffers have no file to reveal")
        vim.api.nvim_buf_set_name(buffer, directory .. "/keep.lua")
        reveal({ entry }, {})
        assert(vim.deep_equal(request, { "open", "-R", vim.api.nvim_buf_get_name(buffer) }))
        vim.api.nvim_buf_delete(buffer, { force = true })
        vim.system = system
    end

    local marker = directory .. "/must-not-exist"
    -- Observe the final command, not just the regex or glob quoting in isolation.
    for _, case in ipairs({
        { query = "$(touch " .. marker .. ") -- *.rs", code = 1 },
        { query = "error -- *.rs !$(touch${IFS}" .. marker .. ")", code = 0 },
    }) do
        result = grep(case.query)
        assert(result.code == case.code and result.stderr == "", vim.inspect(result))
        assert(vim.fn.filereadable(marker) == 0, "search input was executed by the shell")
    end

    local _, flags = picker.glob_parse("error -- a'b\\c", options)
    result = vim.system({ "/bin/sh", "-c", "printf '%s\\0' " .. flags }):wait()
    assert(result.code == 0 and result.stdout == "--glob\0a'b\\c\0", vim.inspect(result))
end, debug.traceback)
vim.api.nvim_set_current_dir(root)
vim.fn.delete(directory, "rf")
assert(ok, failure)
print("PASS: installed fzf-lua filtering, literal shell arguments and macOS Finder reveal")
vim.cmd("qa!")
