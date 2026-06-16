local function cargo_keymaps(bufnr)
    local crates = require("crates")
    local opts = { buffer = bufnr, remap = false, silent = true }

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
    vim.keymap.set("n", "<leader>cH", crates.open_homepage, opts)
    vim.keymap.set("n", "<leader>cR", crates.open_repository, opts)
    vim.keymap.set("n", "<leader>cD", crates.open_documentation, opts)
    vim.keymap.set("n", "<leader>cC", crates.open_crates_io, opts)
    vim.keymap.set("n", "<leader>cL", crates.open_lib_rs, opts)
end

return {
    { "nvim-lua/plenary.nvim", lazy = true },
    {
        "saecki/crates.nvim",
        event = { "BufReadPost Cargo.toml", "BufNewFile Cargo.toml" },
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
                },
                lsp = {
                    enabled = true,
                    actions = true,
                    completion = true,
                    hover = true,
                },
            })

            if vim.fn.expand("%:t") == "Cargo.toml" then
                cargo_keymaps(0)
            end

            vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
                pattern = "Cargo.toml",
                callback = function(args)
                    cargo_keymaps(args.buf)
                end,
            })
        end,
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
