return {
    {
        "williamboman/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUpdate" },
        keys = {
            { "<leader>m", "<cmd>Mason<cr>", desc = "Mason" },
        },
        opts = {
            ui = {
                border = "single",
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
            keymaps = {
                toggle_server_expand = "<enter>",
                install_server = "i",
                update_server = "u",
                check_server_version = "c",
                update_all_servers = "U",
                check_outdated_servers = "C",
                uninstall_server = "X",
            },
            max_concurrent_installers = 10,
        },
        init = function()
            -- Prefer Mason tools over system versions.
            local is_windows = vim.uv.os_uname().sysname == "Windows_NT"
            vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH
        end,
    },
}

