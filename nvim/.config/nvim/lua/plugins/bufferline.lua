local status_ok, bufferline = pcall(require, "bufferline")
if not status_ok then
	return
end

local colors_ok, colors = pcall(require, "plugins.colors")
if not colors_ok then
	return
end

bufferline.setup({
	options = {
		offsets = {
			{ filetype = "NvimTree", text = "nvim-tree", text_align = "left" },
		},
		modified_icon = "",
		show_close_icon = false,
		show_buffer_close_icons = false,
		max_name_length = 14,
		max_prefix_length = 13,
		tab_size = 20,
		show_tab_indicators = false,
		enforce_regular_tabs = false,
		separator_style = "thin",
		always_show_bufferline = true,
		diagnostics = "nvim_lsp",
		diagnostics_indicator = function(count)
			return "[" .. count .. "]"
		end,
	},

	highlights = {
		-- Background and fill
		background = {
			guifg = colors.white,
			guibg = colors.gray,
		},
		fill = {
			guifg = colors.gray,
			guibg = colors.gray,
		},

		-- Indicator
		indicator_selected = {
			guifg = colors.magneta,
			guibg = colors.none,
		},

		-- Buffers
		buffer = {
			guifg = colors.white,
			guibg = colors.gray,
		},
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
			guibg = colors.gray,
		},
		error_diagnostic = {
			guifg = colors.red,
			guibg = colors.gray,
		},
		error_selected = {
			guifg = colors.red,
			guibg = colors.none,
		},
		warning = {
			guifg = colors.yellow,
			guibg = colors.gray,
		},
		warning_diagnostic = {
			guifg = colors.yellow,
			guibg = colors.gray,
		},
		warning_selected = {
			guifg = colors.yellow,
			guibg = colors.none,
		},
		hint = {
			guifg = colors.white,
			guibg = colors.gray,
		},
		hint_diagnostic = {
			guifg = colors.white,
			guibg = colors.gray,
		},
		hint_selected = {
			guifg = colors.white,
			guibg = colors.none,
		},
		info = {
			guifg = colors.white,
			guibg = colors.gray,
		},
		info_diagnostic = {
			guifg = colors.white,
			guibg = colors.gray,
		},
		info_selected = {
			guifg = colors.white,
			guibg = colors.none,
		},

		-- Modified
		modified = {
			guifg = colors.red,
			guibg = colors.gray,
		},
		modified_visible = {
			guifg = colors.yellow,
			guibg = colors.gray,
		},
		modified_selected = {
			guifg = colors.green,
			guibg = colors.none,
		},

		-- Separators
		separator = {
			guifg = colors.gray,
			guibg = colors.gray,
		},
		separator_visible = {
			guifg = colors.gray,
			guibg = colors.gray,
		},
		separator_selected = {
			guifg = colors.gray,
			guibg = colors.none,
		},
	},
})
