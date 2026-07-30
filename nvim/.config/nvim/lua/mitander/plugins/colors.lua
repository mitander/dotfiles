local dotfiles = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles")
local flume = dotfiles .. "/themes/flume"
local schema_file = flume .. "/extras/current/schema"
local schema = "mesa"

if vim.fn.filereadable(schema_file) == 1 then
    schema = vim.trim(vim.fn.readfile(schema_file, "", 1)[1] or schema)
end

return {
    schema = schema,
    dir = flume,
    name = "flume.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        pcall(vim.api.nvim_del_augroup_by_name, "mitander_highlight_overrides")
        require("flume").setup({ schema = schema, transparent = false })
    end,
}
