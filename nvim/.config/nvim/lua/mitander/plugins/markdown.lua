return {
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
