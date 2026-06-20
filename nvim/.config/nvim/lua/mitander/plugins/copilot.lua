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
            hide_during_completion = false,
            debounce = 75,
            keymap = {
                accept = "<Tab>",
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

        -- Copilot owns <Tab>; blink.cmp owns <CR>.

        vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#6b7280", italic = true })
        vim.api.nvim_set_hl(0, "CopilotAnnotation", { fg = "#6b7280" })
    end,
}
