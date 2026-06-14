return {
    dir = vim.fn.stdpath("config"),
    name = "duskfox",
    lazy = false,
    priority = 1000,
    config = function()
        require("mitander_theme").setup()
    end,
}
