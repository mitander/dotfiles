local cmp_ok, cmp = pcall(require, "cmp")
if not cmp_ok then
    print "error: could not load cmp"
    return
end

local snip_ok, luasnip = pcall(require, "luasnip")
if not snip_ok then
    print "error: could not load luasnip"
    return
end

local check_backspace = function()
    local col = vim.fn.col "." - 1
    return col == 0 or vim.fn.getline("."):sub(col, col):match "%s"
end

require("luasnip/loaders/from_vscode").lazy_load()

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


cmp.setup.cmdline("/", {
    view = {
        entries = { name = "wildmenu", separator = "|" },
    },
})

cmp.setup {
    window = {
        completion = {
            side_padding = 0,
            scrollbar = false,
            -- winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel",
        },
    },
    formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(_, vim_item)
            vim_item.kind = string.format("%s", kind_icons[vim_item.kind])
            return vim_item
        end,
    },
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    duplicates = {
        nvim_lsp = 1,
        luasnip = 1,
        cmp_tabnine = 1,
        buffer = 1,
        path = 1,
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
    mapping = {
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
            if luasnip.jumpable() then
                luasnip.jump(1)
            else
                fallback()
            end
        end, {
            "i",
            "s",
        }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.jumpable() then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, {
            "i",
            "s",
        }),
    },
}
