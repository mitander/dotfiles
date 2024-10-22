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
            duskfox = {
                Normal = { fg = "fg1", bg = "bg1" },
                Pmenu = { fg = "fg1", bg = "bg1" },
                NormalFloat = { fg = "fg3", bg = "bg1" },
                FloatBorder = { fg = "fg3", bg = "bg1" },
                WinSeparator = { fg = "bg3", bg = "bg1" },
                StatusLine = { fg = "none", bg = "bg3" },
                StatusLineNC = { fg = "none", bg = "bg3" },
            },
        },
    },
    init = function()
        vim.cmd("colorscheme duskfox")
    end,
}
