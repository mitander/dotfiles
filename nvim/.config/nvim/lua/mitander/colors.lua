return {
    dir = vim.fn.stdpath("config"),
    name = "flume.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        require("flume").setup()
    end,
}
