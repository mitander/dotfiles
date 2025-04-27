return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
        notify_on_error = false,
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "isort", "black" },
            zig = { "zigfmt" },
            rust = { "rustfmt", lsp_format = "fallback" },
            go = { "gofmt" },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            c = { "clang_format" },
            cpp = { "clang_format" },
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
        },
    },
    init = function()
        vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
        vim.g.zig_fmt_autosave = 0
    end,
}
