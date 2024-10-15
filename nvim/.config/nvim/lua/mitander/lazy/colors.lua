return {
    "rebelot/kanagawa.nvim",
    init = function()
        require('kanagawa').setup({
            compile = false,
            undercurl = true,
            commentStyle = { italic = false },
            functionStyle = {},
            keywordStyle = { italic = false },
            statementStyle = { bold = true },
            typeStyle = {},
            transparent = false,
            dimInactive = false,
            terminalColors = true,
            theme = "wave",
            colors = {
                theme = {
                    all = {
                        ui = {
                            bg_gutter = "none"
                        }
                    }
                }
            },
            overrides = function(colors)
                local theme = colors.theme
                return {
                    Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
                    PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
                    PmenuSbar = { bg = theme.ui.bg_m1 },
                    PmenuThumb = { bg = theme.ui.bg_p2 },
                    CursorLineNr = { fg = "#E6C384" },
                    StatusLine = { bg = "#363646" },
                    StatusLineNC = { bg = "#363646" },
                    LineNr = { fg = "#9c9c9c" },
                    IblIndent = { fg = "#35353d" },
                }
            end,
        })
        vim.cmd("colorscheme kanagawa")
    end,
}
