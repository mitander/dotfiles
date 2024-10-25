return {
    "EdenEast/nightfox.nvim",
    priority = 1000,
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
                Normal = { fg = "palette.fg1", bg = "palette.bg1" },
                Pmenu = { fg = "palette.fg1", bg = "palette.bg1" },
                NormalFloat = { fg = "palette.fg3", bg = "palette.bg1" },
                FloatBorder = { fg = "palette.fg3", bg = "palette.bg1" },
                WinSeparator = { fg = "palette.bg3", bg = "palette.bg1" },
                StatusLine = { fg = "none", bg = "palette.bg3" },
                StatusLineNC = { fg = "none", bg = "palette.bg3" },
                NonText = { fg = "palette.blue", bg = "none" },
                CursorLineNr = { fg = "palette.fg1", bg = "none" },
            },
        },
    },
    init = function()
        vim.cmd("colorscheme duskfox")
    end,
}
