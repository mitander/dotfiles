-- Run with: nvim --clean --headless -l tests/nvim-formatters.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config_dir = root .. "/nvim/.config/nvim"
local project = vim.fn.tempname()

local function check()
    local opts = dofile(config_dir .. "/lua/mitander/plugins/conform.lua").opts
    vim.fn.mkdir(project .. "/docs", "p")
    vim.fn.mkdir(project .. "/.dev-tools/bin", "p")

    local function expect_native_routes()
        assert(vim.deep_equal(opts.formatters_by_ft.rust, { "rustfmt" }))
        assert(
            vim.deep_equal(opts.formatters_by_ft.python, { "ruff_organize_imports", "ruff_format" })
        )
    end

    expect_native_routes()

    for _, filetype in ipairs({ "typescript", "json", "markdown" }) do
        assert(
            vim.deep_equal(
                opts.formatters_by_ft[filetype],
                { "prettierd", "dprint", stop_after_first = true }
            )
        )
    end
    assert(
        opts.formatters.prettierd.require_cwd,
        "Prettier runs only in repositories that configure it"
    )

    local formatter = opts.formatters.dprint
    local context = { dirname = project .. "/docs" }
    assert(
        vim.deep_equal(formatter.args, { "fmt", "--stdin", "$RELATIVE_FILEPATH" }),
        "pass the path relative to the config directory so unsaved files format"
    )
    assert(formatter.cwd(nil, context) == context.dirname)
    for _, name in ipairs({ "dprint.json", ".dprint.json", "dprint.jsonc", ".dprint.jsonc" }) do
        vim.fn.writefile({ "{}" }, project .. "/" .. name)
        assert(formatter.cwd(nil, context) == project)
        vim.fn.delete(project .. "/" .. name)
    end

    -- A nested project owns its configuration even when the parent also has one.
    vim.fn.writefile({ "{}" }, project .. "/dprint.json")
    vim.fn.writefile({ "{}" }, project .. "/docs/.dprint.jsonc")
    assert(formatter.cwd(nil, context) == context.dirname)
    vim.fn.delete(project .. "/docs/.dprint.jsonc")

    local fallback_calls = 0
    package.loaded["conform.util"] = {
        from_node_modules = function(name)
            assert(name == "dprint")
            return function(_, ctx)
                assert(ctx.dirname == context.dirname)
                fallback_calls = fallback_calls + 1
                return "node_modules/.bin/dprint"
            end
        end,
    }
    assert(formatter.command(nil, context) == "node_modules/.bin/dprint")

    local pinned = project .. "/.dev-tools/bin/dprint"
    vim.fn.writefile({ "#!/bin/sh", "exit 0" }, pinned)
    vim.fn.setfperm(pinned, "rwxr-xr-x")
    assert(formatter.command(nil, context) == pinned, "project-pinned dprint must take precedence")
    assert(fallback_calls == 1)

    -- A project's dprint installation must never reroute native buffer formatters.
    expect_native_routes()

    -- A nearer config cannot accidentally borrow the parent's pinned executable.
    vim.fn.writefile({ "{}" }, project .. "/docs/.dprint.jsonc")
    assert(formatter.command(nil, context) == "node_modules/.bin/dprint")
    assert(fallback_calls == 2)
    expect_native_routes()
    vim.fn.delete(project .. "/docs/.dprint.jsonc")

    -- Config discovery uses the buffer directory, not the editor's cwd.
    local outside = { dirname = project .. "-outside" }
    assert(
        formatter.cwd(nil, outside) == outside.dirname,
        "outside config must not inherit a project root"
    )
end

local ok, failure = xpcall(check, debug.traceback)

vim.fn.delete(project, "rf")

assert(ok, failure)
print("PASS: project configuration and pinned executable precedence")
vim.cmd("qa!")
