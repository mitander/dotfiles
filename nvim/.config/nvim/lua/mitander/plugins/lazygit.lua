local function open_lazygit()
    local root = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles")
    local script = root .. "/scripts/tmux-project.sh"

    if vim.env.TMUX and vim.fn.executable("tmux") == 1 and vim.fn.executable(script) == 1 then
        local output = vim.fn.system({ script, "git", vim.fn.getcwd() })
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
