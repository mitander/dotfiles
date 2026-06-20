return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
        panel = {
            enabled = false,
        },
        suggestion = {
            enabled = true,
            auto_trigger = true,
            hide_during_completion = true,
            debounce = 75,
            keymap = {
                accept = "<M-l>",
                accept_word = "<M-w>",
                accept_line = "<M-L>",
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
                toggle_auto_trigger = "<M-\\>",
            },
        },
        -- Keep this off for now: Copilot's next-edit-suggestion support is
        -- still experimental and was causing duplicate keymap / agent-service
        -- initialization warnings. Inline autocomplete remains enabled above.
        nes = {
            enabled = false,
        },
        filetypes = {
            markdown = true,
            yaml = true,
            gitcommit = true,
            sh = function()
                return not vim.fs.basename(vim.api.nvim_buf_get_name(0)):match("^%.env")
            end,
        },
    },
    config = function(_, opts)
        require("copilot").setup(opts)

        -- Keep Copilot ghost text out of the way while blink.cmp's menu is open.
        vim.api.nvim_create_autocmd("User", {
            pattern = "BlinkCmpMenuOpen",
            callback = function()
                vim.b.copilot_suggestion_hidden = true
            end,
        })
        vim.api.nvim_create_autocmd("User", {
            pattern = "BlinkCmpMenuClose",
            callback = function()
                vim.b.copilot_suggestion_hidden = false
            end,
        })

        vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#6b7280", italic = true })
        vim.api.nvim_set_hl(0, "CopilotAnnotation", { fg = "#6b7280" })
    end,
}
