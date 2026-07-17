local dotfiles = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles")
local variant = "dusk" -- "dusk", "mist", or "ash"

return {
    variant = variant,
    dir = dotfiles .. "/themes/flume",
    name = "flume.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        pcall(vim.api.nvim_del_augroup_by_name, "mitander_highlight_overrides")
        require("flume").setup({ variant = variant, transparent = false })
    end,
}
