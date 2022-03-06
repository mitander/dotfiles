local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
  return
end

-- Customize jellybeans
local custom_jellybeans = require'lualine.themes.jellybeans'
custom_jellybeans.normal.c.fg = '#e8e8de'


local config = {
  options = {
    disabled_filetypes = { "NvimTree" },
    component_separators = "",
    section_separators = "",
    theme = custom_jellybeans
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  extensions = {}
}

lualine.setup(config)
