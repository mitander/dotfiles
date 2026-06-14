return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
        local colors = require("mitander_theme").colors
        return {
            options = {
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                theme = {
                    normal = { c = { fg = colors.text, bg = colors.surface_alt } },
                    inactive = { c = { fg = colors.placeholder, bg = colors.surface, gui = "bold" } },
                },
            },
            sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {
                    {
                        "mode",
                        fmt = string.upper,
                        color = { fg = colors.accent, bg = colors.surface_alt, gui = "bold" },
                    },
                    {
                        "branch",
                        icon = "",
                        color = { fg = colors.green, bg = colors.surface_alt, gui = "bold" },
                        padding = { right = 1 },
                    },
                    {
                        "filename",
                        color = { gui = "bold" },
                        path = 1,
                        padding = { right = 1 },
                    },
                },
                lualine_x = {
                    {
                        "progress",
                        color = { fg = colors.text, gui = "bold" },
                        padding = { right = 1 },
                    },
                    {
                        "location",
                        color = { fg = colors.cyan, gui = "bold" },
                        padding = { right = 1 },
                    },
                    {
                        "diagnostics",
                        sources = { "nvim_diagnostic" },
                        symbols = { error = " ", warn = " ", info = " " },
                        diagnostics_color = {
                            color_error = { fg = colors.red },
                            color_warn = { fg = colors.yellow },
                            color_info = { fg = colors.accent },
                        },
                        padding = { right = 1 },
                    },
                    {
                        -- lsp client name
                        function()
                            local clients = vim.lsp.get_clients({ bufnr = 0 })
                            if next(clients) == nil then
                                return ""
                            end
                            return clients[1].name
                        end,
                        icon = "",
                        color = { fg = colors.green, gui = "bold" },
                        padding = { right = 1 },
                    },
                    {
                        "o:encoding",
                        fmt = string.upper,
                        color = { fg = colors.accent, gui = "bold" },
                        padding = { right = 1 },
                    },
                },
                lualine_y = {},
                lualine_z = {},
            },
            inactive_sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {
                    {
                        "filename",
                        path = 1,
                        colors = { gui = "bold " },
                        color = { link = "LineNr" },
                    },
                },
                lualine_x = {},
                lualine_y = {},
                lualine_z = {},
            },
        }
    end,
}
