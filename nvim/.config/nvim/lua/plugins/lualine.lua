local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
  return
end

-- Customize jellybeans
local custom_jellybeans = require('lualine.themes.jellybeans')

-- clearer filename
custom_jellybeans.normal.c.fg = '#e8e8de'

-- same color for all modes
custom_jellybeans.normal.a.bg = '#8197bf'
custom_jellybeans.insert.a.bg = '#8197bf'
custom_jellybeans.visual.a.bg = '#8197bf'


local config = {
  options = {
    disabled_filetypes = { "NvimTree" },
    component_separators = "",
    section_separators = "",
    theme = custom_jellybeans
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  tabline = {},
  extensions = {}
}

lualine.setup(config)
