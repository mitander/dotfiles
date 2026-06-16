return {
    dir = vim.fn.expand("~/dotfiles/themes/flume"),
    name = "flume.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("flume").setup()
    end,
}
