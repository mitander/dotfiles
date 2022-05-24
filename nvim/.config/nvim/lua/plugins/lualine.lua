local ok, lualine = pcall(require, "lualine")
if not ok then
    return
end

-- Customize jellybeans
local custom_jellybeans = require("lualine.themes.jellybeans")

-- clearer filename
local colors = require("plugins.colors")

custom_jellybeans.normal.c.fg = colors.white
custom_jellybeans.normal.c.bg = colors.gray

-- same color for all modes
custom_jellybeans.normal.a.bg = colors.magneta
custom_jellybeans.insert.a.bg = colors.magneta
custom_jellybeans.visual.a.bg = colors.magneta

local config = {
    options = {
        disabled_filetypes = { "NvimTree" },
        component_separators = "",
        section_separators = "",
        theme = custom_jellybeans,
        globalstatus = true,
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
    inactive_sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
    tabline = {},
    extensions = {},
}

lualine.setup(config)
