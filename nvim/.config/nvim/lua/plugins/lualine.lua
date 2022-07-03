local ok, lualine = pcall(require, "lualine")
if not ok then
	return
end

-- Customize jellybeans
local jelly = require("lualine.themes.jellybeans")

local colors = require("plugins.colors")

-- Bar colors
jelly.normal.c.fg = colors.white
jelly.normal.c.bg = colors.gray

-- Git colors
jelly.normal.a.bg = colors.gray
jelly.insert.a.bg = colors.gray
jelly.visual.a.bg = colors.gray
jelly.normal.a.fg = colors.yellow
jelly.insert.a.fg = colors.yellow
jelly.visual.a.fg = colors.yellow

-- Filename colors
jelly.normal.b.bg = colors.gray
jelly.insert.b.bg = colors.gray
jelly.visual.b.bg = colors.gray
jelly.normal.b.fg = colors.white
jelly.insert.b.fg = colors.white
jelly.visual.b.fg = colors.white

local config = {
	options = {
		component_separators = "",
		section_separators = "",
		theme = jelly,
		globalstatus = true,
	},
	sections = {
		lualine_a = { "branch", "diagnostics" },
		lualine_b = { { "filename", path = 1 } },
		lualine_c = {},
		lualine_x = {},
		lualine_y = { "location" },
		lualine_z = { "progress" },
	},
	inactive_sections = {
		lualine_a = { "branch", "diagnostics" },
		lualine_b = { { "filename", path = 1 } },
		lualine_c = {},
		lualine_x = {},
		lualine_y = { "location" },
		lualine_z = { "progress" },
	},
	tabline = {},
	extensions = {},
}

lualine.setup(config)
