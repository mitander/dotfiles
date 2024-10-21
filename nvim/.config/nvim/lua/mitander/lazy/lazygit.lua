return {
    "kdheepak/lazygit.nvim",
    init = function()
        vim.api.nvim_create_autocmd({ "BufRead" }, {
            group = vim.api.nvim_create_augroup("LazyGitLazyLoad", { clear = true }),
            callback = function()
                vim.fn.system("git -C " .. '"' .. vim.fn.expand("%:p:h") .. '"' .. " rev-parse")
                if vim.v.shell_error == 0 then
                    vim.api.nvim_del_augroup_by_name("LazyGitLazyLoad")
                    vim.schedule(function()
                        require("lazygit")
                    end)
                end
            end,
        })
    end,
    config = function()
        vim.keymap.set("n", "<leader>gg", vim.cmd.LazyGit)
        vim.g.lazygit_floating_window_scaling_factor = 1
    end,
}
