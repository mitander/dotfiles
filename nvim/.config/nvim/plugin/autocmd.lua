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

-- switch tmux pane and run command
vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = "*",
    command = [[
        nnoremap <silent> <buffer> <leader><enter> :silent exec "!tmux select-window -l && tmux send-keys C-l && tmux send up enter && tmux select-pane -l"<enter>
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

-- trim whitespace
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = "*",
    command = "%s/\\s\\+$//e",
})

-- close nvim-tree if last window
vim.api.nvim_create_autocmd("QuitPre", {
    callback = function()
        local invalid_win = {}
        local wins = vim.api.nvim_list_wins()
        for _, w in ipairs(wins) do
            local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
            if bufname:match "NvimTree_" ~= nil then
                table.insert(invalid_win, w)
            end
        end
        if #invalid_win == #wins - 1 then
            -- Should quit, so we close all invalid windows.
            for _, w in ipairs(invalid_win) do
                vim.api.nvim_win_close(w, true)
            end
        end
    end,
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
            local root_file = vim.fs.find({ ".git", "Makefile", "*.norg" }, { path = path, upward = true })[1]
            if root_file == nil then
                return
            end
            if path ~= nil then
                root_cache[path] = vim.fs.dirname(root_file)
            end
        end
        vim.fn.chdir(root_cache[path])
    end,
})
