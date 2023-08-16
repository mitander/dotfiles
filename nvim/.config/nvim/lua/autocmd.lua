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

-- change root when opening new buffer
local root_cache = {}
vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("AutoRoot", {}),
    callback = function()
        local path = vim.api.nvim_buf_get_name(0)
        if path == "" then
            return
        end
        path = vim.fs.dirname(path)
        if root_cache[path] == nil then
            local root_file = vim.fs.find({ ".git", "Makefile" }, { path = path, upward = true })[1]
            if root_file == nil then
                return
            end
            root_cache[path] = vim.fs.dirname(root_file)
        end
        vim.fn.chdir(root_cache[path])
    end,
})
