local ok, fzf_lua = pcall(require, "fzf-lua")
if not ok then
	return
end

fzf_lua.setup({
	globals = {
		files = {
			file_icons = false,
			color_icons = false,
			git_icons = false,
		},
	},
	winopts = {
		hl = { border = "FzfBorder" },
		height = 0.60,
		width = 0.70,
		row = 0.35,
		col = 0.55,
		preview = {
			layout = "flex",
			flip_columns = 130,
			scrollbar = "float",
		},
	},
	previewers = {
		bat = { theme = "base16" },
	},
	files = {
		fd_opts = "--no-ignore --color=never --type f --hidden --follow  --exclude .git",
		action = { ["ctrl-l"] = fzf_lua.actions.arg_add },
		file_icons = false,
		color_icons = false,
		git_icons = false,
	},
	grep = {
		rg_glob = true,
		rg_opts = "--hidden --column --line-number --no-heading"
			.. " --color=always --smart-case -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'",
		file_icons = false,
		color_icons = false,
		git_icons = false,
	},
	git = {
		status = {
			cmd = "git status -su",
			winopts = {
				preview = { vertical = "down:70%", horizontal = "right:70%" },
			},
			actions = {
				["ctrl-x"] = { fzf_lua.actions.git_reset, fzf_lua.actions.resume },
			},
			preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
		},
		commits = {
			winopts = { preview = { vertical = "down:60%" } },
			preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
		},
		bcommits = {
			winopts = { preview = { vertical = "down:60%" } },
			preview_pager = vim.fn.executable("delta") == 1 and "delta --width=$COLUMNS",
		},
		branches = { winopts = {
			preview = { vertical = "down:75%", horizontal = "right:75%" },
		} },
		files = {
			cmd = "git ls-files  --exclude-standard --other;  git ls-files",
			file_icons = false,
			color_icons = false,
			git_icons = false,
		},
	},
	diagnostics = { icon_padding = " " },
})

if vim.ui then
	fzf_lua.register_ui_select({
		winopts = {
			win_height = 0.30,
			win_width = 0.70,
			win_row = 0.40,
		},
	})
end