local autocmd = vim.api.nvim_create_autocmd

-- highlight yanks
autocmd("TextYankPost", {
    pattern = "*",
    callback = function()
        vim.highlight.on_yank {
            higroup = "IncSearch",
            timeout = 200,
        }
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

-- reload some chadrc options on-save
--autocmd("BufWritePost", {
--    -- pattern = vim.tbl_map(vim.fs.normalize, vim.fn.glob(vim.fn.stdpath "config" .. "/lua/**/*.lua", true, true, true)),
--    pattern = "*",
--    group = vim.api.nvim_create_augroup("ReloadConfig", {}),
--
--    callback = function(opts)
--        local fp = vim.fn.fnamemodify(vim.fs.normalize(vim.api.nvim_buf_get_name(opts.buf)), ":r") --[[@as string]]
--        local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"
--        local name = string.gsub(fp, "^.*/" .. app_name .. "/lua/", ""):gsub("/", ".")
--
--        local plugin = require("lazy.core.config").plugins[name]
--        print(plugin)
--        require("lazy.core.loader").reload "colors"
--    end,
--})
