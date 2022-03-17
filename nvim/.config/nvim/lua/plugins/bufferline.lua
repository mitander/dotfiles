local status_ok, bufferline = pcall(require, "bufferline")

if not status_ok then
  return
end

local colors = {
  black = '#3b3b3b',
  red = '#cf6a4c',
  green = '#99ad6a',
  yellow = '#d8ad4c',
  blue = '#597bc5',
  magenta = '#a037b0',
  cyan = '#71b9f8',
  white = '#adadad',
  grey = '#30302c',
  none = 'NONE'
}

bufferline.setup {
  options = {
    offsets = {
      { filetype = "NvimTree", text = "nvim-tree", text_align = "left" },
    },
    modified_icon = "",
    close_icon = "",
    show_close_icon = false,
    show_buffer_close_icons = false,
    left_trunc_marker = "",
    right_trunc_marker = "",
    max_name_length = 14,
    max_prefix_length = 13,
    tab_size = 20,
    show_tab_indicators = true,
    enforce_regular_tabs = false,
    separator_style = "thin",
    always_show_bufferline = true,
    diagnostics = "nvim_lsp",
    diagnostics_indicator = function(count)
     return "["..count.."]"
     end
  },

  highlights = {
    -- Background and fill
    background = {
      guifg = colors.white,
      guibg = colors.grey,
    },
    fill = {
      guifg = colors.grey,
      guibg = colors.grey,
    },

    -- Buffers
    buffer_selected = {
      guifg = colors.white,
      guibg = colors.none,
    },
    buffer_visible = {
      guifg = colors.white,
      guibg = colors.none,
    },

    -- Diagnostics
    error = {
      guifg = colors.red,
      guibg = colors.grey,
    },
    error_diagnostic = {
      guifg = colors.red,
      guibg = colors.grey,
    },
    error_selected = {
      guifg = colors.red,
      guibg = colors.none,
    },
    warning = {
      guifg = colors.yellow,
      guibg = colors.grey,
    },
    warning_diagnostic = {
      guifg = colors.yellow,
      guibg = colors.grey,
    },
    warning_selected = {
      guifg = colors.yellow,
      guibg = colors.none,
    },
    hint = {
      guifg = colors.white,
      guibg = colors.grey,
    },
    hint_diagnostic = {
      guifg = colors.white,
      guibg = colors.grey,
    },
    hint_selected = {
      guifg = colors.white,
      guibg = colors.none,
    },
    info = {
      guifg = colors.white,
      guibg = colors.grey,
    },
    info_diagnostic = {
      guifg = colors.white,
      guibg = colors.grey,
    },
    info_selected = {
      guifg = colors.white,
      guibg = colors.none,
    },

    -- Modified
    modified = {
      guifg = colors.red,
      guibg = colors.grey,
    },
    modified_visible = {
      guifg = colors.yellow,
      guibg = colors.none,
    },
    modified_selected = {
      guifg = colors.green,
      guibg = colors.none,
    },

    -- Separators
    separator = {
      guifg = colors.grey,
      guibg = colors.grey,
    },
    separator_visible = {
      guifg = colors.grey,
      guibg = colors.none,
    },
    separator_selected = {
      guifg = colors.grey,
      guibg = colors.none,
    },
  },
}
