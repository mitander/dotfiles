return {
    "nvim-lualine/lualine.nvim",
    config = function()
        local colors = {
            bg = "#393552",
            fg = "#e0def4",
            red = "#eb6f92",
            green = "#a3be8c",
            blue = "#569fba",
            cyan = "#9ccfd8",
            gray = "#9d95c9",
            none = "NONE",
        }

        local config = {
            options = {
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                theme = {
                    normal = { c = { fg = colors.fg, bg = colors.bg } },
                    inactive = { c = { fg = colors.gray, bg = colors.bg, gui = "bold" } },
                },
                ignore_focus = { "NvimTree" },
            },
            sections = {
                lualine_a = {},
                lualine_b = {},
                lualine_c = {},
                lualine_x = {},
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
                    },
                },
                lualine_x = {},
                lualine_y = {},
                lualine_z = {},
            },
        }

        local function ins_left(component)
            table.insert(config.sections.lualine_c, component)
        end

        local function ins_right(component)
            table.insert(config.sections.lualine_x, component)
        end

        ins_left({
            "mode",
            color = { fg = colors.blue, bg = colors.bg, gui = "bold" },
        })

        ins_left({
            "branch",
            icon = "",
            color = { fg = colors.green, bg = colors.bg, gui = "bold" },
            padding = { right = 1 },
        })

        ins_left({
            "filename",
            color = { gui = "bold" },
            path = 1,
            padding = { right = 1 },
        })

        ins_left({
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = { error = " ", warn = " ", info = " " },
            diagnostics_color = {
                color_error = { fg = colors.red },
                color_warn = { fg = colors.blue },
                color_info = { fg = colors.cyan },
            },
            padding = { right = 1 },
        })

        ins_right({
            "progress",
            color = { gui = "bold" },
            padding = { right = 1 },
        })

        ins_right({
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
            icon = " ",
            color = { fg = colors.green, gui = "bold" },
            padding = { right = 1 },
        })

        ins_right({
            "o:encoding",
            fmt = string.upper,
            color = { fg = colors.blue, gui = "bold" },
            padding = { right = 1 },
        })

        require("lualine").setup(config)
        vim.cmd([[hi StatusLine guibg=#393552]])
        vim.cmd([[hi StatusLineNC guibg=#393552]])
    end,
}
