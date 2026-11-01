-- Run with: nvim --clean --headless -l tests/nvim-rust.lua
-- Requires installed plugins and a rustup toolchain. Cargo work stays in a disposable project.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config = root .. "/nvim/.config/nvim"
local data = vim.fn.stdpath("data")
local plugins = vim.env.NVIM_LAZY_DIR or data .. "/lazy"
local temporary = vim.fn.tempname()
local client

local function check()
    local analyzer = vim.fn.exepath("rust-analyzer")
    assert(analyzer ~= "", "install rust-analyzer in the selected rustup toolchain first")
    vim.fn.mkdir(temporary .. "/data/nvim", "p")
    vim.fn.mkdir(temporary .. "/project/src", "p")
    vim.fn.mkdir(temporary .. "/project/.git", "p")
    temporary = assert(vim.uv.fs_realpath(temporary))
    assert(vim.uv.fs_symlink(plugins, temporary .. "/data/nvim/lazy"))
    assert(vim.uv.fs_symlink(data .. "/site", temporary .. "/data/nvim/site"))
    vim.env.XDG_DATA_HOME = temporary .. "/data"
    vim.env.XDG_STATE_HOME = temporary .. "/state"
    vim.env.XDG_CACHE_HOME = temporary .. "/cache"
    vim.env.FLUME_DATA_DIR = temporary .. "/flume"
    vim.env.DOTFILES_DIR = root
    vim.env.TMUX, vim.env.TMUX_PANE = nil, nil
    vim.fn.writefile(vim.fn.readfile(config .. "/lazy-lock.json"), temporary .. "/lazy-lock.json")
    vim.opt.rtp:prepend(config)
    vim.opt.rtp:prepend(plugins .. "/lazy.nvim")
    local lazy = require("lazy")
    local setup = lazy.setup
    lazy.setup = function(opts)
        opts.install.missing = false
        opts.lockfile = temporary .. "/lazy-lock.json"
        opts.spec = {
            { import = opts.spec },
            {
                "saghen/blink.cmp",
                opts = {
                    fuzzy = { implementation = "lua", prebuilt_binaries = { download = false } },
                },
            },
        }
        return setup(opts)
    end
    dofile(config .. "/init.lua")
    print("Rust fixture: configuration loaded")
    vim.fn.writefile({
        "[package]",
        'name = "editor_fixture"',
        'version = "0.1.0"',
        'edition = "2021"',
    }, temporary .. "/project/Cargo.toml")
    local filename = temporary .. "/project/src/main.rs"
    vim.fn.writefile({
        "fn double(value: i32) -> i32 { value * 2 }",
        "fn main() {",
        "    let answer = double(21);",
        "    let macro_text = stringify!(hello);",
        '    println!("{answer} {macro_text}");',
        "}",
        "#[test]",
        "fn failing_test() { assert_eq!(1, 2); }",
    }, filename)
    vim.cmd.edit(vim.fn.fnameescape(filename))
    local bufnr = vim.api.nvim_get_current_buf()
    print("Rust fixture: waiting for analyzer attachment")
    assert(
        vim.wait(30000, function()
            local clients = vim.lsp.get_clients({ bufnr = bufnr })
            client = clients[1]
            return #clients == 1
                and client.initialized
                and vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
        end, 50),
        "one initialized Rust client with enabled hints must attach"
    )
    assert(client.name == "rust-analyzer")
    assert(not vim.lsp.is_enabled("rust_analyzer"), "generic Rust startup must remain disabled")
    assert(client.config.cmd[1] == analyzer, "Rust must use the same analyzer as the shell")
    assert(client.config.capabilities.textDocument.completion.completionItem.snippetSupport)

    print("Rust fixture: one initialized client attached")
    local document = { uri = vim.uri_from_bufnr(bufnr) }
    local hints, finished, hint_error = {}, false, nil
    local function request_hints()
        if finished then
            return
        end
        client:request("textDocument/inlayHint", {
            textDocument = document,
            range = {
                start = { line = 0, character = 0 },
                ["end"] = {
                    line = 2,
                    character = #vim.api.nvim_buf_get_lines(bufnr, 2, 3, false)[1],
                },
            },
        }, function(err, result)
            hints = not err and result or {}
            hint_error = err
            if #hints == 0 then
                vim.defer_fn(request_hints, 200)
            end
        end, bufnr)
    end
    -- Poll state only. Sending requests in the predicate can flood the server on every reply.
    request_hints()
    local received = vim.wait(30000, function()
        return #hints > 0
    end, 200)
    finished = true
    assert(received, "rust-analyzer must return real inlay hints: " .. vim.inspect(hint_error))
    assert(vim.inspect(hints):find("i32", 1, true), "inferred i32 type must appear in the hints")

    print("Rust fixture: real inlay hints returned")
    local selected = false
    vim.ui.select = function(items, _, callback)
        assert(#items > 0, "runnable picker must contain targets")
        selected = true
        callback(nil)
    end
    vim.fn.maparg(" cr", "n", false, true).callback()
    assert(
        vim.wait(10000, function()
            return selected
        end),
        "Rust runnable mapping must open target selection"
    )

    print("Rust fixture: runnable selection opened")
    selected = false
    vim.ui.select = function(items, _, callback)
        for index, item in ipairs(items) do
            if item:find("failing_test", 1, true) then
                selected = true
                callback(item, index)
                return
            end
        end
        error("test picker did not expose failing_test")
    end
    vim.fn.maparg(" ct", "n", false, true).callback()
    local namespace = vim.api.nvim_create_namespace("rustaceanvim")
    assert(
        vim.wait(30000, function()
            return selected and #vim.diagnostic.get(bufnr, { namespace = namespace }) > 0
        end, 100),
        "a real failed Cargo test must produce source diagnostics"
    )
    assert(#vim.lsp.get_clients({ bufnr = bufnr }) == 1, "Rust startup must not duplicate clients")

    print("Rust fixture: failed-test diagnostics received")
    vim.api.nvim_win_set_cursor(0, { 4, 23 })
    vim.fn.maparg(" cm", "n", false, true).callback()
    assert(
        vim.wait(10000, function()
            if vim.api.nvim_get_current_buf() == bufnr then
                return false
            end
            local expansion = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
            return expansion:find('"hello"', 1, true) ~= nil
        end, 50),
        "macro mapping must display the expansion"
    )
end

local ok, failure = xpcall(check, debug.traceback)
if client then
    client:stop(true)
    vim.wait(5000, function()
        return client:is_stopped()
    end)
end
vim.api.nvim_set_current_dir(root)
vim.fn.delete(temporary, "rf")
assert(ok, failure)
print(
    "PASS: one Rust client, real inlay hints, runnable selection, failed-test diagnostics and macro expansion"
)
vim.cmd("qa!")
