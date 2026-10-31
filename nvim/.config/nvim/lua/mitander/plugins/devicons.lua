return {
    "nvim-tree/nvim-web-devicons",
    -- Use one upstream color reference; Flume supplies readable themed shades.
    opts = { variant = "dark" },
    config = function(_, opts)
        local provider = require("nvim-web-devicons")
        provider.setup(opts)
        require("mitander.icon_colors").setup(provider)
    end,
}
