-- Subprocess fixture for nvim-files.lua. Successful automatic quit exits before the watchdog.
local root, oil_path, tree_path, scenario = unpack(arg)
vim.opt.rtp:prepend(root .. "/nvim/.config/nvim")
vim.opt.rtp:prepend(oil_path)
vim.opt.rtp:prepend(tree_path)
local specs = dofile(root .. "/nvim/.config/nvim/lua/mitander/plugins/files.lua")
specs[1].config(nil, specs[1].opts)
local browser = require("mitander.file_browser")
local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        vim.fn.delete(directory, "rf")
    end,
})
vim.cmd.cd(vim.fn.fnameescape(directory))
local is_tree = scenario:find("tree", 1, true) ~= nil
local is_outline = scenario:find("outline", 1, true) ~= nil
local should_exit = scenario == "oil-exit"
    or scenario == "tree-exit"
    or scenario == "outline-exit"
    or scenario == "oil-float"
local original_tab = vim.api.nvim_get_current_tabpage()
if scenario:find("tab", 1, true) then
    vim.cmd.tabnew()
end
if scenario:find("hidden-dirty", 1, true) then
    local hidden = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(hidden, directory .. "/unsaved.txt")
    vim.api.nvim_buf_set_lines(hidden, 0, -1, false, { "keep me" })
end
local editor = vim.api.nvim_get_current_win()
if is_outline then
    -- Outline identifies its scratch sidebar with this filetype.
    vim.cmd.vnew()
    vim.bo.buftype = "nofile"
    vim.bo.filetype = "Outline"
elseif is_tree then
    require("nvim-tree").setup(specs[2].opts)
    browser.toggle_tree()
elseif scenario == "oil-standalone" then
    require("oil").open(directory)
    vim.cmd.vnew()
    editor = vim.api.nvim_get_current_win()
else
    browser.open()
end
assert(vim.wait(3000, function()
    return vim.bo.filetype == (is_outline and "Outline" or is_tree and "NvimTree" or "oil")
        or scenario == "oil-standalone"
end))
-- Let Oil finish its asynchronous initial render before introducing unsaved edits.
vim.wait(100)
local sidebar = vim.api.nvim_get_current_win()
if scenario == "oil-dirty" then
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "unsaved-entry" })
elseif scenario == "oil-float" then
    vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
        relative = "editor",
        row = 1,
        col = 1,
        width = 10,
        height = 2,
    })
elseif scenario == "oil-split" or scenario == "outline-split" then
    vim.api.nvim_set_current_win(editor)
    vim.cmd.vnew()
end
vim.api.nvim_set_current_win(editor)
if scenario == "oil-background-tab" then
    vim.api.nvim_set_current_tabpage(original_tab)
    vim.api.nvim_win_close(editor, false)
else
    vim.cmd.quit()
end
if scenario == "oil-stale" or scenario == "outline-stale" then
    vim.api.nvim_set_current_win(sidebar)
    vim.cmd.vnew()
end
vim.defer_fn(function()
    if should_exit then
        io.stderr:write("orphan sidebar did not quit: " .. scenario .. "\n")
        vim.cmd.cquit()
    end
    if scenario:find("tab", 1, true) then
        assert(#vim.api.nvim_list_tabpages() == 1, "orphan tab stayed open")
        assert(vim.api.nvim_get_current_tabpage() == original_tab, "closed the wrong tab")
    elseif scenario == "oil-dirty" then
        assert(vim.bo[vim.api.nvim_win_get_buf(sidebar)].modified, "discarded Oil edits")
    elseif scenario:find("hidden-dirty", 1, true) then
        assert(vim.fn.getbufinfo({ bufmodified = 1 })[1], "discarded hidden edits")
    elseif scenario == "oil-standalone" then
        assert(vim.bo.filetype == "oil", "closed standalone Oil")
    else
        assert(#vim.api.nvim_tabpage_list_wins(0) == 2, "closed a live editing layout")
    end
    print("SURVIVED: " .. scenario)
    vim.cmd("qa!")
end, 200)
vim.wait(2000, function()
    return false
end)
error("quit fixture timed out")
