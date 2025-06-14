return {
    { "nvim-lua/plenary.nvim", name = "plenary" },
    { "fatih/vim-go", ft = "go" },
    { "ziglang/zig.vim", ft = "zig" },
    { "dag/vim-fish", ft = "fish" },
    { "rust-lang/rust.vim", ft = "rust" },
    {
        "saecki/crates.nvim",
        tag = "stable",
        lazy = false,
        config = function()
            require("crates").setup({
                autoupdate_throttle = 50,
                max_parallel_requests = 32,
                popup = {
                    show_version_date = true,
                },
                completion = {
                    crates = {
                        enabled = true,
                        max_results = 30,
                    },
                    cmp = {
                        use_custom_kind = true,
                    },
                },
                lsp = {
                    enabled = true,
                    actions = true,
                    completion = true,
                    hover = true,
                    on_attach = function()
                        local opts = { buffer = bufnr, remap = false }
                        local crates = require("crates")

                        vim.keymap.set("n", "<leader>ct", crates.toggle, opts)
                        vim.keymap.set("n", "<leader>cr", crates.reload, opts)

                        vim.keymap.set("n", "<leader>cv", crates.show_versions_popup, opts)
                        vim.keymap.set("n", "<leader>cf", crates.show_features_popup, opts)
                        vim.keymap.set("n", "<leader>cd", crates.show_dependencies_popup, opts)

                        vim.keymap.set("n", "<leader>cu", crates.update_crate, opts)
                        vim.keymap.set("v", "<leader>cu", crates.update_crates, opts)
                        vim.keymap.set("n", "<leader>ca", crates.update_all_crates, opts)
                        vim.keymap.set("n", "<leader>cU", crates.upgrade_crate, opts)
                        vim.keymap.set("v", "<leader>cU", crates.upgrade_crates, opts)
                        vim.keymap.set("n", "<leader>cA", crates.upgrade_all_crates, opts)

                        vim.keymap.set("n", "<leader>cx", crates.expand_plain_crate_to_inline_table, opts)
                        vim.keymap.set("n", "<leader>cX", crates.extract_crate_into_table, opts)

                        vim.keymap.set("n", "<leader>cH", crates.open_homepage, opts)
                        vim.keymap.set("n", "<leader>cR", crates.open_repository, opts)
                        vim.keymap.set("n", "<leader>cD", crates.open_documentation, opts)
                        vim.keymap.set("n", "<leader>cC", crates.open_crates_io, opts)
                        vim.keymap.set("n", "<leader>cL", crates.open_lib_rs, opts)
                    end,
                },
            })
        end,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        opts = {},
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && yarn install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    },
}
