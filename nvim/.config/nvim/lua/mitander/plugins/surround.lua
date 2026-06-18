return {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("nvim-surround").setup({
            -- Use the default keymaps:
            -- ys{motion}{char} - add surround
            -- ds{char}         - delete surround
            -- cs{target}{char} - change surround
        })
    end,
}
