require("mitander.options")
require("mitander.remaps")
require("mitander.lazy_init")

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local group = augroup("mitander", {})
local yank_group = augroup("HighlightYank", {})

function R(name)
    require("plenary.reload").reload_module(name)
end

vim.filetype.add({
    extension = {
        templ = "templ",
    },
})

autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({
            higroup = "IncSearch",
            timeout = 40,
        })
    end,
})

autocmd({ "BufWritePre" }, {
    group = group,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

autocmd({ "InsertLeave" }, {
    group = group,
    pattern = "*",
    command = "set nopaste",
})

autocmd({ "FileType" }, {
    group = group,
    pattern = { "zig", "go", "rust", "c", "cpp" },
    command = [[ setlocal tabstop=4 shiftwidth=4 ]],
})

autocmd({ "TermOpen" }, {
    group = group,
    pattern = "*",
    command = [[ setlocal norelativenumber nonumber ]],
})

autocmd({ "FileType" }, {
    group = group,
    pattern = "qf",
    command = [[
        nnoremap <silent> <buffer> q :close<enter>
        nnoremap <silent> <buffer> <esc> :close<enter>
        nnoremap <silent> <buffer> <enter> <enter>:cclose<enter>
    ]],
})

local root_cache = {}
autocmd("BufEnter", {
    group = group,
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
            if path ~= nil then
                root_cache[path] = vim.fs.dirname(root_file)
            end
        end
        vim.fn.chdir(root_cache[path])
    end,
})
