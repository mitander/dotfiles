local function open_lazygit()
    if vim.env.TMUX then
        vim.system({ "myran", "role", "open", "git", vim.fn.getcwd() }, { text = true }, function(result)
            if result.code ~= 0 then
                vim.schedule(function()
                    vim.notify(
                        result.stderr ~= "" and result.stderr or result.stdout,
                        vim.log.levels.ERROR,
                        { title = "lazygit" }
                    )
                end)
            end
        end)
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
