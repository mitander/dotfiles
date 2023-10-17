local ok, ibl = pcall(require, "ibl")
if not ok then
    print "error: could not load indent_blankline"
    return
end

ibl.setup {
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
