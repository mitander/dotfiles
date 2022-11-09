local nvim_tree_ok, nvim_tree = pcall(require, "nvim-tree")
if not nvim_tree_ok then
	print("error: could not load nvim-tree")
	return
end

local config_ok, nvim_tree_config = pcall(require, "nvim-tree.config")
if not config_ok then
	print("error: could not load nvim-tree.config")
	return
end

local tree_cb = nvim_tree_config.nvim_tree_callback

require("general.keymaps").nvimtree()

nvim_tree.setup({
	renderer = {
		icons = {
			glyphs = {
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
			},
		},
	},
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
		hide_root_folder = false,
		side = "left",
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
