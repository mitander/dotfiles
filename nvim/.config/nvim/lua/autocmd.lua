-- highlight yanks
vim.api.nvim_create_autocmd("TextYankPost", {
    pattern = "*",
    callback = function()
        vim.highlight.on_yank {
            higroup = "IncSearch",
            timeout = 200,
        }
    end,
})
-- trim whitespace
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = "*",
    command = "%s/\\s\\+$//e",
})

-- better paste
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    pattern = "*",
    command = "set nopaste",
})

-- indent
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "zig", "go", "rust", "c", "cpp" },
    command = [[ setlocal tabstop=4 shiftwidth=4 ]],
})

-- terminal
vim.api.nvim_create_autocmd({ "TermOpen" }, {
    pattern = "*",
    command = [[ setlocal norelativenumber nonumber ]],
})

-- quickfix binds
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = "qf",
    command = [[
        nnoremap <silent> <buffer> q :close<enter>
        nnoremap <silent> <buffer> <esc> :close<enter>
        nnoremap <silent> <buffer> <enter> <enter>:cclose<enter>
    ]],
})
