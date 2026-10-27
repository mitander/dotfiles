local dprint_configs = { "dprint.json", ".dprint.json", "dprint.jsonc", ".dprint.jsonc" }

local function project_dprint_config(dirname)
    return vim.fs.find(dprint_configs, { path = dirname, upward = true })[1]
end

local function pinned_dprint(dirname)
    local config = project_dprint_config(dirname)
    local command = config and vim.fs.dirname(config) .. "/.dev-tools/bin/dprint"
    return command and vim.fn.executable(command) == 1 and command or nil
end

-- Repositories with a Prettier config keep their exact style through the prettierd daemon.
-- dprint options cannot reproduce Prettier's line breaking, so others use the dprint defaults.
local prettier_or_dprint = { "prettierd", "dprint", stop_after_first = true }

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
            python = { "ruff_organize_imports", "ruff_format" },
            zig = { "zigfmt" },
            rust = { "rustfmt" },
            go = { "gofmt", "goimports" },
            gleam = { "gleam" },
            javascript = prettier_or_dprint,
            typescript = prettier_or_dprint,
            javascriptreact = prettier_or_dprint,
            typescriptreact = prettier_or_dprint,
            json = prettier_or_dprint,
            jsonc = prettier_or_dprint,
            yaml = prettier_or_dprint,
            markdown = prettier_or_dprint,
            html = prettier_or_dprint,
            css = prettier_or_dprint,
            scss = prettier_or_dprint,
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
            -- Unavailable without a Prettier config file or a package.json "prettier" key.
            prettierd = { require_cwd = true },
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
                -- dprint rejects absolute paths to files not yet on disk, such as a new file's first save.
                args = { "fmt", "--stdin", "$RELATIVE_FILEPATH" },
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
