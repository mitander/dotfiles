-- Run with: nvim --clean --headless -l tests/nvim-files.lua [oil.nvim nvim-tree.lua lualine.nvim paths]
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local specs = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/files.lua")
local spec, tree_spec = specs[1], specs[2]
assert(tree_spec[1] == "nvim-tree/nvim-tree.lua" and tree_spec.lazy == true)
assert(not tree_spec.opts.git.enable and not tree_spec.opts.filesystem_watchers.enable)
assert(not tree_spec.opts.hijack_directories.enable and not tree_spec.opts.hijack_netrw)

assert(spec[1] == "stevearc/oil.nvim" and spec.lazy == false, "Oil must handle directories at startup")
assert(spec.opts.delete_to_trash, "preserve trash-based deletion")
assert(spec.opts.view_options.show_hidden, "show dotfiles")
for _, key in ipairs({ "<C-h>", "<C-l>", "<C-p>" }) do
    assert(spec.opts.keymaps[key] == false, "preserve pane navigation: " .. key)
end
local mappings = {}
for _, mapping in ipairs(spec.keys) do
    mappings[mapping[1]] = mapping[2]
end
assert(mappings["-"] == "<cmd>Oil<cr>", "keep current-window directory editing")
assert(type(mappings["<C-n>"]) == "function")
local toggle_tree = tree_spec.keys[1][2]
assert(tree_spec.keys[1][1] == "<leader>n" and type(toggle_tree) == "function")
assert(mappings["<C-m>"] == nil, "do not capture Enter as an explorer shortcut")
assert(vim.fn.filereadable(root .. "/nvim/.config/nvim/lua/mitander/plugins/nvim-tree.lua") == 0)
local lock = vim.json.decode(table.concat(vim.fn.readfile(root .. "/nvim/.config/nvim/lazy-lock.json"), "\n"))
assert(lock["oil.nvim"] and lock["nvim-tree.lua"], "pin both file browsers")

local status_opts = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/lualine.lua").opts()
local oil_directory, tree_directory = "/project/plugins/", "/project/dotfiles"
package.loaded["oil"] = {
    get_current_dir = function()
        return oil_directory
    end,
}
package.loaded["nvim-tree.core"] = {
    get_cwd = function()
        return tree_directory
    end,
}
local oil_title = status_opts.extensions[1].sections.lualine_c[1]
local tree_title = status_opts.extensions[2].sections.lualine_c[1]
assert(oil_title() == "Oil · plugins/" and tree_title() == "Tree · dotfiles/")
assert(status_opts.extensions[1].inactive_sections.lualine_c[1]() == oil_title())
assert(status_opts.extensions[2].inactive_sections.lualine_c[1]() == tree_title())
oil_directory = "/"
assert(oil_title() == "Oil · /")
oil_directory = "/project/100%/"
assert(oil_title() == "Oil · 100%%/")
oil_directory = nil
assert(oil_title() == "Oil")
package.loaded["oil"], package.loaded["nvim-tree.core"] = nil, nil

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
            assert(vim.trim(rendered) == expected, "unexpected browser statusline: " .. rendered)
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
        assert(vim.api.nvim_win_get_width(sidebar) == 34 and vim.wo.winfixwidth)
        assert(vim.fn.win_screenpos(sidebar)[2] < vim.fn.win_screenpos(target)[2], "sidebar must be on the left")
        assert(not vim.wo.number and not vim.wo.relativenumber)
        status_title("Oil · " .. vim.fn.fnamemodify(directory, ":t") .. "/")
        assert(vim.api.nvim_win_get_buf(target) == file_buffer, "opening sidebar replaced the editing buffer")

        -- Directories, including symlinks, stay in the sidebar. Files open beside it.
        for _, name in ipairs({ "child", "linked-child" }) do
            select(name)
            assert(
                vim.wait(3000, function()
                    local dir = oil.get_current_dir()
                    return dir and vim.uv.fs_realpath(dir) == vim.uv.fs_realpath(directory .. "/child")
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
                return vim.api.nvim_get_current_win() == target and vim.api.nvim_get_current_buf() == file_buffer
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
        assert(vim.api.nvim_win_get_width(sidebar) == 34)

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
        assert(#vim.api.nvim_tabpage_list_wins(0) == 1, "toggle from editing window must close sidebar")

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
        status_title("Tree · " .. vim.fn.fnamemodify(directory, ":t") .. "/")
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
                local lines = table.concat(vim.api.nvim_buf_get_lines(tree_buffer, 0, -1, false), "\n")
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

print("PASS: file browser configuration" .. (arg[1] and " and installed-plugin sidebar navigation" or ""))
vim.cmd("qa!")
