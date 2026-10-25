return {
    {
        "stevearc/oil.nvim",
        -- Oil owns directory buffers. Startup loading keeps `nvim .` reliable.
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "-", "<cmd>Oil<cr>", desc = "Edit parent directory" },
            {
                "<C-n>",
                function()
                    require("mitander.file_browser").toggle()
                end,
                desc = "Toggle Oil sidebar",
            },
        },
        opts = {
            win_options = {
                number = false,
                relativenumber = false,
            },
            delete_to_trash = true,
            skip_confirm_for_simple_edits = true,
            keymaps = {
                ["<CR>"] = {
                    callback = function()
                        require("mitander.file_browser").select()
                    end,
                    desc = "Open entry",
                },
                ["<bs>"] = "actions.parent",
                ["q"] = {
                    callback = function()
                        require("mitander.file_browser").close()
                    end,
                    desc = "Close Oil",
                },
                ["<C-n>"] = {
                    callback = function()
                        require("mitander.file_browser").toggle()
                    end,
                    desc = "Toggle Oil sidebar",
                },
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
    },
    {
        "nvim-tree/nvim-tree.lua",
        lazy = true,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            {
                "<leader>n",
                function()
                    require("mitander.file_browser").toggle_tree()
                end,
                desc = "Toggle project tree and reveal current file",
            },
        },
        opts = {
            -- Oil handles directory buffers. The tree is an on-demand visual map.
            disable_netrw = false,
            hijack_netrw = false,
            hijack_directories = { enable = false },
            view = { width = 34 },
            git = { enable = false },
            filesystem_watchers = { enable = false },
            on_attach = function(buffer)
                local api = require("nvim-tree.api")
                api.map.on_attach.default(buffer)
                vim.keymap.set("n", "q", api.tree.close, { buffer = buffer, desc = "Close tree" })
            end,
        },
    },
}
