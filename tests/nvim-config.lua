-- Run with: nvim --clean --headless -l tests/nvim-config.lua
-- No plugin installation, live editor, clipboard, or tmux server is touched.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config = root .. "/nvim/.config/nvim"
local function spec(name)
    return dofile(config .. "/lua/mitander/plugins/" .. name .. ".lua")
end
local function key(plugin, lhs)
    for _, mapping in ipairs(plugin.keys or {}) do
        if mapping[1] == lhs then
            return mapping[2]
        end
    end
    error("Missing key: " .. lhs)
end

local tmux = spec("tmux")
assert(tmux.opts.copy_sync.sync_registers == false, "ordinary registers must remain local")
assert(tmux.opts.copy_sync.sync_clipboard == true, "explicit clipboard access must remain available")

-- Exercise local split navigation and inspect the single asynchronous tmux request.
vim.env.TMUX = "/tmp/not-a-real-tmux-server,1,0"
vim.env.TMUX_PANE = "%42"
local requests = {}
vim.system = function(command, opts, callback)
    assert(opts.text and callback)
    requests[#requests + 1] = command
    return {
        wait = function()
            error("navigation must not wait")
        end,
    }
end
vim.fn.system = function()
    error("configuration must not run blocking shell queries")
end
vim.fn.executable = function()
    return 1
end
vim.cmd.vsplit()
vim.cmd.wincmd("l")
local right = vim.api.nvim_get_current_win()
vim.cmd.wincmd("h")
local left = vim.api.nvim_get_current_win()
assert(left ~= right)
key(tmux, "<C-l>")()
assert(vim.api.nvim_get_current_win() == right, "local split navigation failed")
assert(#requests == 0, "local navigation must not spawn tmux")
key(tmux, "<C-l>")()
assert(#requests == 1, "cross-pane navigation should make one request")
assert(vim.deep_equal(requests[1], {
    "tmux",
    "if-shell",
    "-F",
    "-t",
    "%42",
    "#{pane_at_right}",
    "",
    "select-pane -t %42 -R",
}))
vim.env.TMUX = nil
key(tmux, "<C-l>")()
assert(#requests == 1, "standalone Neovim should not call tmux")

local tree_calls = {}
package.loaded["nvim-tree.api"] = {
    tree = {
        toggle = function(opts)
            tree_calls.toggle = opts
        end,
        find_file = function(opts)
            tree_calls.find = opts
        end,
    },
}
local tree = spec("nvim-tree")
key(tree, "<C-n>")()
assert(tree_calls.toggle.focus and tree_calls.toggle.update_root == false)
key(tree, "<leader>e")()
assert(tree_calls.find.open and tree_calls.find.focus)
assert(tree.lazy ~= false, "tree should only load when requested")
local oil_opened = false
package.loaded.oil = {
    open = function()
        oil_opened = true
    end,
}
local oil = spec("oil")
key(oil, "-")()
assert(oil_opened, "Oil should use its native directory editor")
assert(oil.opts.keymaps.q == "actions.close")
assert(not oil.config, "Oil should not implement a second sidebar lifecycle")

local conform = spec("conform")
assert(conform.opts.format_on_save.timeout_ms == 500)
assert(conform.opts.notify_on_error)
assert(not conform.opts.format_after_save, "save should not be modified asynchronously")
local format_args
package.loaded.conform = {
    format = function(opts)
        format_args = opts
    end,
}
key(conform, "<leader>f")()
assert(format_args.async, "explicit formatting should remain asynchronous")
local fzf = spec("fzf")
-- Multiprocess children fail to bootstrap config on this machine and yield
-- empty file lists; see the comment in fzf.lua.
assert(fzf.opts.files.multiprocess == false and fzf.opts.git.files.multiprocess == false)

local init = table.concat(vim.fn.readfile(config .. "/init.lua"), "\n")
assert(not init:find("lazy.reload", 1, true) and not init:find("lazy.core", 1, true))
assert(not init:find("silent! wa", 1, true), "configuration must not save unrelated buffers")
local lock = vim.json.decode(table.concat(vim.fn.readfile(config .. "/lazy-lock.json"), "\n"))
assert(lock["lazy.nvim"] and lock["tmux.nvim"] and lock["oil.nvim"])
for name, entry in pairs(lock) do
    assert(entry.commit:match("^%x+$") and #entry.commit == 40, "invalid lock entry: " .. name)
end
print("PASS: Neovim clipboard, navigation, browser, formatting, and lockfile configuration")
vim.cmd("qa!")
