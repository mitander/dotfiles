local ok, neogit = pcall(require, "neogit")
if not ok then
	return
end

neogit.setup({
	disable_signs = false,
	disable_hint = false,
	disable_context_highlighting = false,
	disable_commit_confirmation = true,
	auto_refresh = true,
	disable_insert_on_commit = false,
	disable_builtin_notifications = false,
	use_magit_keybindings = false,
	kind = "tab",
	commit_popup = {
		kind = "split",
	},
	popup = {
		kind = "split",
	},
	signs = {
		section = { ">", "v" },
		item = { ">", "v" },
		hunk = { "", "" },
	},
	integrations = {
		diffview = false,
	},
	sections = {
		untracked = {
			folded = false,
		},
		unstaged = {
			folded = false,
		},
		staged = {
			folded = false,
		},
		stashes = {
			folded = true,
		},
		unpulled = {
			folded = true,
		},
		unmerged = {
			folded = false,
		},
		recent = {
			folded = true,
		},
	},
	mappings = {
		status = {
			["B"] = "BranchPopup",
		},
	},
})
