return {
    {
        "williamboman/mason.nvim",
        lazy = false,
        opts = {
            log_level = vim.log.levels.INFO,
            PATH = "skip",
            ui = {
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
            -- add binaries installed by mason to path
            local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
            vim.env.PATH = vim.env.PATH .. (is_windows and ";" or ":") .. vim.fn.stdpath("data") .. "/mason/bin"
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        lazy = false,
        opts = {
            ensure_installed = {
                "clangd",
                "gopls",
                "rust_analyzer",
                "zls",
                "lua_ls",
                "jsonls",
            },
            ui = {
                keymaps = {
                    toggle_server_expand = "<enter>",
                    install_server = "i",
                    update_server = "u",
                    check_server_version = "c",
                    update_all_servers = "U",
                    check_outdated_servers = "C",
                    uninstall_server = "X",
                },
            },
            log_level = vim.log.levels.INFO,
        },
    },
}
