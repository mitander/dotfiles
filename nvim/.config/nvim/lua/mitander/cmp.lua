return {
    "saghen/blink.cmp",
    lazy = false,
    dependencies = "rafamadriz/friendly-snippets",
    version = "v0.*",
    opts = {
        keymap = {
            preset = "none",
            ["<C-k>"] = { "select_prev", "fallback" },
            ["<C-j>"] = { "select_next", "fallback" },
            ["<C-u>"] = { "scroll_documentation_up", "fallback" },
            ["<C-d>"] = { "scroll_documentation_down", "fallback" },
            ["<C-e>"] = { "hide", "fallback" },
            ["<CR>"] = { "accept", "fallback" },
            ["<Tab>"] = { "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "snippet_backward", "fallback" },
            ["<C-p>"] = { "select_prev", "fallback" },
            ["<C-n>"] = { "select_next", "fallback" },
        },
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = "mono",
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
            providers = {
                buffer = {
                    name = "Buffer",
                    module = "blink.cmp.sources.buffer",
                    opts = {
                        max_items = 5,
                    },
                },
                snippets = {
                    name = "Snippets",
                    module = "blink.cmp.sources.snippets",
                },
                path = {
                    name = "Path",
                    module = "blink.cmp.sources.path",
                    opts = {
                        trailing_slash = false,
                        label_trailing_slash = true,
                    },
                },
                lsp = {
                    name = "LSP",
                    module = "blink.cmp.sources.lsp",
                },
            },
        },
        completion = {
            accept = {
                auto_brackets = {
                    enabled = true,
                },
            },
            menu = {
                border = "single",
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
                scrolloff = 2,
                draw = {
                    columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
                    components = {
                        kind_icon = {
                            text = function(ctx)
                                local kind_icons = {
                                    Text = "󰊄",
                                    Method = "󰊕",
                                    Function = "",
                                    Constructor = "",
                                    Field = "",
                                    Variable = "󰆧",
                                    Class = "󰌗",
                                    Interface = "",
                                    Module = "󰅩",
                                    Property = "",
                                    Unit = "󰜫",
                                    Value = "󰎠",
                                    Enum = "󰘨",
                                    EnumMember = "",
                                    Keyword = "󰌆",
                                    Snippet = "󰘍",
                                    Color = "󰏘",
                                    File = "",
                                    Folder = "",
                                    Reference = "󰆑",
                                    Constant = "󰏿",
                                    Struct = "󰙅",
                                    Event = "",
                                    Operator = "󰒕",
                                    TypeParameter = "",
                                }
                                return kind_icons[ctx.kind] or ctx.kind
                            end,
                        },
                    },
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 200,
                window = {
                    border = "single",
                    winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
                },
            },
            ghost_text = {
                enabled = false,
            },
        },
        signature = {
            enabled = true,
            window = {
                border = "single",
            },
        },
    },
}
