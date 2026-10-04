local function make_opts()
    return {
        options = {
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            theme = "flume",
            disabled_filetypes = {
                statusline = { "NvimTree" },
            },
        },
        sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = {
                {
                    "mode",
                    fmt = string.upper,
                    color = function()
                        local colors = require("flume").colors
                        return { fg = colors.accent, bg = colors.surface_alt, gui = "bold" }
                    end,
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
                    "diagnostics",
                    sources = { "nvim_diagnostic" },
                    symbols = { error = " ", warn = " ", info = " " },
                    padding = { right = 1 },
                },
                {
                    "branch",
                    icon = "",
                    padding = { right = 1 },
                    fmt = function(name)
                        if name == "master" or name == "main" or name == "" then
                            return ""
                        end
                        return name
                    end,
                },
                {
                    function()
                        local clients = vim.lsp.get_clients({ bufnr = 0 })
                        if next(clients) == nil then
                            return ""
                        end
                        return clients[1].name
                    end,
                    icon = "",
                    color = function()
                        return { fg = require("flume").colors.green, gui = "bold" }
                    end,
                    padding = { right = 1 },
                },
                {
                    "location",
                    color = function()
                        return { fg = require("flume").colors.accent, gui = "bold" }
                    end,
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
                    color = { link = "LineNr" },
                },
            },
            lualine_x = {},
            lualine_y = {},
            lualine_z = {},
        },
    }
end

return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = make_opts,
}
