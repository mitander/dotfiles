return {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TodoFzfLua", "TodoQuickFix", "TodoLocList" },
    keys = {
        { "<leader>t", "<cmd>TodoFzfLua<cr>", desc = "Todo comments" },
        {
            "]t",
            function()
                require("todo-comments").jump_next()
            end,
            desc = "Next todo comment",
        },
        {
            "[t",
            function()
                require("todo-comments").jump_prev()
            end,
            desc = "Previous todo comment",
        },
    },
    opts = { signs = false },
    dependencies = { "nvim-lua/plenary.nvim" },
}
