return {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    opts = {
        debounce = 100,
        viewport_buffer = {
            min = 120,
        },
        indent = {
            char = "▎",
            tab_char = "▎",
        },
        scope = {
            enabled = false,
        },
        exclude = {
            filetypes = {
                "help",
                "lazy",
                "mason",
                "notify",
                "oil",
                "qf",
                "terminal",
                "trouble",
                "checkhealth",
                "man",
                "lspinfo",
                "TelescopePrompt",
                "TelescopeResults",
                "",
            },
            buftypes = {
                "nofile",
                "terminal",
                "quickfix",
            },
        },
    },
}
