local sidebar_width = 34

local function is_oil_sidebar(winid)
    return vim.api.nvim_win_is_valid(winid) and vim.w[winid].oil_sidebar == true
end

local function is_oil_win(winid)
    if not vim.api.nvim_win_is_valid(winid) then
        return false
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    return vim.w[winid].oil_sidebar == true or vim.bo[bufnr].filetype == "oil"
end

local function find_oil_sidebar()
    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_oil_sidebar(winid) then
            return winid
        end
    end
end

local function current_file_path()
    local bufnr = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(bufnr)
    if name ~= "" and vim.bo[bufnr].buftype == "" then
        return name
    end
end

local function oil_parent_url(path)
    if not path then
        return nil
    end

    local parent_url, basename = require("oil").get_buffer_parent_url(path, true)
    if basename then
        require("oil.view").set_last_cursor(parent_url, basename)
    end
    return parent_url
end

local function set_sidebar_width(winid)
    vim.wo[winid].winfixwidth = true
    vim.api.nvim_win_set_width(winid, sidebar_width)
end

local function normal_wins()
    return vim.tbl_filter(function(winid)
        return vim.api.nvim_win_get_config(winid).relative == ""
    end, vim.api.nvim_tabpage_list_wins(0))
end

local function quit_if_only_oil()
    vim.schedule(function()
        local wins = normal_wins()
        if #wins == 1 and is_oil_win(wins[1]) then
            vim.cmd.quit()
        end
    end)
end

local function close_sidebar(winid)
    winid = winid or find_oil_sidebar()
    if not winid or not vim.api.nvim_win_is_valid(winid) then
        return
    end

    if #normal_wins() == 1 then
        vim.cmd.quit()
    else
        vim.api.nvim_win_close(winid, true)
    end
end

local function find_target_win(sidebar_winid)
    local target = vim.w[sidebar_winid].oil_target_win
    if target and vim.api.nvim_win_is_valid(target) and not is_oil_sidebar(target) then
        return target
    end

    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if
            winid ~= sidebar_winid
            and vim.api.nvim_win_get_config(winid).relative == ""
            and not is_oil_sidebar(winid)
        then
            local bufnr = vim.api.nvim_win_get_buf(winid)
            if vim.bo[bufnr].buftype == "" then
                return winid
            end
        end
    end
end

local function ensure_target_win(sidebar_winid)
    local target = find_target_win(sidebar_winid)
    if target and vim.api.nvim_win_is_valid(target) then
        return target
    end

    vim.api.nvim_set_current_win(sidebar_winid)
    vim.cmd("rightbelow vertical split")
    target = vim.api.nvim_get_current_win()
    vim.w[target].oil_sidebar = nil
    vim.w[sidebar_winid].oil_target_win = target
    vim.api.nvim_set_current_win(sidebar_winid)
    return target
end

local function open_sidebar(path, focus)
    local oil = require("oil")
    local source_win = vim.api.nvim_get_current_win()
    local dir = oil_parent_url(path or current_file_path())

    local sidebar_win = find_oil_sidebar()
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
        if not is_oil_sidebar(source_win) then
            vim.w[sidebar_win].oil_target_win = source_win
        end
        vim.api.nvim_set_current_win(sidebar_win)
        oil.open(dir)
    else
        vim.cmd("topleft vertical new")
        sidebar_win = vim.api.nvim_get_current_win()
        vim.w[sidebar_win].oil_sidebar = true
        vim.w[sidebar_win].oil_target_win = source_win
        oil.open(dir)
    end

    set_sidebar_width(sidebar_win)

    if not focus and vim.api.nvim_win_is_valid(source_win) and not is_oil_sidebar(source_win) then
        vim.api.nvim_set_current_win(source_win)
    end
end

local function close_oil()
    if #normal_wins() == 1 and is_oil_win(vim.api.nvim_get_current_win()) then
        vim.cmd.quit()
    elseif vim.w.oil_sidebar then
        close_sidebar(vim.api.nvim_get_current_win())
    else
        require("oil").close()
    end
end

local function toggle_sidebar()
    local sidebar_win = find_oil_sidebar()
    if sidebar_win and vim.api.nvim_win_is_valid(sidebar_win) then
        close_sidebar(sidebar_win)
    else
        open_sidebar(nil, true)
    end
end

local function reveal_in_sidebar()
    open_sidebar(current_file_path(), true)
end

local function move_pane(method)
    return function()
        require("tmux")[method]()
    end
end

local function select_entry()
    local oil = require("oil")
    if not vim.w.oil_sidebar then
        oil.select()
        return
    end

    local entry = oil.get_cursor_entry()
    if entry and require("oil.util").is_directory(entry) then
        oil.select()
        return
    end

    local sidebar_win = vim.api.nvim_get_current_win()
    local target_win = find_target_win(sidebar_win)
    oil.select({
        handle_buffer_callback = function(bufnr)
            if not target_win or not vim.api.nvim_win_is_valid(target_win) then
                target_win = ensure_target_win(sidebar_win)
            end
            vim.api.nvim_set_current_win(target_win)
            vim.api.nvim_set_current_buf(bufnr)
            if vim.api.nvim_win_is_valid(sidebar_win) then
                vim.w[sidebar_win].oil_target_win = target_win
            end
        end,
    })
end

return {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        default_file_explorer = true,
        columns = { "icon" },
        buf_options = {
            buflisted = false,
            bufhidden = "hide",
        },
        win_options = {
            wrap = false,
            number = false,
            relativenumber = false,
            signcolumn = "no",
            cursorcolumn = false,
            foldcolumn = "0",
            spell = false,
            list = false,
            conceallevel = 3,
            concealcursor = "nvic",
        },
        delete_to_trash = false,
        skip_confirm_for_simple_edits = false,
        prompt_save_on_select_new_entry = true,
        cleanup_delay_ms = 2000,
        lsp_file_methods = {
            enabled = true,
            timeout_ms = 1000,
            autosave_changes = false,
        },
        constrain_cursor = "editable",
        watch_for_changes = false,
        keymaps = {
            ["<CR>"] = {
                callback = select_entry,
                desc = "Select entry",
            },
            ["<bs>"] = "actions.parent",
            ["<C-h>"] = {
                callback = move_pane("move_left"),
                desc = "Move to left pane",
                mode = "n",
            },
            ["<C-j>"] = {
                callback = move_pane("move_bottom"),
                desc = "Move to lower pane",
                mode = "n",
            },
            ["<C-k>"] = {
                callback = move_pane("move_top"),
                desc = "Move to upper pane",
                mode = "n",
            },
            ["<C-l>"] = {
                callback = move_pane("move_right"),
                desc = "Move to right pane",
                mode = "n",
            },
            ["<C-p>"] = "actions.preview",
            ["<C-n>"] = {
                callback = close_oil,
                desc = "Close oil",
            },
            ["q"] = {
                callback = close_oil,
                desc = "Close oil",
            },
            ["."] = "actions.open_cwd",
            ["~"] = "actions.cd",
            ["<c-s>"] = {
                "actions.select",
                opts = { vertical = true },
                desc = "Open the entry in a vertical split",
            },
            ["<c-v>"] = {
                "actions.select",
                opts = { horizontal = true },
                desc = "Open the entry in a horizontal split",
            },
        },
        use_default_keymaps = true,
        view_options = {
            show_hidden = true,
            is_hidden_file = function(name, _)
                return vim.startswith(name, ".")
            end,
            is_always_hidden = function(_, _)
                return false
            end,
            natural_order = true,
            case_insensitive = false,
            sort = {
                { "type", "asc" },
                { "name", "asc" },
            },
        },
    },
    config = function(_, opts)
        vim.keymap.set("n", "<c-n>", toggle_sidebar, { desc = "Toggle oil sidebar" })
        vim.keymap.set("n", "<leader>e", reveal_in_sidebar, { desc = "Reveal current file in oil" })
        require("oil").setup(opts)

        vim.api.nvim_create_autocmd("WinClosed", {
            group = vim.api.nvim_create_augroup("mitander_oil_last_window", { clear = true }),
            callback = quit_if_only_oil,
        })
    end,
}
