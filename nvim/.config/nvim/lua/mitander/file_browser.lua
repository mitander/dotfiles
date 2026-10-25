local M = {}
local width = 34

local function find_sidebar()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.w[win].oil_sidebar then
            return win
        end
    end
end

local function is_edit_window(win)
    return win
        and vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_win_get_tabpage(win) == vim.api.nvim_get_current_tabpage()
        and vim.api.nvim_win_get_config(win).relative == ""
        and not vim.w[win].oil_sidebar
end

function M.close()
    if vim.w.oil_sidebar and #vim.api.nvim_tabpage_list_wins(0) > 1 then
        vim.api.nvim_win_close(0, false)
    else
        local was_sidebar = vim.w.oil_sidebar
        require("oil").close()
        if was_sidebar then
            vim.wo.winfixwidth = false
            vim.w.oil_sidebar = nil
        end
    end
end

function M.open()
    -- Don't load the tree plugin just to close it.
    local tree_api = package.loaded["nvim-tree.api"]
    if tree_api then
        tree_api.tree.close()
    end
    local source = vim.api.nvim_get_current_win()
    local buffer = vim.api.nvim_get_current_buf()
    local sidebar = find_sidebar()
    if sidebar == source then
        return
    end
    if not sidebar then
        vim.cmd("topleft " .. width .. "vsplit")
        sidebar = vim.api.nvim_get_current_win()
        vim.w[sidebar].oil_sidebar = true
        vim.wo[sidebar].winfixwidth = true
    end
    if is_edit_window(source) then
        vim.w[sidebar].oil_target_win = source
    end
    vim.api.nvim_set_current_win(sidebar)
    -- Let Oil derive the directory and selected filename from the source buffer.
    vim.api.nvim_win_set_buf(sidebar, buffer)
    require("oil").open()
end

function M.toggle()
    local sidebar = find_sidebar()
    if sidebar then
        vim.api.nvim_win_call(sidebar, M.close)
    else
        M.open()
    end
end

function M.toggle_tree()
    local tree = require("nvim-tree.api").tree
    if tree.is_visible() then
        tree.close()
        return
    end
    local sidebar = find_sidebar()
    if sidebar then
        vim.api.nvim_win_call(sidebar, M.close)
    end
    tree.open({
        path = vim.fn.getcwd(),
        find_file = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "",
        update_root = false,
    })
end

function M.select()
    local oil = require("oil")
    if not vim.w.oil_sidebar then
        oil.select()
        return
    end

    local sidebar = vim.api.nvim_get_current_win()
    local source_buffer = vim.api.nvim_get_current_buf()
    oil.select({
        handle_buffer_callback = function(buffer)
            if
                not vim.api.nvim_win_is_valid(sidebar)
                or vim.api.nvim_win_get_buf(sidebar) ~= source_buffer
                or vim.api.nvim_win_get_tabpage(sidebar) ~= vim.api.nvim_get_current_tabpage()
            then
                return
            end

            -- Oil normalizes directory buffer names with a trailing slash, including symlinks.
            if vim.api.nvim_buf_get_name(buffer):sub(-1) == "/" then
                vim.api.nvim_win_set_buf(sidebar, buffer)
                return
            end

            local target = vim.w[sidebar].oil_target_win
            if not is_edit_window(target) then
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                    if is_edit_window(win) then
                        target = win
                        break
                    end
                end
            end
            if not is_edit_window(target) then
                vim.api.nvim_set_current_win(sidebar)
                vim.cmd("rightbelow vnew")
                target = vim.api.nvim_get_current_win()
                vim.w[target].oil_sidebar = nil
                vim.wo[target].winfixwidth = false
                vim.api.nvim_win_set_width(sidebar, width)
            end
            vim.w[sidebar].oil_target_win = target
            vim.api.nvim_set_current_win(target)
            vim.api.nvim_win_set_buf(target, buffer)
        end,
    })
end

return M
