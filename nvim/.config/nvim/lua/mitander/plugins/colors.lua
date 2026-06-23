local dotfiles = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles")

return {
    dir = dotfiles .. "/themes/flume",
    name = "flume.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        pcall(vim.api.nvim_del_augroup_by_name, "mitander_highlight_overrides")
        require("flume").setup()
    end,
}
