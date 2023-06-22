local ok, configs = pcall(require, "nvim-treesitter.configs")
if not ok then
    print "error: could not load nvim-treesitter.configs"
    return
end

configs.setup {
    ensure_installed = {
        "go",
        "zig",
        "rust",
        "lua",
        "vim",
        "python",
        "c",
        "cpp",
        "javascript",
        "typescript",
        "comment",
    },
    sync_install = false,
    highlight = {
        enable = true,
        use_languagetree = true,
    },
    context_commentstring = {
        enable = true,
        enable_autocmd = false,
    },
    incremental_selection = {
        enable = false,
    },
    indent = { enable = true },
}

require("treesitter-context").setup {
    enable = true,
    throttle = true,
    max_lines = 0,
    patterns = {
        default = {
            "class",
            "function",
            "method",
        },

        zig = {
            "TopLevelDecl",
            "Statement",
            "SwitchProng",
        },
    },
}
