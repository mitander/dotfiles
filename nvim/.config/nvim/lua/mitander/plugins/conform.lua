local dprint_configs = { "dprint.json", ".dprint.json", "dprint.jsonc", ".dprint.jsonc" }

local function project_dprint_config(dirname)
    return vim.fs.find(dprint_configs, { path = dirname, upward = true })[1]
end

local function pinned_dprint(dirname)
    local config = project_dprint_config(dirname)
    local command = config and vim.fs.dirname(config) .. "/.dev-tools/bin/dprint"
    return command and vim.fn.executable(command) == 1 and command or nil
end

-- Rust/Python repositories with a local dprint binary own their native tool pins.
local function native_or_pinned(formatters)
    return function(bufnr)
        local dirname = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
        return pinned_dprint(dirname) and { "dprint" } or formatters
    end
end

return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true, lsp_format = "never" })
            end,
            mode = { "n", "v" },
            desc = "Format buffer",
        },
    },
    opts = {
        notify_on_error = true,
        notify_no_formatters = false,
        formatters_by_ft = {
            lua = { "stylua" },
            python = native_or_pinned({ "ruff_organize_imports", "ruff_format" }),
            zig = { "zigfmt" },
            rust = native_or_pinned({ "rustfmt" }),
            go = { "gofmt", "goimports" },
            gleam = { "gleam" },
            javascript = { "dprint" },
            typescript = { "dprint" },
            javascriptreact = { "dprint" },
            typescriptreact = { "dprint" },
            json = { "dprint" },
            jsonc = { "dprint" },
            yaml = { "dprint" },
            markdown = { "dprint" },
            html = { "dprint" },
            css = { "dprint" },
            scss = { "dprint" },
            c = { "clang_format" },
            cpp = { "clang_format" },
            sh = { "dprint" },
            bash = { "dprint" },
            zsh = { "dprint" },
            fish = { "fish_indent" },
            toml = { "dprint" },
            -- The dprint Nix plugin uses nixfmt-rs, not this checkout's Alejandra style.
            nix = { "alejandra" },
        },
        default_format_opts = {
            lsp_format = "never",
        },
        -- Keep saves bounded. Slow formatting remains available via <leader>f.
        format_on_save = { timeout_ms = 500 },
        formatters = {
            fish_indent = { command = vim.fn.expand("~/.nix-profile/bin/fish_indent") },
            goimports = { prepend_args = { "-local", "github.com" } },
            zigfmt = {
                command = function(_, ctx)
                    local root = vim.fs.root(ctx.buf, { "build.zig", ".git" }) or vim.fn.getcwd()
                    local command = root .. "/zig/zig"
                    return vim.fn.executable(command) == 1 and command or "zig"
                end,
                args = { "fmt", "--stdin" },
            },
            dprint = {
                command = function(self, ctx)
                    return pinned_dprint(ctx.dirname)
                        or require("conform.util").from_node_modules("dprint")(self, ctx)
                end,
                -- Let dprint resolve project config first, then its global fallback.
                cwd = function(_, ctx)
                    local config = project_dprint_config(ctx.dirname)
                    return config and vim.fs.dirname(config) or ctx.dirname
                end,
            },
        },
    },
    init = function()
        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
}
