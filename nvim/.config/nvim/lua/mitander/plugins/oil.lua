local sidebar_width = 34

function _G.mitander_oil_statusline()
    local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
    local dir = require("oil").get_current_dir(bufnr)
    local path = dir and ("  " .. vim.fn.fnamemodify(dir, ":~")) or "  Oil"
    return "%#OilStatusLine#" .. path
end

local show_detail = false
local function toggle_detail()
    show_detail = not show_detail
    if show_detail then
        require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
    else
        require("oil").set_columns({ "icon" })
    end
end

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

local function select_entry(opts)
    opts = opts or {}
    local oil = require("oil")
    if not vim.w.oil_sidebar then
        oil.select(opts)
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
            if opts.vertical then
                vim.cmd("vsplit")
                target_win = vim.api.nvim_get_current_win()
            elseif opts.horizontal then
                vim.cmd("split")
                target_win = vim.api.nvim_get_current_win()
            end
            vim.api.nvim_set_current_buf(bufnr)
            if vim.api.nvim_win_is_valid(sidebar_win) then
                vim.w[sidebar_win].oil_target_win = target_win
            end
            if opts.keep_focus and vim.api.nvim_win_is_valid(sidebar_win) then
                vim.api.nvim_set_current_win(sidebar_win)
            end
        end,
    })
end

local function select_on_click()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == vim.api.nvim_get_current_win() and mouse.line > 0 and mouse.column > 0 then
        local line_count = vim.api.nvim_buf_line_count(0)
        local target_line = math.min(mouse.line, line_count)
        vim.api.nvim_win_set_cursor(0, { target_line, mouse.column - 1 })
    end
    select_entry({ keep_focus = true })
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
            statuscolumn = "  ",
            statusline = "%!v:lua.mitander_oil_statusline()",
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
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
            ["<LeftMouse>"] = {
                callback = select_on_click,
                desc = "Select entry (click)",
            },
            ["<2-LeftMouse>"] = {
                callback = select_on_click,
                desc = "Select entry (double click)",
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
            ["<C-w>k"] = {
                callback = move_pane("move_top"),
                desc = "Move to upper pane (fallback)",
                mode = "n",
            },
            ["<C-l>"] = {
                callback = move_pane("move_right"),
                desc = "Move to right pane",
                mode = "n",
            },
            ["<C-p>"] = false,
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
                callback = function()
                    select_entry({ vertical = true })
                end,
                desc = "Open the entry in a vertical split in target window",
            },
            ["<c-v>"] = {
                callback = function()
                    select_entry({ horizontal = true })
                end,
                desc = "Open the entry in a horizontal split in target window",
            },
            ["gd"] = {
                callback = toggle_detail,
                desc = "Toggle detail columns",
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

        local function setup_oil_highlights()
            local ok, flume = pcall(require, "flume")
            if ok and flume.colors then
                local colors = flume.colors
                vim.api.nvim_set_hl(0, "OilStatusLine", {
                    fg = colors.text or "#c0caf5",
                    bg = colors.surface_alt or "#1e1e2e",
                    bold = true,
                })
            else
                vim.api.nvim_set_hl(0, "OilStatusLine", { link = "StatusLine" })
            end
        end

        setup_oil_highlights()

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("mitander_oil_colors", { clear = true }),
            callback = setup_oil_highlights,
        })

        vim.api.nvim_create_autocmd("WinClosed", {
            group = vim.api.nvim_create_augroup("mitander_oil_last_window", { clear = true }),
            callback = quit_if_only_oil,
        })
    end,
}
