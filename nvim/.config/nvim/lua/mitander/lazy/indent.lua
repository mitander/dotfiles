return {
    lazy = false,
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
        require("ibl").setup {
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
            }
        }
    end,
}
