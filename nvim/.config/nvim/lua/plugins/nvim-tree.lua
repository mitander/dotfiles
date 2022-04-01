-- following options are the default
-- each of these are documented in `:help nvim-tree.OPTION_NAME`
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

local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
	return
end

local config_status_ok, nvim_tree_config = pcall(require, "nvim-tree.config")
if not config_status_ok then
	return
end

local tree_cb = nvim_tree_config.nvim_tree_callback

nvim_tree.setup({
	disable_netrw = true,
	hijack_netrw = true,
	open_on_setup = false,
	open_on_tab = true,
	hijack_cursor = false,
	update_cwd = true,
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
		width = 30,
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
				{ key = "<C-v>", cb = tree_cb("vsplit") },
				{ key = "<C-s>", cb = tree_cb("split") },
				{ key = "<C-t>", cb = tree_cb("tab") },
			},
		},
		number = false,
		relativenumber = false,
	},
	trash = {
		cmd = "trash",
		require_confirm = true,
	},
	git_hl = 1,
	disable_window_picker = 1,
	root_folder_modifier = ":t",
	show_icons = {
		git = 1,
		folders = 1,
		files = 1,
		folder_arrows = 1,
		tree_width = 30,
	},
	actions = {
		open_file = {
			quit_on_open = true,
		},
	},
})

local colors_ok, colors = pcall(require, "plugins.colors")
if not colors_ok then
	return
end

colors.highlight("IndentBlanklineChar", colors.none, colors.light_gray)
colors.highlight("NvimTreeSymlink", colors.none, colors.magneta)
colors.highlight("NvimTreeFolderName", colors.none, colors.white)
colors.highlight("NvimTreeRootFolder", colors.none, colors.gray)
colors.highlight("LspDiagnosticsError", colors.none, colors.red)
colors.highlight("LspDiagnosticsWarning", colors.none, colors.yellow)
colors.highlight("LspDiagnosticsInformation", colors.none, colors.white)
colors.highlight("LspDiagnosticsHint", colors.none, colors.white)
