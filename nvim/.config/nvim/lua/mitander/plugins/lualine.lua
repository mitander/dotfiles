local function browser_extension(filetype, label, directory)
    local function title()
        local path = directory()
        if not path then
            return label
        end
        local name = vim.fn.fnamemodify(path:gsub("/+$", ""), ":t")
        local text = label .. " · " .. (name == "" and "/" or name .. "/")
        return (text:gsub("%%", "%%%%"))
    end
    local sections = { lualine_c = { title } }
    return { filetypes = { filetype }, sections = sections, inactive_sections = sections }
end

local function make_opts()
    return {
        options = {
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            theme = "flume",
        },
        extensions = {
            browser_extension("oil", "Oil", function()
                return require("oil").get_current_dir()
            end),
            browser_extension("NvimTree", "Tree", function()
                return require("nvim-tree.core").get_cwd()
            end),
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
