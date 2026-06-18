local dotfiles = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles")

return {
    dir = dotfiles .. "/themes/flume",
    name = "flume.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("flume").setup()
    end,
}
