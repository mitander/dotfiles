local dotfiles = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles")
local flume = dotfiles .. "/themes/flume"
local schema = "mesa" -- Fallback until the first :FlumeSync.

return {
    schema = schema,
    dir = flume,
    name = "flume.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        pcall(vim.api.nvim_del_augroup_by_name, "mitander_highlight_overrides")
        require("flume").setup({ schema = schema, follow_sync = true, dev = true, transparent = false })
    end,
}
