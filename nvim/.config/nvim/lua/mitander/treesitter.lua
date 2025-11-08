return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
        { "<leader>ti", "<cmd>TSConfigInfo<cr>", desc = "Treesitter info" },
    },
    opts = {
        ensure_installed = {
            "go",
            "zig",
            "rust",
            "lua",
            "vim",
            "vimdoc",
            "python",
            "c",
            "cpp",
            "javascript",
            "typescript",
            "json",
            "toml",
            "yaml",
            "bash",
            "fish",
            "markdown",
            "markdown_inline",
            "comment",
        },
        auto_install = false,
        sync_install = false,
        highlight = {
            enable = true,
            use_languagetree = true,
            disable = function(lang, buf)
                -- Disable for large files
                local max_filesize = 100 * 1024 -- 100 KB
                local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                if ok and stats and stats.size > max_filesize then
                    return true
                end
            end,
            additional_vim_regex_highlighting = false,
        },
        indent = {
            enable = true,
            disable = { "python" }, -- Python indentation is better handled by LSP
        },
        -- incremental_selection = {
        --     enable = true,
        --     keymaps = {
        --         init_selection = "<CR>",
        --         node_incremental = "<CR>",
        --         scope_incremental = false,
        --         node_decremental = "<BS>",
        --     },
        -- },
    },
    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end,
}
