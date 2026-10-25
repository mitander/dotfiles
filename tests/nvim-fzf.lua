-- Run with: scripts/check fzf
-- Load the real configuration and installed picker without installing other plugins.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugins = vim.fn.stdpath("data") .. "/lazy"
assert(vim.fn.filereadable(plugins .. "/lazy.nvim/lua/lazy/init.lua") == 1, "install Lazy separately")
package.loaded.lazy = { setup = function() end }
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
    vim.fn.mkdir(directory, "p")
    for _, name in ipairs({ "keep.rs", "keep_test.rs", "keep.lua" }) do
        vim.fn.writefile({ "error" }, directory .. "/" .. name)
    end

    local result = grep("err(or|ata) -- *.rs !*_test.rs")
    assert(result.code == 0 and result.stderr == "", vim.inspect(result))
    local lines = vim.split(vim.trim(result.stdout), "\n", { plain = true })
    assert(#lines == 1 and lines[1]:find("keep.rs:", 1, true), result.stdout)

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
print("PASS: installed fzf-lua regex/glob filtering and literal regex/glob shell arguments")
vim.cmd("qa!")
