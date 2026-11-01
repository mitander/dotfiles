-- Run with: nvim --clean --headless -l tests/nvim-lsp.lua
-- Test tool ownership and LSP registration without plugins or language-server processes.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config = root .. "/nvim/.config/nvim"
local lsp_config, lsp_enable = vim.lsp.config, vim.lsp.enable

local function spec(name)
    return dofile(config .. "/lua/mitander/plugins/" .. name .. ".lua")
end

local function check()
    local blink = spec("blink")
    assert(blink.version == "1.*", "completion must track stable 1.x, not experimental main")
    assert(blink.opts.completion.list.selection.preselect == false)
    assert(blink.opts.completion.list.selection.auto_insert == true)
    assert(vim.deep_equal(blink.opts.keymap["<CR>"], { "accept", "fallback" }))
    assert(vim.deep_equal(blink.opts.cmdline.keymap["<CR>"], { "accept_and_enter", "fallback" }))

    local configured, enabled = {}, {}
    local capabilities =
        { textDocument = { completion = { completionItem = { snippetSupport = true } } } }
    package.loaded["blink.cmp"] = {
        get_lsp_capabilities = function()
            return capabilities
        end,
    }
    vim.lsp.config = function(name, opts)
        configured[name] = opts
    end
    vim.lsp.enable = function(name)
        enabled[name] = true
    end
    vim.g.mapleader = " "
    local lsp = spec("lsp")
    lsp.config(nil, lsp.opts)
    assert(
        configured.ts_ls and enabled.ts_ls,
        "TypeScript must use the installed ts_ls configuration"
    )
    assert(not configured.tsc and not enabled.tsc)
    assert(configured.lua_ls.capabilities.textDocument.completion.completionItem.snippetSupport)
    assert(
        not configured.rust_analyzer and not enabled.rust_analyzer,
        "Rust must have one LSP owner"
    )

    local rust = spec("rust")
    assert(rust.lazy == false and rust.version == "^9")
    rust.init()
    assert(type(vim.g.rustaceanvim) == "function", "Rust completion must initialize on demand")
    local rust_opts = vim.g.rustaceanvim()
    assert(rust_opts.server.capabilities.textDocument.completion.completionItem.snippetSupport)
    assert(not rust_opts.server.lspmux.enable)
    assert(not rust_opts.dap.autoload_configurations)
    assert(rust_opts.tools.test_executor == "background")

    local bufnr = vim.api.nvim_get_current_buf()
    local hints = {}
    vim.lsp.inlay_hint.enable = function(enable, opts)
        assert(opts.bufnr == bufnr)
        hints[#hints + 1] = enable
    end
    vim.lsp.inlay_hint.is_enabled = function(opts)
        assert(opts.bufnr == bufnr)
        return hints[#hints] or false
    end
    rust_opts.server.on_attach({}, bufnr)
    assert(#hints == 0, "Rust attachment must leave hints disabled by default")
    vim.api.nvim_exec_autocmds("LspAttach", { group = "LspSetup", buffer = bufnr })
    local hint_mapping = vim.fn.maparg(" i", "n", false, true)
    assert(hint_mapping.desc == "Toggle inlay hints")
    hint_mapping.callback()
    assert(hints[1] == true, "shared hint toggle must enable Rust hints")
    hint_mapping.callback()
    assert(hints[2] == false, "shared hint toggle must disable Rust hints")

    local commands = {}
    vim.api.nvim_create_user_command("RustLsp", function(opts)
        commands[#commands + 1] = { command = opts.args, bang = opts.bang }
    end, { nargs = "+", bang = true })
    for _, case in ipairs({
        { lhs = " cr", command = "runnables", bang = false },
        { lhs = " cR", command = "runnables", bang = true },
        { lhs = " ct", command = "testables", bang = false },
        { lhs = " cT", command = "testables", bang = true },
        { lhs = " cm", command = "expandMacro", bang = false },
    }) do
        local mapping = vim.fn.maparg(case.lhs, "n", false, true)
        assert(mapping.buffer == 1 and mapping.desc ~= nil)
        mapping.callback()
        assert(vim.deep_equal(commands[#commands], { command = case.command, bang = case.bang }))
    end
end

local ok, failure = xpcall(check, debug.traceback)
vim.lsp.config, vim.lsp.enable = lsp_config, lsp_enable
package.loaded["blink.cmp"] = nil
assert(ok, failure)
print("PASS: stable completion, single Rust LSP owner, Rust commands and native hints")
vim.cmd("qa!")
