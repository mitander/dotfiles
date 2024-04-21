return {
    "rebelot/kanagawa.nvim",
    init = function()
        require("kanagawa").load "wave"
        vim.cmd [[set background=dark]]
        vim.cmd [[hi CursorLine guibg=#2a2a37]]
        vim.cmd [[hi CursorLineNr guifg=#E6C384]]
        vim.cmd [[hi StatusLine guibg=#363646]]
        vim.cmd [[hi StatusLineNC guibg=#363646]]
        vim.cmd [[hi LineNr guifg=NONE]]
        vim.cmd [[hi Todo guifg=#E6C384 guibg=#1F1F28]]
        vim.cmd [[hi IblIndent guifg=#35353d guibg=NONE]]
    end,
}
