return {
    {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = "markdown",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<leader>vm", "<cmd>RenderMarkdown buf_toggle<cr>", desc = "Toggle Markdown rendering" },
        },
        opts = {
            ignore = function(bufnr)
                return require("mitander.buffer_limits").is_large(bufnr)
            end,
            render_modes = { "n", "c" },
            sign = { enabled = false },
            heading = { width = "block" },
            code = { width = "block", sign = false },
            latex = { enabled = false },
        },
    },
    {
        "brianhuster/live-preview.nvim",
        cmd = "LivePreview",
        keys = {
            { "<leader>vp", "<cmd>LivePreview start<cr>", desc = "Open browser preview" },
            { "<leader>vs", "<cmd>LivePreview close<cr>", desc = "Stop browser preview" },
        },
        config = function()
            require("livepreview.config").set({ address = "127.0.0.1", sync_scroll = true })
            require("mitander.preview").setup()
        end,
    },
}
