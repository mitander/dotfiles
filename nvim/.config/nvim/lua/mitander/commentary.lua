return {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("Comment").setup({
            padding = true,
            sticky = true,
            ignore = "^$",
            toggler = {
                line = "gcc",
                block = "gbc",
            },
            opleader = {
                line = "gc",
                block = "gb",
            },
            mappings = {
                basic = true,
                extra = false,
            },
        })

        -- Preserve <leader>/ keymap for commenting
        vim.keymap.set("n", "<leader>/", "gcc", { remap = true, silent = true })
        vim.keymap.set("v", "<leader>/", "gc", { remap = true, silent = true })
    end,
}
