return {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts = {
        signs = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "▎" },
            topdelete = {
                text = "▎",
            },
            changedelete = {
                text = "▎",
            },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
            interval = 1000,
            follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false,
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,
        preview_config = {
            border = "single",
            style = "minimal",
            relative = "cursor",
            row = 0,
            col = 1,
        },
    },
    config = function(_, opts)
        require("gitsigns").setup(opts)

        vim.keymap.set("n", "gp", require("gitsigns").preview_hunk_inline)
        vim.keymap.set("n", "g.", require("gitsigns").toggle_signs)
        vim.keymap.set("n", "[g", require("gitsigns").prev_hunk)
        vim.keymap.set("n", "]g", require("gitsigns").next_hunk)
        vim.keymap.set("n", "g,", require("gitsigns").toggle_current_line_blame)
        vim.keymap.set("n", "gl", require("gitsigns").blame_line)
        vim.keymap.set("n", "<leader><bs>", require("gitsigns").reset_hunk)
    end,
}
