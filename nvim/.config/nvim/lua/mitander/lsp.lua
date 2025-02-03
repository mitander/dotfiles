return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "L3MON4D3/LuaSnip",
        {
            "j-hui/fidget.nvim",
            config = true,
        },
    },
    opts = {
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        flags = {
            debounce_text_changes = 150,
        },
        servers = {
            zls = {},
            gopls = {},
            jsonls = {},
            clangd = {},
            rust_analyzer = {
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
            },
            lua_ls = {
                Lua = {
                    diagnostics = {
                        globals = { "vim", "augroup" },
                    },
                    workspace = {
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                            [vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
                        },
                    },
                },
            },
        },
    },
    config = function(_, opts)
        local lsp = require("lspconfig")
        local cmp = require("cmp_nvim_lsp")

        opts.capabilities =
            vim.tbl_deep_extend("force", {}, vim.lsp.protocol.make_client_capabilities(), cmp.default_capabilities())
        vim.inspect(opts.capabilities)

        vim.diagnostic.config({
            virtual_text = true,
            update_in_insert = false,
            underline = true,
            severity_sort = true,
        })

        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "single" })
        vim.lsp.handlers["textDocument/signatureHelp"] =
            vim.lsp.with(vim.lsp.handlers.signature_help, { border = "single" })

        local group = vim.api.nvim_create_augroup("LspSetup", {})

        vim.api.nvim_create_autocmd("LspAttach", {
            pattern = "*",
            group = group,
            callback = function(args)
                local map_opts = { buffer = args.buf, remap = false }
                vim.keymap.set("i", "<c-s>", vim.lsp.buf.signature_help, map_opts)
                vim.keymap.set("n", "K", vim.lsp.buf.hover, map_opts)
                vim.keymap.set("n", "ga", vim.lsp.buf.code_action, map_opts)
                vim.keymap.set("n", "gr", vim.lsp.buf.references, map_opts)
                vim.keymap.set("n", "gd", vim.lsp.buf.definition, map_opts)
                vim.keymap.set("n", "gi", vim.lsp.buf.implementation, map_opts)
                vim.keymap.set("n", "go", vim.diagnostic.open_float, map_opts)
                -- TODO: this bricks diagnostic jumping somehow
                -- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, map_opts)
                -- vim.keymap.set("n", "]d", vim.diagnostic.goto_next, map_opts)
                vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, map_opts)
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, map_opts)
                vim.keymap.set("n", "<leader>s", vim.lsp.buf.signature_help, map_opts)
                vim.keymap.set("n", "<leader>i", function()
                    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
                end, map_opts)
            end,
        })

        for k, v in pairs(opts.servers) do
            lsp[k].setup(vim.tbl_deep_extend("force", opts, v))
        end
    end,
}
