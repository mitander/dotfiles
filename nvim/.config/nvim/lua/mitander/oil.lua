return {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
        default_file_explorer = true,
        columns = {},
        buf_options = {
            buflisted = false,
            bufhidden = "hide",
        },
        win_options = {
            wrap = false,
            signcolumn = "no",
            cursorcolumn = false,
            foldcolumn = "0",
            spell = false,
            list = false,
            conceallevel = 3,
            concealcursor = "nvic",
        },
        delete_to_trash = false,
        skip_confirm_for_simple_edits = false,
        prompt_save_on_select_new_entry = true,
        cleanup_delay_ms = 2000,
        lsp_file_methods = {
            enabled = true,
            timeout_ms = 1000,
            autosave_changes = false,
        },
        constrain_cursor = "editable",
        watch_for_changes = false,
        keymaps = {
            ["<enter>"] = "actions.select",
            ["<bs>"] = "actions.parent",
            ["<c-p>"] = "actions.preview",
            ["<c-n>"] = "actions.close",
            ["q"] = "actions.close",
            ["."] = "actions.open_cwd",
            ["~"] = "actions.cd",
            ["<c-s>"] = {
                "actions.select",
                opts = { vertical = true },
                desc = "Open the entry in a vertical split",
            },
            ["<c-v>"] = {
                "actions.select",
                opts = { horizontal = true },
                desc = "Open the entry in a horizontal split",
            },
        },
        use_default_keymaps = true,
        view_options = {
            show_hidden = true,
            is_hidden_file = function(name, _)
                return vim.startswith(name, ".")
            end,
            is_always_hidden = function(_, _)
                return false
            end,
            natural_order = true,
            case_insensitive = false,
            sort = {
                { "type", "asc" },
                { "name", "asc" },
            },
        },
    },
    config = function(_, opts)
        vim.keymap.set("n", "<c-n>", "<cmd>Oil<enter>")
        require("oil").setup(opts)
    end,
}
