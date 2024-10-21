return {
    "EdenEast/nightfox.nvim",
    priority = 1000,
    lazy = true,
    opts = {
        groups = {
            all = {
                ["@markup.italic"] = { style = "italic" },
                ["@keyword.operator"] = { link = "@keyword" },
                ["@text.reference"] = { link = "@keyword" },
                ["@text.literal"] = { style = "" },
                ["@codeblock"] = { bg = "palette.bg0" },
                ["@neorg.markup.strikethrough"] = { fg = "palette.comment", style = "strikethrough" },
            },
        },
    },
    init = function()
        vim.cmd("colorscheme duskfox")
        vim.cmd([[hi WinSeparator guifg=#363646]])
        vim.cmd([[hi NormalFloat guibg=#232136]])
    end,
}
