local function open_lazygit()
    if vim.env.TMUX then
        local output = vim.fn.system({ "myran", "role", "open", "git", vim.fn.getcwd() })
        if vim.v.shell_error ~= 0 then
            vim.notify(output, vim.log.levels.ERROR, { title = "lazygit" })
        end
        return
    end

    vim.cmd("LazyGit")
end

return {
    "kdheepak/lazygit.nvim",
    cmd = {
        "LazyGit",
        "LazyGitConfig",
        "LazyGitCurrentFile",
        "LazyGitFilter",
        "LazyGitFilterCurrentFile",
    },
    keys = {
        { "<leader>gg", open_lazygit, desc = "LazyGit tmux window" },
    },
    init = function()
        vim.g.lazygit_floating_window_scaling_factor = 1
    end,
}
