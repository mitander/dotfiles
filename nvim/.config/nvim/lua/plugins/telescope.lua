local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end

local actions = require("telescope.actions")

telescope.setup({
	defaults = {
		path_display = { "truncate" },
		selection_strategy = "reset",
		sorting_strategy = "descending",
		layout_strategy = "horizontal",
		layout_config = {
			horizontal = {
				preview_width = 0.55,
				results_width = 0.8,
			},
			vertical = {
				mirror = false,
			},
			width = 0.8,
			height = 0.7,
			preview_cutoff = 120,
		},
		file_ignore_patterns = {
			"jpg",
			"jpeg",
			"ttf",
			"otf",
			"png*",
			"vendor",
			".vscode",
			".gitlab",
			"*cache*",
			".git",
		},
		mappings = {
			i = {
				["<C-n>"] = actions.cycle_history_next,
				["<C-p>"] = actions.cycle_history_prev,
				["<C-j>"] = actions.move_selection_next,
				["<C-k>"] = actions.move_selection_previous,
				["<esc>"] = actions.close,
				["<Down>"] = actions.move_selection_next,
				["<Up>"] = actions.move_selection_previous,
				["<CR>"] = actions.select_default,
				["<C-s>"] = actions.select_horizontal,
				["<C-v>"] = actions.select_vertical,
				["<C-t>"] = actions.select_tab,
				["<C-u>"] = actions.preview_scrolling_up,
				["<C-d>"] = actions.preview_scrolling_down,
				["<PageUp>"] = actions.results_scrolling_up,
				["<PageDown>"] = actions.results_scrolling_down,
				["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
				["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
				["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
				["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
				["<C-l>"] = actions.complete_tag,
			},

			n = {
				["<esc>"] = actions.close,
				["<CR>"] = actions.select_default,
				["<C-s>"] = actions.select_horizontal,
				["<C-v>"] = actions.select_vertical,
				["<C-t>"] = actions.select_tab,
				["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
				["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
				["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
				["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
				["j"] = actions.move_selection_next,
				["k"] = actions.move_selection_previous,
				["H"] = actions.move_to_top,
				["M"] = actions.move_to_middle,
				["L"] = actions.move_to_bottom,
				["<Down>"] = actions.move_selection_next,
				["<Up>"] = actions.move_selection_previous,
				["gg"] = actions.move_to_top,
				["G"] = actions.move_to_bottom,
				["<C-u>"] = actions.preview_scrolling_up,
				["<C-d>"] = actions.preview_scrolling_down,
				["<PageUp>"] = actions.results_scrolling_up,
				["<PageDown>"] = actions.results_scrolling_down,
			},
		},
	},
	pickers = {
		live_grep = {
			additional_args = function()
				return { "--hidden" }
			end,
		},
		git_files = {
			additional_args = function()
				return { "--smart-case" }
			end,
		},
		buffers = {
			previewer = false,
			layout_config = {
				width = 0.4,
				height = 0.4,
			},
		},
	},
})

require("telescope").load_extension("projects")

local util = require("plugins.util")
local colors = require("plugins.colors")

util.highlight({
	{ group = "TelescopeBorder", bg = colors.none, fg = colors.blue },
	{ group = "TelescopeSelection", bg = colors.none, fg = colors.blue },
	{ group = "TelescopePromptBorder", bg = colors.none, fg = colors.gray2 },
	{ group = "TelescopeResultsBorder", bg = colors.none, fg = colors.gray2 },
	{ group = "TelescopePreviewBorder", bg = colors.none, fg = colors.gray2 },
	{ group = "TelescopeMatching", bg = colors.none, fg = colors.green },
})

require("plugins.mappings").telescope()
