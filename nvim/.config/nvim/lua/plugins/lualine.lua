local ok, lualine = pcall(require, "lualine")
if not ok then
	return
end

-- Previously set statusline (in case of removing lualine)
-- set statusline=%{expand('%:p:h:t')}/%t%m%r%h%=\ %l,%v\ %p%%

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

-- Inactive section colors
jelly.inactive.a.bg = colors.gray
jelly.inactive.a.fg = colors.white
jelly.inactive.b.bg = colors.gray
jelly.inactive.b.fg = colors.white
jelly.inactive.c.bg = colors.gray
jelly.inactive.c.fg = colors.white

local config = {
	options = {
		component_separators = "",
		section_separators = "",
		theme = jelly,
		globalstatus = true,
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "diagnostics" },
		lualine_c = { { "filename", path = 1 } },
		lualine_x = { "location" },
		lualine_y = { "progress" },
		lualine_z = { "filetype" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { { "filename", path = 1 } },
		lualine_x = { "location" },
		lualine_y = { "progress" },
		lualine_z = { "filetype" },
	},
	tabline = {},
	extensions = {},
}

lualine.setup(config)
