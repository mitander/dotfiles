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

local directions = {
    h = { edge = "pane_at_left", tmux = "L" },
    j = { edge = "pane_at_bottom", tmux = "D" },
    k = { edge = "pane_at_top", tmux = "U" },
    l = { edge = "pane_at_right", tmux = "R" },
}

local function tmux_navigate(direction)
    local current = vim.fn.win_getid()
    local target = vim.fn.win_getid(vim.fn.winnr("1" .. direction))
    if target ~= 0 and target ~= current then
        vim.fn.win_gotoid(target)
        return
    end

    if not vim.env.TMUX or vim.fn.executable("tmux") ~= 1 then
        return
    end

    local spec = directions[direction]
    if not spec then
        return
    end

    local at_edge = vim.fn.system({ "tmux", "display-message", "-p", "#{" .. spec.edge .. "}" }):gsub("%s+", "")
    if vim.v.shell_error ~= 0 or at_edge == "1" then
        return
    end

    vim.fn.system({ "tmux", "select-pane", "-" .. spec.tmux })
end

local function navigate(direction)
    return function()
        tmux_navigate(direction)
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
        { "<C-h>", navigate("h"), desc = "Tmux navigate left" },
        { "<C-j>", navigate("j"), desc = "Tmux navigate down" },
        { "<C-k>", navigate("k"), desc = "Tmux navigate up" },
        { "<C-l>", navigate("l"), desc = "Tmux navigate right" },
        { "<C-w>h", navigate("h"), desc = "Tmux navigate left" },
        { "<C-w>j", navigate("j"), desc = "Tmux navigate down" },
        { "<C-w>k", navigate("k"), desc = "Tmux navigate up" },
        { "<C-w>l", navigate("l"), desc = "Tmux navigate right" },
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
            enable_default_keybindings = false,
        },
        resize = {
            enable_default_keybindings = true,
        },
    },
}
