return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "j-hui/fidget.nvim",
    },
    config = function()
        local cmp = require('cmp')
        local cmp_lsp = require("cmp_nvim_lsp")
        local luasnip = require("luasnip")
        local lspconfig = require("lspconfig")
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities())
        require("fidget").setup({})

        vim.diagnostic.config {
            virtual_text = true,
            update_in_insert = false,
            underline = true,
            severity_sort = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "single",
                header = "",
                prefix = "",
            },
        }

        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "single" })
        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help,
            { border = "single" })

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
                on_attach = function(_, bufnr)
                    local opts = { buffer = bufnr, remap = false }
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "ga", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                    vim.keymap.set("n", "go", vim.diagnostic.open_float, opts)
                    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
                    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
                    vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set("n", "<leader>s", vim.lsp.buf.signature_help, opts)
                    vim.keymap.set("n", "<leader>i", function()
                        vim.lsp.inlay_hint.enable(0, not vim.lsp.inlay_hint.is_enabled())
                    end, opts)
                end,
                capabilities = capabilities,
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

        cmp.setup({
            window = {
                completion = {
                    side_padding = 0,
                    scrollbar = false,
                },
            },
            formatting = {
                fields = { "kind", "abbr", "menu" },
                format = function(_, vim_item)
                    local kind_icons = {
                        Text          = "󰊄",
                        Method        = "󰊕",
                        Function      = "",
                        Constructor   = "",
                        Field         = "",
                        Variable      = "󰆧",
                        Class         = "󰌗",
                        Interface     = "",
                        Module        = "󰅩",
                        Property      = "",
                        Unit          = "󰜫",
                        Value         = "󰎠",
                        Enum          = "󰘨",
                        EnumMember    = "",
                        Keyword       = "󰌆",
                        Snippet       = "󰘍",
                        Color         = "󰏘",
                        File          = "",
                        Folder        = "",
                        Reference     = "󰆑",
                        Constant      = "󰏿",
                        Struct        = "󰙅",
                        Event         = "",
                        Operator      = "󰒕",
                        TypeParameter = "",
                    }
                    vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
                    return vim_item
                end,
            },
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            confirm_opts = {
                behavior = cmp.ConfirmBehavior.Replace,
                select = true,
            },
            experimental = {
                ghost_text = false,
                native_menu = false,
            },
            completion = {
                keyword_length = 1,
            },
            sources = {
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "buffer" },
                { name = "path" },
            },
            mapping = cmp.mapping.preset.insert({
                ["<C-k>"] = cmp.mapping.select_prev_item(),
                ["<C-j>"] = cmp.mapping.select_next_item(),
                ["<C-p>"] = cmp.mapping.select_prev_item(),
                ["<C-n>"] = cmp.mapping.select_next_item(),
                ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
                ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
                ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
                ["<C-y>"] = cmp.config.disable,
                ["<C-e>"] = cmp.mapping { i = cmp.mapping.abort(), c = cmp.mapping.close() },
                ["<CR>"] = cmp.mapping.confirm { select = false },
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.locally_jumpable(1) then
                        luasnip.jump(1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),

                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.locally_jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),

            }),
        })
    end
}
