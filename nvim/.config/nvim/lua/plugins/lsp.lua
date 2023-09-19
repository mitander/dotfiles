local keymaps = require "keymaps"

local cmp_ok, cmp = pcall(require, "cmp_nvim_lsp")
if not cmp_ok then
    print "error: could not load cmp_nvim_lsp"
    return
end

local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_ok then
    print "error: could not load lspconfig"
    return
end

local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn",  text = "" },
    { name = "DiagnosticSignHint",  text = "" },
    { name = "DiagnosticSignInfo",  text = "" },
}

for _, sign in ipairs(signs) do
    vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
end

vim.diagnostic.config {
    virtual_text = false,
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = {
        focusable = false,
        style = "minimal",
        border = "single",
        source = "always",
        header = "",
        prefix = "",
    },
}

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "single" })
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "single" })

local servers = {
    "clangd",
    "gopls",
    "rust_analyzer",
    "zls",
    "lua_ls",
    "jsonls",
}

for _, server in ipairs(servers) do
    local outer_opts = {
        on_attach = function(client, bufnr)
            keymaps.lsp(bufnr)
            client.server_capabilities.semanticTokensProvider = nil
        end,
        capabilities = cmp.default_capabilities(vim.lsp.protocol.make_client_capabilities()),
        flags = {
            debounce_text_changes = 150,
        },
    }

    if server == "lua_ls" then
        local opts = {
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim", "augroup" },
                    },
                    workspace = {
                        library = {
                            [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                            [vim.fn.stdpath "config" .. "/lua"] = true,
                            [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
                        },
                    },
                },
            },
        }
        outer_opts = vim.tbl_deep_extend("force", outer_opts, opts)
    end

    if server == "rust_analyzer" then
        local opts = {
            settings = {
                ["rust-analyzer"] = {
                    cargo = {
                        loadOutDirsFromCheck = true,
                    },
                    checkOnSave = {
                        command = "clippy",
                    },
                    experimental = {
                        procAttrMacros = true,
                    },
                },
            },
        }
        outer_opts = vim.tbl_deep_extend("force", outer_opts, opts)
    end

    if server == "clangd" then
        outer_opts.capabilities.offsetEncoding = { "utf-16" }
    end

    if server == "jsonls" then
        local opts = {
            setup = {
                commands = {
                    Format = {
                        function()
                            vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line "$", 0 })
                        end,
                    },
                },
            },
        }
        outer_opts = vim.tbl_deep_extend("force", outer_opts, opts)
    end

    lspconfig[server].setup(outer_opts)
end
