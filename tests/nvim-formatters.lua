-- Run with: nvim --clean --headless -l tests/nvim-formatters.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config_dir = root .. "/nvim/.config/nvim"
local opts = dofile(config_dir .. "/lua/mitander/plugins/conform.lua").opts
local project = vim.fn.tempname()
vim.fn.mkdir(project .. "/docs", "p")
vim.fn.mkdir(project .. "/.dev-tools/bin", "p")

local buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(buffer, project .. "/docs/example.rs")
local function expect_native_routes(rust, python)
    assert(vim.deep_equal(opts.formatters_by_ft.rust(buffer), rust))
    assert(vim.deep_equal(opts.formatters_by_ft.python(buffer), python))
end
expect_native_routes({ "rustfmt" }, { "ruff_organize_imports", "ruff_format" })

local formatter = opts.formatters.dprint
local context = { dirname = project .. "/docs" }
assert(not formatter.args, "inherit dprint's stdin arguments and native global/project config discovery")
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
expect_native_routes({ "dprint" }, { "dprint" })
-- A nearer config cannot accidentally borrow the parent's pinned executable.
vim.fn.writefile({ "{}" }, project .. "/docs/.dprint.jsonc")
expect_native_routes({ "rustfmt" }, { "ruff_organize_imports", "ruff_format" })
vim.fn.delete(project .. "/docs/.dprint.jsonc")

-- Config discovery uses the buffer directory, not the editor's cwd.
local outside = { dirname = project .. "-outside" }
assert(formatter.cwd(nil, outside) == outside.dirname)

vim.fn.delete(project, "rf")
print("PASS: project configuration and pinned executable precedence")
vim.cmd("qa!")
