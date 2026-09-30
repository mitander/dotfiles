return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true, lsp_format = "fallback" })
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
            python = { "ruff_organize_imports", "ruff_format" },
            zig = { "zigfmt" },
            rust = { "rustfmt", lsp_format = "fallback" },
            go = { "gofmt", "goimports" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
            json = { "prettier" },
            jsonc = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            html = { "prettier" },
            css = { "prettier" },
            scss = { "prettier" },
            c = { "clang_format" },
            cpp = { "clang_format" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            fish = { "fish_indent" },
            toml = { "taplo" },
            nix = { "alejandra" },
            ["*"] = { "trim_whitespace" },
        },
        default_format_opts = {
            lsp_format = "fallback",
        },
        -- Keep saves bounded. Slow formatting remains available via <leader>f.
        format_on_save = { timeout_ms = 500 },
        formatters = {
            shfmt = {
                prepend_args = { "-i", "2" },
            },
            fish_indent = {
                command = vim.fn.expand("~/.nix-profile/bin/fish_indent"),
            },

            rustfmt = {
                prepend_args = function(_, ctx)
                    local config = vim.fs.find("rustfmt-nightly.toml", { path = ctx.dirname, upward = true })[1]
                    if config then
                        return { "+nightly-2026-07-03", "--config-path", config }
                    end
                    return {}
                end,
            },
            zigfmt = {
                command = function(_, ctx)
                    local root = vim.fs.root(ctx.buf, { "build.zig", ".git" }) or vim.fn.getcwd()
                    local local_zig = root .. "/zig/zig"
                    if vim.uv.fs_stat(local_zig) then
                        return local_zig
                    end
                    return "zig"
                end,
                args = { "fmt", "--stdin" },
            },
            goimports = {
                prepend_args = { "-local", "github.com" },
            },
        },
    },
    init = function()
        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
}
