return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
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
        textobjects = {
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = "@class.inner",
                    ["aa"] = "@parameter.outer",
                    ["ia"] = "@parameter.inner",
                },
            },
            move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                    ["]f"] = "@function.outer",
                    ["]c"] = "@class.outer",
                },
                goto_next_end = {
                    ["]F"] = "@function.outer",
                    ["]C"] = "@class.outer",
                },
                goto_previous_start = {
                    ["[f"] = "@function.outer",
                    ["[c"] = "@class.outer",
                },
                goto_previous_end = {
                    ["[F"] = "@function.outer",
                    ["[C"] = "@class.outer",
                },
            },
        },
    },
    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)
    end,
}
