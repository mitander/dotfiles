local function close_diffbandit()
    local state = require("diffbandit.state")
    local tabpage = vim.api.nvim_get_current_tabpage()
    local session = state.sessions[tabpage]

    if session and type(session.close) == "function" then
        session:close()
        return
    end

    local panel = state.panels[tabpage]
    if panel and type(panel.close) == "function" then
        panel:close()
        return
    end

    vim.notify("No active DiffBandit session", vim.log.levels.INFO)
end

return {
    "CoreyKaylor/diffbandit.nvim",
    cmd = {
        "DiffBandit",
        "DiffBanditBuffers",
        "DiffBanditFolderDiff",
        "DiffBanditGit",
        "DiffBanditGitCurrent",
        "DiffBanditCommitPanel",
        "DiffBanditGitMenu",
        "DiffBanditGitLog",
        "DiffBanditGitCommit",
        "DiffBanditGitCompare",
        "DiffBanditGitCheckout",
        "DiffBanditMerge",
    },
    keys = {
        { "<leader>gd", "<cmd>DiffBanditGit<cr>", desc = "Review Git changes" },
        { "<leader>gD", "<cmd>DiffBanditGitCurrent<cr>", desc = "Review current file changes" },
        { "<leader>gP", "<cmd>DiffBanditCommitPanel<cr>", desc = "Toggle Git commit panel" },
        { "<leader>gm", "<cmd>DiffBanditGitMenu<cr>", desc = "Git workflow menu" },
        { "<leader>gq", close_diffbandit, desc = "Close DiffBandit session" },
    },
    config = function()
        require("diffbandit").setup()
    end,
}
