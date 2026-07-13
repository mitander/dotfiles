local quiet_cmdline_commands = {
    q = true,
    qa = true,
    qall = true,
    quit = true,
    w = true,
    wa = true,
    wall = true,
    write = true,
    wq = true,
    wqa = true,
    wqall = true,
    x = true,
    xa = true,
    xall = true,
    exit = true,
    xit = true,
}

local function should_show_cmdline_menu(ctx)
    if vim.fn.getcmdtype() ~= ":" then
        return false
    end

    local line = vim.trim(ctx.line or "")
    if line == "" then
        return false
    end

    -- Keep routine, complete write/quit commands quiet. This is intentionally
    -- an exact allowlist: partial and unrelated short commands still complete.
    local command = line:match("^([%a]+)!?$")
    return not (command and quiet_cmdline_commands[command:lower()])
end

return {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
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
        cmdline = {
            keymap = {
                -- The cmdline preset does not inherit the top-level <CR> map.
                -- Accept the highlighted item and execute it in one keypress.
                ["<CR>"] = { "accept_and_enter", "fallback" },
            },
            completion = {
                menu = {
                    auto_show = should_show_cmdline_menu,
                },
            },
        },
        completion = {
            list = {
                selection = {
                    -- Start unselected; preview only after explicit menu navigation.
                    preselect = false,
                    auto_insert = true,
                },
            },
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
            enabled = false,
        },
    },
}
