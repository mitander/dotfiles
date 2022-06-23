local ok, lualine = pcall(require, "lualine")
if not ok then
	return
end

-- Customize jellybeans
local jelly = require("lualine.themes.jellybeans")

local colors = require("plugins.colors")

jelly.normal.c.fg = colors.white
jelly.normal.c.bg = colors.gray

-- same color for all modes
jelly.normal.a.bg = colors.blue
jelly.insert.a.bg = colors.blue
jelly.visual.a.bg = colors.blue

jelly.normal.a.fg = colors.black
jelly.insert.a.fg = colors.black
jelly.visual.a.fg = colors.black

-- filename
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
		lualine_a = { "mode" },
		lualine_b = {},
		lualine_c = {},
		lualine_x = { "branch", "diagnostics" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = { "mode" },
		lualine_b = {},
		lualine_c = {},
		lualine_x = { "branch", "diagnostics" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	tabline = {},
	extensions = {},
}

lualine.setup(config)
