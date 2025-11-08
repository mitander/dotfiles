return {
    "mbbill/undotree",
    cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeHide" },
    keys = {
        { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undo tree" },
    },
    init = function()
        vim.g.undotree_WindowLayout = 2
        vim.g.undotree_SplitWidth = 40
        vim.g.undotree_SetFocusWhenToggle = 1
        vim.g.undotree_ShortIndicators = 1
        vim.g.undotree_DiffAutoOpen = 1
        vim.g.undotree_DiffpanelHeight = 10
        vim.g.undotree_HelpLine = 0
    end,
}
