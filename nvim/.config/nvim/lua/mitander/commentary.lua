return {
    event = "BufReadPre",
    "tpope/vim-commentary",
    init = function()
        vim.cmd([[map <silent> <leader>/ :Commentary<enter>]])
    end,
}
