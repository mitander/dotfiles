return {
    "folke/todo-comments.nvim",
    opts = { signs = false },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function(_, opts)
        local todo = require("todo-comments")
        todo.setup(opts)

        vim.keymap.set("n", "<leader>t", "<cmd>TodoFzfLua<enter>")
        vim.keymap.set("n", "]t", function()
            todo.jump_next()
        end)
        vim.keymap.set("n", "[t", function()
            todo.jump_prev()
        end)
    end,
}
