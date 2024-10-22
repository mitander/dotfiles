return {
    event = { "BufReadPre", "BufNewFile" },
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
        scope = {
            enabled = false,
        },
        indent = {
            char = "▎",
        },
        exclude = {
            filetypes = {
                "lazy",
                "NvimTree",
                "terminal",
                "vimwiki",
                "man",
                "gitmessengerpopup",
                "diagnosticpopup",
                "lspinfo",
                "packer",
                "checkhealth",
                "TelescopePrompt",
                "TelescopeResults",
                "",
            },
            buftypes = {
                "nofile",
                "terminal",
                "lsp-installer",
                "lspinfo",
                "fzf",
            },
        },
    },
}
