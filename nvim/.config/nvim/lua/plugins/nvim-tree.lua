local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
	return
end

local config_status_ok, nvim_tree_config = pcall(require, "nvim-tree.config")
if not config_status_ok then
	return
end

local tree_cb = nvim_tree_config.nvim_tree_callback

vim.g.nvim_tree_icons = {
	default = "",
	symlink = "",
	git = {
		unstaged = "",
		staged = "S",
		unmerged = "",
		renamed = "➜",
		deleted = "",
		untracked = "U",
		ignored = "◌",
	},
	folder = {
		default = "",
		open = "",
		empty = "",
		empty_open = "",
		symlink = "",
	},
}

nvim_tree.setup({
	disable_netrw = true,
	hijack_netrw = true,
	open_on_setup = false,
	open_on_tab = true,
	hijack_cursor = false,
	update_cwd = true,
	update_focused_file = {
		enable = true,
		update_cwd = true,
	},
	diagnostics = {
		enable = true,
		icons = {
			hint = "",
			info = "",
			warning = "",
			error = "",
		},
	},
	system_open = {
		cmd = nil,
		args = {},
	},
	filters = {
		dotfiles = false,
		custom = {},
	},
	view = {
		width = 50,
		height = 30,
		hide_root_folder = false,
		side = "left",
		auto_resize = true,
		mappings = {
			custom_only = false,
			list = {
				{ key = { "l", "<CR>", "o" }, cb = tree_cb("edit") },
				{ key = { "h", "<BS>" }, cb = tree_cb("close_node") },
				{ key = "h", cb = tree_cb("close_node") },
				{ key = "<c-v>", cb = tree_cb("vsplit") },
				{ key = "<c-s>", cb = tree_cb("split") },
				{ key = "<c-t>", cb = tree_cb("tab") },
			},
		},
		number = false,
		relativenumber = false,
	},
	trash = {
		cmd = "trash",
		require_confirm = true,
	},
	actions = {
		open_file = {
			quit_on_open = false,
		},
	},
})

local util = require("plugins.util")
local colors = require("plugins.colors")

util.highlight({
	{ group = "NvimTreeSymlink", bg = colors.none, fg = colors.magneta },
	{ group = "NvimTreeFolderName", bg = colors.none, fg = colors.white },
	{ group = "NvimTreeRootFolder", bg = colors.none, fg = colors.gray },
	{ group = "LspDiagnosticsError", bg = colors.none, fg = colors.red },
	{ group = "LspDiagnosticsWarning", bg = colors.none, fg = colors.yellow },
	{ group = "LspDiagnosticsInformation", bg = colors.none, fg = colors.white },
	{ group = "LspDiagnosticsHint", bg = colors.none, fg = colors.white },
})
