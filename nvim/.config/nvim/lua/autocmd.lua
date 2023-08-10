local nnoremap = require("utils").bind "n"

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

-- build programs
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = "zig",
    command = [[
        nnoremap <silent> <buffer> <leader><enter> :Dispatch zig build test<enter>
    ]],
})
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "c", "cpp" },
    command = [[
        nnoremap <silent> <buffer> <leader><enter> :Dispatch make<enter>
    ]],
})
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "go" },
    command = [[
        nnoremap <silent> <buffer> <leader><enter> :Dispatch go test all<enter>
    ]],
})
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { "rust" },
    command = [[
        nnoremap <silent> <buffer> <leader><enter> :Dispatch cargo test<enter>
    ]],
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
