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
        local gitsigns = require("gitsigns")
        gitsigns.setup(opts)

        local function jump_change(direction)
            local state = package.loaded["diffbandit.state"]
            local session = state and state.sessions[vim.api.nvim_get_current_tabpage()]
            local method = direction == "next" and "goto_next_chunk" or "goto_prev_chunk"

            if session and type(session[method]) == "function" then
                session[method](session)
                return
            end

            if session and type(session.goto_diff) == "function" then
                session:goto_diff(direction == "next" and 1 or -1)
                return
            end

            gitsigns[direction .. "_hunk"]()
        end

        vim.keymap.set("n", "gp", gitsigns.preview_hunk_inline)
        vim.keymap.set("n", "g.", gitsigns.toggle_signs)
        vim.keymap.set("n", "[g", function()
            jump_change("prev")
        end, { desc = "Previous Git change" })
        vim.keymap.set("n", "]g", function()
            jump_change("next")
        end, { desc = "Next Git change" })
        vim.keymap.set("n", "g,", require("gitsigns").toggle_current_line_blame)
        vim.keymap.set("n", "gl", require("gitsigns").blame_line)
        vim.keymap.set("n", "<leader><bs>", require("gitsigns").reset_hunk)
    end,
}
