local dotfiles = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles")
local variant = "light" -- "dark" or "light"
vim.g.flume_variant = variant

return {
    dir = dotfiles .. "/themes/flume",
    name = "flume.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        pcall(vim.api.nvim_del_augroup_by_name, "mitander_highlight_overrides")
        require("flume").setup({ variant = variant })
        vim.cmd.colorscheme(variant == "light" and "flume-light" or "flume")
    end,
}
