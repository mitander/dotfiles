local ok, telescope = pcall(require, "telescope")
if not ok then
	return
end

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local theme = require("telescope.themes")

telescope.setup({
	defaults = {
		path_display = { "truncate" },
		selection_strategy = "reset",
		sorting_strategy = "ascending",
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
			height = 0.8,
			preview_cutoff = 120,
		},
		file_ignore_patterns = {
			"jpg",
			"jpeg",
			"ttf",
			"otf",
			"png",
			"vendor",
			".vscode",
			".gitlab/",
			"*cache*",
			".git/",
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
			cmd = "rg",
			sort_last_used = true,
			additional_args = function()
				return { "--hidden" }
			end,
		},
		git_files = {
			additional_args = function()
				return { "--smart-case" }
			end,
			show_untracked = true,
		},
		git_branches = {
			previewer = false,
			layout_config = {
				width = 0.4,
				height = 0.4,
			},
			attach_mappings = function(_, map)
				map("i", "<c-x>", actions.git_delete_branch)
				return true
			end,
		},
		git_status = {
			attach_mappings = function(_, map)
				map("i", "<c-space>", actions.git_staging_toggle)
				return true
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
	extensions = {
		fzf = {
			fuzzy = true,
			override_generic_sorter = true,
			override_file_sorter = true,
			case_mode = "smart_case",
		},
		["ui-select"] = {
			theme.get_dropdown({}),
		},
		project = {
			hidden_files = true,
			theme = "dropdown",
		},
		file_browser = {
			hijack_netrw = true,
		},
	},
})

telescope.load_extension("fzf")
telescope.load_extension("ui-select")
telescope.load_extension("projects")
telescope.load_extension("file_browser")

local M = {}
M.rg = function()
	local input = { "rg", "--hidden", "--column", "" }
	local opts = {
		finder = finders.new_oneshot_job(input),
		sorter = sorters.get_generic_fuzzy_sorter(),
		prompt_title = "RipGrep",
	}

	local picker = pickers.new(opts)
	picker:find()
end
return M
