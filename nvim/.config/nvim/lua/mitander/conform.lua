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
        notify_on_error = false,
        notify_no_formatters = false,
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "black" },
            zig = { "zigfmt" },
            rust = { "rustfmt", lsp_format = "fallback" },
            go = { "gofmt", "goimports" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
            javascriptreact = { "prettierd", "prettier", stop_after_first = true },
            typescriptreact = { "prettierd", "prettier", stop_after_first = true },
            json = { "prettierd", "prettier", stop_after_first = true },
            jsonc = { "prettierd", "prettier", stop_after_first = true },
            yaml = { "prettierd", "prettier", stop_after_first = true },
            markdown = { "prettierd", "prettier", stop_after_first = true },
            html = { "prettierd", "prettier", stop_after_first = true },
            css = { "prettierd", "prettier", stop_after_first = true },
            scss = { "prettierd", "prettier", stop_after_first = true },
            c = { "clang_format" },
            cpp = { "clang_format" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            fish = { "fish_indent" },
            toml = { "taplo" },
            ["*"] = { "trim_whitespace" },
        },
        default_format_opts = {
            lsp_format = "fallback",
        },
        format_on_save = { timeout_ms = 500 },
        formatters = {
            shfmt = {
                prepend_args = { "-i", "2" },
            },
            zigfmt = {
                command = "zig/zig",
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
