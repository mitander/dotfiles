return {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
    },
    opts = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        local border_opts = {
            border = "single",
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
            scrolloff = 2,
        }
        return {
            sources = {
                { name = "nvim_lua" },
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "path" },
            },
            window = {
                completion = cmp.config.window.bordered(border_opts),
                documentation = cmp.config.window.bordered(border_opts),
            },
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            formatting = {
                fields = { "kind", "abbr", "menu" },
                format = function(_, vim_item)
                    local kind_icons = {
                        Text = "󰊄",
                        Method = "󰊕",
                        Function = "",
                        Constructor = "",
                        Field = "",
                        Variable = "󰆧",
                        Class = "󰌗",
                        Interface = "",
                        Module = "󰅩",
                        Property = "",
                        Unit = "󰜫",
                        Value = "󰎠",
                        Enum = "󰘨",
                        EnumMember = "",
                        Keyword = "󰌆",
                        Snippet = "󰘍",
                        Color = "󰏘",
                        File = "",
                        Folder = "",
                        Reference = "󰆑",
                        Constant = "󰏿",
                        Struct = "󰙅",
                        Event = "",
                        Operator = "󰒕",
                        TypeParameter = "",
                    }
                    vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
                    local m = vim_item.menu and vim_item.menu or ""
                    if #m > 20 then
                        vim_item.menu = string.sub(m, 1, 20) .. "..."
                    end
                    return vim_item
                end,
            },
            mapping = cmp.mapping.preset.insert({
                ["<c-k>"] = cmp.mapping.select_prev_item(),
                ["<c-j>"] = cmp.mapping.select_next_item(),
                ["<c-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-1), { "i", "c" }),
                ["<c-d>"] = cmp.mapping(cmp.mapping.scroll_docs(1), { "i", "c" }),
                ["<c-e>"] = cmp.mapping({ i = cmp.mapping.abort(), c = cmp.mapping.close() }),
                ["<enter>"] = cmp.mapping.confirm({ select = false }),
                ["<tab>"] = cmp.mapping(function(fallback)
                    if luasnip.locally_jumpable(1) then
                        luasnip.jump(1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<s-tab>"] = cmp.mapping(function(fallback)
                    if luasnip.locally_jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<C-p>"] = cmp.mapping({
                    i = function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end,
                    c = function()
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            cmp.complete()
                        end
                    end,
                }),
                ["<C-n>"] = cmp.mapping({
                    i = function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end,
                    c = function()
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            cmp.complete()
                        end
                    end,
                }),
            }),
        }
    end,
    config = function(_, opts)
        local cmp = require("cmp")
        local cmp_config = require("cmp.config")

        cmp.setup(opts)
        cmp.setup.cmdline({ "/", "?" }, {
            mapping = cmp_config.get().mapping,
            sources = cmp.config.sources({ { name = "nvim_lsp_document_symbol" } }, { { name = "buffer" } }),
        })
        cmp.setup.cmdline(":", {
            mapping = cmp_config.get().mapping,
            sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
            sorting = { comparators = { cmp.config.compare.recently_used } },
            completion = { keyword_length = 2 },
        })
    end,
}
