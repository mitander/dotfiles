-- Run with: nvim --clean --headless -l tests/nvim-files.lua [oil.nvim nvim-tree.lua lualine.nvim paths]
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local specs = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/files.lua")
local spec, tree_spec = specs[1], specs[2]
-- Keep the deletion safeguard here. Installed-plugin tests below exercise navigation.
assert(spec.opts.delete_to_trash, "preserve trash-based deletion")
local mappings = {}
for _, mapping in ipairs(spec.keys) do
    mappings[mapping[1]] = mapping[2]
end
local toggle_tree = tree_spec.keys[1][2]

local status_opts = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/lualine.lua").opts()
local oil_directory = "/project/100%/"
package.loaded["oil"] = {
    get_current_dir = function()
        return oil_directory
    end,
}
local oil_title = status_opts.extensions[1].sections.lualine_c[1]
local rendered = vim.api.nvim_eval_statusline(oil_title(), {}).str
assert(rendered:find("100%/", 1, true), "directory names must escape statusline formatting")
package.loaded["oil"] = nil

-- Optional installed-plugin lane. Only disposable fixtures are created or removed.
if arg[1] then
    vim.opt.rtp:prepend(root .. "/nvim/.config/nvim")
    vim.opt.rtp:prepend(arg[1])
    assert(arg[3], "the installed-plugin lane needs the lualine path")
    vim.opt.rtp:prepend(arg[3])
    local lualine = require("lualine")
    lualine.setup({
        options = { theme = "auto" },
        sections = {},
        inactive_sections = {},
        extensions = status_opts.extensions,
    })
    local function status_title(expected)
        for _, focused in ipairs({ true, false }) do
            vim.g.actual_curwin = focused and vim.api.nvim_get_current_win() or -1
            local rendered = vim.api.nvim_eval_statusline(lualine.statusline(focused), {}).str
            assert(
                rendered:find(expected, 1, true),
                "browser statusline lost its directory: " .. rendered
            )
        end
    end
    local directory = vim.fn.tempname()
    vim.fn.mkdir(directory .. "/child", "p")
    vim.fn.writefile({ "fixture" }, directory .. "/file.txt")
    vim.fn.writefile({}, directory .. "/.hidden")
    vim.fn.writefile({}, directory .. "/child/nested.txt")
    assert(vim.uv.fs_symlink(directory .. "/child", directory .. "/linked-child"))
    local ok, err = xpcall(function()
        local oil = require("oil")
        oil.setup(spec.opts)
        vim.cmd.edit(vim.fn.fnameescape(directory .. "/file.txt"))
        local file_buffer = vim.api.nvim_get_current_buf()
        local target = vim.api.nvim_get_current_win()
        local sidebar

        local function wait_for_entry(name)
            local line
            assert(
                vim.wait(3000, function()
                    if vim.bo.filetype ~= "oil" then
                        return false
                    end
                    for index = 1, vim.api.nvim_buf_line_count(0) do
                        local entry = oil.get_entry_on_line(0, index)
                        if entry and entry.name == name then
                            line = index
                            return true
                        end
                    end
                    return false
                end),
                "missing entry: " .. name
            )
            vim.api.nvim_win_set_cursor(0, { line, 0 })
        end

        local function select(name)
            wait_for_entry(name)
            spec.opts.keymaps["<CR>"].callback()
        end

        require("mitander.file_browser").open()
        sidebar = vim.api.nvim_get_current_win()
        wait_for_entry(".hidden")
        assert(#vim.api.nvim_list_wins() == 2 and sidebar ~= target)
        assert(vim.wo.winfixwidth, "sidebar width must stay fixed while navigating")
        assert(
            vim.fn.win_screenpos(sidebar)[2] < vim.fn.win_screenpos(target)[2],
            "sidebar must be on the left"
        )
        status_title(vim.fn.fnamemodify(directory, ":t") .. "/")
        assert(
            vim.api.nvim_win_get_buf(target) == file_buffer,
            "opening sidebar replaced the editing buffer"
        )

        -- Directories, including symlinks, stay in the sidebar. Files open beside it.
        for _, name in ipairs({ "child", "linked-child" }) do
            select(name)
            assert(
                vim.wait(3000, function()
                    local dir = oil.get_current_dir()
                    return dir
                        and vim.uv.fs_realpath(dir) == vim.uv.fs_realpath(directory .. "/child")
                end),
                "directory did not open"
            )
            assert(vim.api.nvim_get_current_win() == sidebar and #vim.api.nvim_list_wins() == 2)
            require("oil.actions").parent.callback()
            wait_for_entry("file.txt")
        end
        select("file.txt")
        assert(
            vim.wait(3000, function()
                return vim.api.nvim_get_current_win() == target
                    and vim.api.nvim_get_current_buf() == file_buffer
            end),
            "file must open in the original editing window"
        )
        assert(vim.bo[vim.api.nvim_win_get_buf(sidebar)].filetype == "oil")

        -- Reveal reuses the sidebar and puts the cursor on the current file.
        require("mitander.file_browser").open()
        assert(
            vim.wait(3000, function()
                local entry = oil.get_cursor_entry()
                return entry and entry.name == "file.txt"
            end),
            "reveal must select the current file"
        )
        assert(vim.api.nvim_get_current_win() == sidebar and #vim.api.nvim_list_wins() == 2)

        -- If the original target closes, reuse another window before creating one.
        vim.api.nvim_set_current_win(target)
        vim.cmd.vnew()
        local replacement = vim.api.nvim_get_current_win()
        vim.api.nvim_win_close(target, false)
        vim.api.nvim_set_current_win(sidebar)
        select("file.txt")
        assert(
            vim.wait(3000, function()
                return vim.api.nvim_get_current_win() == replacement
            end),
            "closed target must fall back to another editing window"
        )
        vim.api.nvim_win_close(replacement, false)
        vim.api.nvim_set_current_win(sidebar)
        select("file.txt")
        assert(
            vim.wait(3000, function()
                return vim.api.nvim_get_current_win() ~= sidebar and #vim.api.nvim_list_wins() == 2
            end),
            "a lone sidebar must create an editing window"
        )
        assert(vim.api.nvim_get_current_buf() == file_buffer and not vim.w.oil_sidebar)

        -- Closing the last remaining sidebar restores a regular editing window.
        vim.api.nvim_win_close(vim.api.nvim_get_current_win(), false)
        spec.opts.keymaps["q"].callback()
        assert(#vim.api.nvim_tabpage_list_wins(0) == 1 and not vim.w.oil_sidebar)
        assert(not vim.wo.winfixwidth and vim.bo.filetype ~= "oil")
        mappings["<C-n>"]()
        vim.cmd.wincmd("p")

        -- Sidebar ownership is tab-local. Toggling and q never quit Neovim.
        vim.cmd.tabnew()
        mappings["<C-n>"]()
        assert(#vim.api.nvim_tabpage_list_wins(0) == 2)
        spec.opts.keymaps["q"].callback()
        assert(#vim.api.nvim_tabpage_list_wins(0) == 1)
        vim.cmd.tabclose()
        mappings["<C-n>"]()
        assert(
            #vim.api.nvim_tabpage_list_wins(0) == 1,
            "toggle from editing window must close sidebar"
        )

        -- Oil use alone must not load the optional tree.
        assert(not package.loaded["nvim-tree"] and not package.loaded["nvim-tree.api"])
        assert(arg[2], "the installed-plugin lane needs the NvimTree path")
        vim.opt.rtp:prepend(arg[2])
        require("nvim-tree").setup(tree_spec.opts)
        local tree = require("nvim-tree.api").tree
        local browser = require("mitander.file_browser")
        vim.cmd.cd(vim.fn.fnameescape(directory))

        -- Switching views leaves exactly one sidebar, with the current file revealed.
        mappings["<C-n>"]()
        assert(vim.w.oil_sidebar)
        toggle_tree()
        assert(
            vim.wait(3000, function()
                local node = tree.get_node_under_cursor()
                return vim.bo.filetype == "NvimTree" and node and node.name == "file.txt"
            end),
            "tree must reveal the current file"
        )
        assert(#vim.api.nvim_tabpage_list_wins(0) == 2)
        status_title(vim.fn.fnamemodify(directory, ":t") .. "/")
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            assert(not vim.w[win].oil_sidebar, "Oil sidebar stayed open beside the tree")
        end
        -- Default Enter expands folders and shows their nested files.
        local tree_buffer = vim.api.nvim_get_current_buf()
        local enter
        for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(tree_buffer, "n")) do
            if mapping.lhs == "<CR>" then
                enter = mapping.callback
            end
        end
        assert(enter, "keep default tree navigation")
        for line = 1, vim.api.nvim_buf_line_count(tree_buffer) do
            vim.api.nvim_win_set_cursor(0, { line, 0 })
            local node = tree.get_node_under_cursor()
            if node and node.name == "child" then
                enter()
                break
            end
        end
        assert(
            vim.wait(3000, function()
                local lines =
                    table.concat(vim.api.nvim_buf_get_lines(tree_buffer, 0, -1, false), "\n")
                return lines:find("nested.txt", 1, true) ~= nil
            end),
            "tree folder did not expand inline"
        )
        mappings["<C-n>"]()
        wait_for_entry("file.txt")
        assert(vim.w.oil_sidebar and not tree.is_visible(), "opening Oil must close the tree")
        assert(#vim.api.nvim_tabpage_list_wins(0) == 2)
        browser.close()
        toggle_tree()
        assert(tree.is_visible())
        toggle_tree()
        assert(not tree.is_visible() and #vim.api.nvim_tabpage_list_wins(0) == 1)
        assert(vim.api.nvim_get_current_buf() == file_buffer)

        -- Standard Oil still works without a sidebar.
        vim.cmd.Oil()
        wait_for_entry("file.txt")
        spec.opts.keymaps["q"].callback()
        assert(
            vim.wait(1000, function()
                return vim.api.nvim_get_current_buf() == file_buffer
            end),
            "closing current-window Oil must restore the file"
        )
        vim.cmd.edit(vim.fn.fnameescape(directory))
        assert(
            vim.wait(3000, function()
                return vim.bo.filetype == "oil"
            end),
            "directory editing must use Oil"
        )
        assert(#vim.api.nvim_list_wins() == 1, "directory editing must not force a sidebar")
    end, debug.traceback)
    vim.fn.delete(directory, "rf")
    assert(ok, err)
end

print(
    "PASS: file browser configuration"
        .. (arg[1] and " and installed-plugin sidebar navigation" or "")
)
vim.cmd("qa!")
