return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    config = function()
        require("nvim-treesitter.configs").setup({
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
                "markdown",
                "vimdoc",
            },
            auto_install = true,
            sync_install = true,
            highlight = {
                enable = true,
                use_languagetree = false,
                additional_vim_regex_highlighting = { "markdown" },
            },
            context_commentstring = {
                enable = true,
                enable_autocmd = false,
            },
            incremental_selection = {
                enable = false,
            },
        })
    end,
}
