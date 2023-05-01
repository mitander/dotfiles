local ok, lualine = pcall(require, "lualine")
if not ok then
    return
end

local colors = {
    fg = "#dcd7ba",
    bg = "#363646",
    red = "#cf6a4c",
    green = "#99ad6a",
    yellow = "#E6C384",
    cyan = "#71b9f8",
    gray = "#9c9c9c",
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
        -- remove defaults values
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
    },
    inactive_sections = {
        -- remove defaults values
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

ins_left {
    "mode",
    color = { fg = colors.yellow, bg = colors.bg, gui = "bold" },
}

ins_left {
    "branch",
    icon = "",
    color = { fg = colors.green, bg = colors.bg, gui = "bold" },
    padding = { right = 1 },
}

ins_left {
    "filename",
    color = { gui = "bold" },
    path = 1,
    padding = { right = 1 },
}

ins_left {
    "diagnostics",
    sources = { "nvim_diagnostic" },
    symbols = { error = " ", warn = " ", info = " " },
    diagnostics_color = {
        color_error = { fg = colors.red },
        color_warn = { fg = colors.yellow },
        color_info = { fg = colors.cyan },
    },
    padding = { right = 1 },
}

ins_right {
    "progress",
    color = { gui = "bold" },
    padding = { right = 1 },
}

ins_right {
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
}

ins_right {
    "o:encoding",
    fmt = string.upper,
    color = { fg = colors.yellow, gui = "bold" },
    padding = { right = 1 },
}

lualine.setup(config)
