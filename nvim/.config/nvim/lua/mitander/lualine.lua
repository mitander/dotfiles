return {
    "nvim-lualine/lualine.nvim",
    opts = function()
        local colors = {
            bg = "#393552",
            fg = "#e0def4",
            red = "#eb6f92",
            green = "#a3be8c",
            blue = "#569fba",
            cyan = "#9ccfd8",
            gray = "#6e6a86",
            none = "NONE",
        }
        return {
            options = {
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                theme = {
                    normal = { c = { fg = colors.fg, bg = colors.bg } },
                    inactive = { c = { fg = colors.gray, bg = colors.bg, gui = "bold" } },
                },
            },
            sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {
                    {
                        "mode",
                        fmt = string.upper,
                        color = { fg = colors.blue, bg = colors.bg, gui = "bold" },
                    },
                    {
                        "branch",
                        icon = "",
                        color = { fg = colors.green, bg = colors.bg, gui = "bold" },
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
                        color = { fg = colors.white, gui = "bold" },
                        padding = { right = 1 },
                    },
                    {
                        "diagnostics",
                        sources = { "nvim_diagnostic" },
                        symbols = { error = " ", warn = " ", info = " " },
                        diagnostics_color = {
                            color_error = { fg = colors.red },
                            color_warn = { fg = colors.blue },
                            color_info = { fg = colors.cyan },
                        },
                        padding = { right = 1 },
                    },
                    {
                        -- lsp client name
                        function()
                            local msg = ""
                            local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
                            local clients = vim.lsp.get_active_clients()
                            if next(clients) == nil then
                                return msg
                            end
                            for _, client in ipairs(clients) do
                                local filetypes = client.config.filetypes
                                if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                                    return client.name
                                end
                            end
                            return msg
                        end,
                        icon = "",
                        color = { fg = colors.green, gui = "bold" },
                        padding = { right = 1 },
                    },
                    {
                        "o:encoding",
                        fmt = string.upper,
                        color = { fg = colors.blue, gui = "bold" },
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
