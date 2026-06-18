local function dotfiles_script(script_name)
    local root = vim.env.DOTFILES_DIR or vim.fn.expand("~/dotfiles")
    return root .. "/scripts/" .. script_name
end

local function run_tmux_project(args)
    if not vim.env.TMUX then
        vim.notify("Not inside tmux", vim.log.levels.WARN, { title = "tmux" })
        return
    end

    local script = dotfiles_script("tmux-project.sh")
    if vim.fn.executable("tmux") ~= 1 or vim.fn.executable(script) ~= 1 then
        vim.notify("tmux project script not executable: " .. script, vim.log.levels.ERROR, { title = "tmux" })
        return
    end

    local command = { script }
    vim.list_extend(command, args)

    local output = vim.fn.system(command)
    if vim.v.shell_error ~= 0 then
        vim.notify(output, vim.log.levels.ERROR, { title = "tmux" })
    end
end

local function open_project_role(role)
    return function()
        run_tmux_project({ role, vim.fn.getcwd() })
    end
end

local function open_shell_popup()
    if not vim.env.TMUX then
        vim.notify("Not inside tmux", vim.log.levels.WARN, { title = "tmux" })
        return
    end

    local output = vim.fn.system({ "tmux", "display-popup", "-E", "-d", vim.fn.getcwd(), "-w", "90%", "-h", "80%" })
    if vim.v.shell_error ~= 0 then
        vim.notify(output, vim.log.levels.ERROR, { title = "tmux" })
    end
end

return {
    "aserowy/tmux.nvim",
    event = "VeryLazy",
    keys = {
        { "<leader>Te", open_project_role("vim"), desc = "Tmux project nvim window" },
        { "<leader>Ts", open_project_role("shell"), desc = "Tmux project shell window" },
        { "<leader>Ta", open_project_role("pi"), desc = "Tmux project pi window" },
        {
            "<leader>TA",
            function()
                run_tmux_project({ "agent-split", vim.fn.getcwd() })
            end,
            desc = "Tmux new pi split",
        },
        { "<leader>Tp", open_shell_popup, desc = "Tmux shell popup" },
    },
    opts = {
        copy_sync = {
            enable = true,
            ignore_buffers = { empty = false },
            register_offset = 0,
            redirect_to_clipboard = true,
            sync_clipboard = true,
            sync_deletes = true,
            sync_unnamed = true,
        },
        navigation = {
            cycle_navigation = false,
            enable_default_keybindings = true,
        },
        resize = {
            enable_default_keybindings = true,
        },
    },
}
