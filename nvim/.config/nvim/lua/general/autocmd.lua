local autocmd = vim.api.nvim_create_autocmd

-- highlight yanks
autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 200,
		})
	end,
})
-- trim whitespace
autocmd({ "BufWritePre" }, {
	pattern = "*",
	command = "%s/\\s\\+$//e",
})

-- better paste
autocmd({ "InsertLeave" }, {
	pattern = "*",
	command = "set nopaste",
})

-- indent
autocmd({ "FileType" }, {
	pattern = { "zig", "go", "rust", "c", "cpp" },
	command = [[ setlocal tabstop=4 shiftwidth=4 ]],
})

-- terminal
autocmd({ "TermOpen" }, {
	pattern = "*",
	command = [[ setlocal norelativenumber nonumber ]],
})

-- quickfix binds
autocmd({ "FileType" }, {
	pattern = "qf",
	command = [[
        nnoremap <silent> <buffer> q :close<enter>
        nnoremap <silent> <buffer> <esc> :close<enter>
        nnoremap <silent> <buffer> <enter> <enter>:cclose<enter>
    ]],
})
