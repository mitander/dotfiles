-- Run with: nvim --clean --headless -l tests/nvim-performance.lua
-- Exercise buffer budgets and startup hooks without installed plugins or language servers.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config = root .. "/nvim/.config/nvim"
vim.opt.rtp:prepend(config)
local limits = require("mitander.buffer_limits")
local original_start = vim.treesitter.start
local original_get_lines = vim.api.nvim_buf_get_lines
local directory = vim.fn.tempname()

local function buffer(bytes)
    local bufnr = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { string.rep("a", bytes - 1) })
    return bufnr
end

local function check()
    -- Include the final newline in the exact boundary. Unsaved text is the source of truth.
    local boundary = buffer(102400)
    local large = buffer(102401)
    assert(not limits.is_large(boundary))
    assert(limits.is_large(large))

    vim.fn.mkdir(directory)
    local file = directory .. "/example.lua"
    vim.fn.writefile({ "return 42" }, file)
    vim.api.nvim_buf_set_name(large, file)
    assert(limits.is_large(large), "small on-disk files must not hide large unsaved text")
    vim.fn.writefile({ string.rep("a", 110000) }, file)
    vim.api.nvim_buf_set_lines(large, 0, -1, false, { "return 42" })
    assert(not limits.is_large(large), "large on-disk files must not override current loaded text")
    vim.api.nvim_buf_delete(large, { unload = true, force = true })
    assert(limits.is_large(large), "unloaded buffers must use their on-disk size")

    -- Prefer the current buffer, deduplicate splits, exclude hidden and special buffers,
    -- and bound combined input even when each visible buffer is individually small.
    local first = buffer(60000)
    local second = buffer(60000)
    local third = buffer(10000)
    local hidden = buffer(100)
    local special = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(second)
    vim.cmd.vsplit()
    vim.api.nvim_win_set_buf(0, first)
    local current_window = vim.api.nvim_get_current_win()
    for _, bufnr in ipairs({ first, third, special }) do
        vim.cmd.vsplit()
        vim.api.nvim_win_set_buf(0, bufnr)
    end
    vim.api.nvim_set_current_win(current_window)

    vim.api.nvim_buf_get_lines = function()
        error("budget checks must not copy buffer text")
    end
    local blink = dofile(config .. "/lua/mitander/plugins/blink.lua")
    local selected = blink.opts.sources.providers.buffer.opts.get_bufnrs()
    assert(vim.deep_equal(selected, { first, third }), vim.inspect(selected))
    assert(not vim.tbl_contains(selected, hidden))
    assert(not limits.is_large(first) and limits.is_large(boundary) == false)
    vim.api.nvim_buf_get_lines = original_get_lines

    local markdown = dofile(config .. "/lua/mitander/plugins/markdown.lua")[1]
    assert(not markdown.opts.ignore(first))
    assert(markdown.opts.ignore(large))

    -- Exercise the actual built-in ftplugin entrypoints. A late FileType return is not enough.
    local calls = {}
    vim.treesitter.start = function(bufnr, lang)
        calls[#calls + 1] = { bufnr = bufnr, lang = lang }
        return "started"
    end
    limits.setup_treesitter()
    local oversized = buffer(102401)
    vim.api.nvim_set_current_buf(oversized)
    dofile(vim.env.VIMRUNTIME .. "/ftplugin/lua.lua")
    dofile(vim.env.VIMRUNTIME .. "/ftplugin/markdown.lua")
    assert(#calls == 0, "built-in ftplugins must not start Treesitter on large buffers")
    vim.api.nvim_set_current_buf(first)
    assert(vim.treesitter.start() == "started")
    assert(vim.treesitter.start(first, "lua") == "started")
    assert(#calls == 2 and calls[2].bufnr == first and calls[2].lang == "lua")

    -- Provisioning is explicit, while the plugin's update hook remains intact.
    local installations = {}
    package.loaded["nvim-treesitter"] = {
        setup = function() end,
        install = function(languages, opts)
            installations[#installations + 1] = { languages = languages, opts = opts }
        end,
    }
    package.loaded["nvim-treesitter-textobjects"] = { setup = function() end }
    local treesitter = dofile(config .. "/lua/mitander/plugins/treesitter.lua")
    treesitter.config()
    assert(#installations == 0, "normal startup must not provision parsers")
    vim.cmd.TSInstallConfigured()
    assert(
        #installations == 1 and #installations[1].languages > 0,
        "explicit provisioning must install the configured set"
    )
end

local ok, failure = xpcall(check, debug.traceback)
vim.treesitter.start = original_start
vim.api.nvim_buf_get_lines = original_get_lines
for _, name in ipairs({ "nvim-treesitter", "nvim-treesitter-textobjects" }) do
    package.loaded[name] = nil
end
vim.fn.delete(directory, "rf")
assert(ok, failure)
print("PASS: buffer budgets, Treesitter entrypoints and explicit parser provisioning")
vim.cmd("qa!")
