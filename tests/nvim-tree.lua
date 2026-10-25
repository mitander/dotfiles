-- Run with: nvim --clean --headless -l tests/nvim-tree.lua
-- Queue directory navigation without loading the plugin or touching the filesystem.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local other_window = vim.api.nvim_get_current_win()
local window

local function check()
    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "directory", "child" })

    local replacement = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(replacement, 0, -1, false, { "other", "content" })

    local node
    local opened = 0
    local queued = {}
    vim.schedule = function(callback)
        queued[#queued + 1] = callback
    end
    package.loaded["nvim-tree.api"] = {
        map = { on_attach = { default = function() end } },
        tree = {
            close = function() end,
            get_node_under_cursor = function()
                return node
            end,
        },
        node = {
            navigate = { parent_close = function() end },
            open = {
                edit = function(selected)
                    assert(selected == node)
                    opened = opened + 1
                    selected.open = true
                end,
            },
        },
    }
    local tree = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/nvim-tree.lua")

    local function attach()
        vim.cmd.vsplit()
        window = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(window, buffer)
        tree.opts.on_attach(buffer)
        for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buffer, "n")) do
            if mapping.lhs == "l" then
                return mapping.callback
            end
        end
        error("missing directory navigation mapping")
    end

    local enter_directory = attach()

    enter_directory()
    node = { type = "file", name = "file" }
    enter_directory()
    node = { type = "directory", name = ".." }
    enter_directory()
    assert(opened == 0 and #queued == 0, "non-directory/parent entries must not queue navigation")

    node = { type = "directory", name = "directory", open = false, has_children = false }
    enter_directory()
    assert(opened == 1 and #queued == 0, "empty directories should open without moving")

    node.has_children = true
    enter_directory()
    assert(opened == 1 and #queued == 1, "open directories should not be reopened")
    assert(vim.api.nvim_win_get_cursor(window)[1] == 1, "movement must wait for redraw")
    table.remove(queued, 1)()
    assert(vim.api.nvim_win_get_cursor(window)[1] == 2, "active tree should move to its child")

    enter_directory()
    table.remove(queued, 1)()
    assert(vim.api.nvim_win_get_cursor(window)[1] == 2, "movement must stop at the last line")

    vim.api.nvim_win_set_cursor(window, { 1, 0 })
    enter_directory()
    vim.api.nvim_set_current_win(other_window)
    local cursor = vim.api.nvim_win_get_cursor(other_window)
    table.remove(queued, 1)()
    assert(vim.deep_equal(vim.api.nvim_win_get_cursor(other_window), cursor), "queued work moved another window")
    assert(vim.api.nvim_win_get_cursor(window)[1] == 1, "queued work moved an inactive tree")

    vim.api.nvim_set_current_win(window)
    enter_directory()
    vim.api.nvim_win_set_buf(window, replacement)
    table.remove(queued, 1)()
    assert(vim.api.nvim_win_get_cursor(window)[1] == 1, "queued work moved a replacement buffer")
    vim.api.nvim_win_set_buf(window, buffer)

    -- Closing the tree or wiping its buffer makes queued movement a no-op.
    enter_directory()
    vim.api.nvim_win_close(window, true)
    table.remove(queued, 1)()

    enter_directory = attach()
    enter_directory()
    vim.api.nvim_win_set_buf(window, replacement)
    vim.api.nvim_buf_delete(buffer, { force = true })
    table.remove(queued, 1)()
    assert(#queued == 0, "all scheduled callbacks must have been exercised")
end

check()
print("PASS: tree navigation, deferred movement and stale buffer/window callbacks")
vim.cmd("qa!")
