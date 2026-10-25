-- Run with: nvim --clean --headless -l tests/nvim-startup.lua
-- Requires installed plugins/parsers. No language servers, downloads or live sessions are started.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config = root .. "/nvim/.config/nvim"
local data = vim.fn.stdpath("data")
local temporary = vim.fn.tempname()

local function check()
    assert(vim.fn.isdirectory(data .. "/lazy/lazy.nvim") == 1, "install plugins separately first")
    vim.fn.mkdir(temporary .. "/config", "p")
    vim.fn.mkdir(temporary .. "/data/nvim", "p")
    vim.fn.mkdir(temporary .. "/files", "p")
    assert(vim.uv.fs_symlink(config, temporary .. "/config/nvim"))
    assert(vim.uv.fs_symlink(data .. "/lazy", temporary .. "/data/nvim/lazy"))
    assert(vim.uv.fs_symlink(data .. "/site", temporary .. "/data/nvim/site"))
    if vim.fn.isdirectory(data .. "/mason") == 1 then
        assert(vim.uv.fs_symlink(data .. "/mason", temporary .. "/data/nvim/mason"))
    end

    local env = vim.fn.environ()
    for _, name in ipairs({ "TMUX", "TMUX_PANE", "NVIM", "NVIM_APPNAME", "NVIM_LOG_FILE" }) do
        env[name] = nil
    end
    env.XDG_CONFIG_HOME = temporary .. "/config"
    env.XDG_DATA_HOME = temporary .. "/data"
    env.XDG_STATE_HOME = temporary .. "/state"
    env.XDG_CACHE_HOME = temporary .. "/cache"
    env.FLUME_DATA_DIR = temporary .. "/flume"
    env.DOTFILES_DIR = root

    local driver = temporary .. "/driver.lua"
    vim.fn.writefile(
        vim.split(
            [[
local started = vim.uv.hrtime()
local starts = {}
vim.lsp.start = function(server)
    starts[#starts + 1] = server.capabilities.textDocument.completion.completionItem.snippetSupport
end
local lazy_path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
vim.opt.rtp:prepend(lazy_path)
local lazy = require('lazy')
local setup = lazy.setup
lazy.setup = function(opts)
    opts.install.missing = false
    opts.spec = {
        { import = opts.spec },
        { 'saghen/blink.cmp', opts = { fuzzy = { prebuilt_binaries = { download = false } } } },
    }
    return setup(opts)
end
vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
        local entered_ms = (vim.uv.hrtime() - started) / 1e6
        vim.api.nvim_exec_autocmds('UIEnter', {})
        vim.defer_fn(function()
            local ok, result = xpcall(function()
                local result = {
                    entered_ms = entered_ms,
                    blink_loaded = package.loaded['blink.cmp'] ~= nil,
                    treesitter_active = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil,
                    starts = starts,
                }
                if vim.bo.filetype == 'lua' and not require('mitander.buffer_limits').is_large(0) then
                    local spec = dofile(vim.env.DOTFILES_DIR .. '/nvim/.config/nvim/lua/mitander/plugins/blink.lua')
                    local provider = spec.opts.sources.providers.buffer
                    local source = require(provider.module).new(provider.opts)
                    vim.cmd.vsplit()
                    local large = vim.api.nvim_create_buf(true, false)
                    vim.api.nvim_win_set_buf(0, large)
                    vim.api.nvim_buf_set_lines(large, 0, -1, false, { string.rep('z', 10000000) })
                    vim.cmd.wincmd('p')
                    local read_lines = vim.api.nvim_buf_get_lines
                    vim.api.nvim_buf_get_lines = function(buffer, ...)
                        assert(buffer ~= large, 'completion copied a large visible buffer')
                        return read_lines(buffer, ...)
                    end
                    local done = false
                    local completion_started = vim.uv.hrtime()
                    source:get_completions({}, function(response)
                        result.completion_ms = (vim.uv.hrtime() - completion_started) / 1e6
                        result.completion_items = #response.items
                        done = true
                    end)
                    assert(vim.wait(2000, function() return done end), 'completion timed out')
                    vim.api.nvim_buf_get_lines = read_lines
                end
                return result
            end, debug.traceback)
            vim.fn.writefile({ vim.json.encode(ok and result or { error = result }) }, vim.env.TEST_RESULT)
            vim.cmd('qa!')
        end, 100)
    end,
})
]],
            "\n"
        ),
        driver
    )

    for _, case in ipairs({
        { name = "plain.txt", text = "plain text", lsp = false, treesitter = false },
        { name = "small.md", text = "# Heading\n\nSome text", lsp = false, treesitter = true },
        { name = "large.md", text = string.rep("# Heading\n\nSome text\n", 6000), lsp = false, treesitter = false },
        { name = "small.lua", text = "local alpha = 42\nreturn alpha", lsp = true, treesitter = true },
        { name = "large.lua", text = string.rep("local alpha = 42\n", 7000), lsp = true, treesitter = false },
    }) do
        local file = temporary .. "/files/" .. case.name
        vim.fn.writefile(vim.split(case.text, "\n"), file)
        env.TEST_RESULT = temporary .. "/" .. case.name .. ".json"
        local process = vim.system({
            vim.v.progpath,
            "--headless",
            "-i",
            "NONE",
            "-n",
            "--cmd",
            "lua dofile(" .. vim.inspect(driver) .. ")",
            file,
        }, { env = env, clear_env = true, cwd = temporary .. "/files", text = true }):wait(10000)
        assert(process.code == 0, case.name .. ": " .. vim.inspect(process))
        local result = vim.json.decode(table.concat(vim.fn.readfile(env.TEST_RESULT), "\n"))
        assert(not result.error, (result.error or "") .. "\n" .. (process.stderr or ""))
        assert(result.blink_loaded == case.lsp, case.name .. ": completion load")
        assert(result.treesitter_active == case.treesitter, case.name .. ": Treesitter cutoff")
        if case.lsp then
            assert(#result.starts > 0, case.name .. ": first supported file did not activate LSP")
            for _, snippets in ipairs(result.starts) do
                assert(snippets, case.name .. ": completion capabilities lost")
            end
        else
            assert(#result.starts == 0, case.name .. ": unrelated file activated LSP")
        end
        if result.completion_items then
            assert(result.completion_items > 0, "large split suppressed small-buffer completion")
        end
        print(case.name .. ": " .. vim.json.encode(result))
    end
end

local ok, failure = xpcall(check, debug.traceback)
vim.fn.delete(temporary, "rf")
assert(ok, failure)
print("PASS: installed startup, filetype activation, Treesitter cutoff and completion isolation")
vim.cmd("qa!")
