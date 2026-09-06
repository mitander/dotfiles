-- NvimTree owns the sidebar. Oil edits directories in the current window.
return {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
        {
            "-",
            function()
                require("oil").open()
            end,
            desc = "Edit parent directory",
        },
    },
    opts = {
        default_file_explorer = true,
        columns = { "icon" },
        win_options = {
            wrap = false,
            number = false,
            relativenumber = false,
            signcolumn = "no",
            cursorcolumn = false,
            foldcolumn = "0",
            spell = false,
            list = false,
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        prompt_save_on_select_new_entry = true,
        lsp_file_methods = {
            enabled = true,
            timeout_ms = 1000,
            autosave_changes = false,
        },
        watch_for_changes = false,
        keymaps = {
            ["<bs>"] = "actions.parent",
            ["q"] = "actions.close",
            ["<C-h>"] = false,
            ["<C-l>"] = false,
            ["<C-p>"] = false,
            ["."] = "actions.open_cwd",
            ["~"] = "actions.cd",
        },
        view_options = {
            show_hidden = true,
        },
    },
}
