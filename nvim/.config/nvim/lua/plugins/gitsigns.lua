local status_ok, gitsigns = pcall(require, "gitsigns")
if not status_ok then
	return
end

gitsigns.setup({
	signs = {
		add = { hl = "GitSignsAdd", text = "▎", numhl = "GitSignsAddNr", linehl = "GitSignsAddLn" },
		change = { hl = "GitSignsChange", text = "▎", numhl = "GitSignsChangeNr", linehl = "GitSignsChangeLn" },
		delete = { hl = "GitSignsDelete", text = "▎", numhl = "GitSignsDeleteNr", linehl = "GitSignsDeleteLn" },
		topdelete = {
			hl = "GitSignsDelete",
			text = "|",
			numhl = "GitSignsDeleteNr",
			linehl = "GitSignsDeleteLn",
		},
		changedelete = {
			hl = "GitSignsChange",
			text = "▎",
			numhl = "GitSignsChangeNr",
			linehl = "GitSignsChangeLn",
		},
	},
	signcolumn = true,
	numhl = false,
	linehl = false,
	word_diff = false,
	watch_gitdir = {
		interval = 1000,
		follow_files = true,
	},
	attach_to_untracked = true,
	current_line_blame = false,
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = "right_align",
		delay = 0,
		ignore_whitespace = false,
	},
	current_line_blame_formatter_opts = {
		relative_time = false,
	},
	sign_priority = 6,
	update_debounce = 100,
	status_formatter = nil,
	max_file_length = 40000,
	preview_config = {
		border = "single",
		style = "minimal",
		relative = "cursor",
		row = 0,
		col = 1,
	},
	yadm = {
		enable = false,
	},
})

local util = require("plugins.util")
local colors = require("plugins.colors")

util.highlight({
	{ group = "GitSignsAdd", bg = colors.none, fg = colors.green },
	{ group = "GitSignsDelete", bg = colors.none, fg = colors.red },
	{ group = "GitSignsChange", bg = colors.none, fg = colors.yellow },
	{ group = "DiffAdd", bg = colors.none, fg = colors.green },
	{ group = "DiffChange", bg = colors.none, fg = colors.red },
	{ group = "DiffDelete", bg = colors.none, fg = colors.yellow },
    { group = "GitSignsCurrentLineBlame", bg = colors.none, fg = colors.gray2 }
})
