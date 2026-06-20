return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
        local colors = require("flume").colors
        return {
            options = {
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                theme = {
                    normal = { c = { fg = colors.text, bg = colors.surface_alt } },
                    inactive = { c = { fg = colors.placeholder, bg = colors.surface, gui = "bold" } },
                },
                disabled_filetypes = {
                    statusline = { "oil" },
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
                        "filename",
                        color = { gui = "bold" },
                        path = 1,
                        padding = { right = 1 },
                        fmt = function(name)
                            if vim.b.startup_scratch then
                                return "[No Name]"
                            end
                            return name
                        end,
                    },
                },
                lualine_x = {
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
                        "branch",
                        icon = "",
                        color = { fg = colors.green, bg = colors.surface_alt, gui = "bold" },
                        padding = { right = 1 },
                        fmt = function(name)
                            if name == "master" or name == "main" or name == "" then
                                return ""
                            end
                            return name
                        end,
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
                        "location",
                        color = { fg = colors.cyan, gui = "bold" },
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
                        fmt = function(name)
                            if vim.b.startup_scratch then
                                return "Scratch"
                            end
                            return name
                        end,
                    },
                },
                lualine_x = {},
                lualine_y = {},
                lualine_z = {},
            },
        }
    end,
}
