return {
    "lewis6991/gitsigns.nvim",
    init = function()
        vim.api.nvim_create_autocmd({ "BufRead" }, {
            group = vim.api.nvim_create_augroup("GitSignsLazyLoad", { clear = true }),
            callback = function()
                vim.fn.system("git -C " .. '"' .. vim.fn.expand "%:p:h" .. '"' .. " rev-parse")
                if vim.v.shell_error == 0 then
                    vim.api.nvim_del_augroup_by_name "GitSignsLazyLoad"
                    vim.schedule(function()
                        require("lazy").load { plugins = { "gitsigns.nvim" } }
                    end)
                end
            end,
        })
    end,
    config = function()
        require("gitsigns").setup({
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
        })

        vim.keymap.set("n", "gp", require("gitsigns").preview_hunk_inline)
        vim.keymap.set("n", "g.", require("gitsigns").toggle_signs)
        vim.keymap.set("n", "[g", require("gitsigns").prev_hunk)
        vim.keymap.set("n", "]g", require("gitsigns").next_hunk)
        vim.keymap.set("n", "g,", require("gitsigns").toggle_current_line_blame)
        vim.keymap.set("n", "gl", require("gitsigns").blame_line)
        vim.keymap.set("n", "<leader><bs>", require("gitsigns").reset_hunk)
    end,
}
