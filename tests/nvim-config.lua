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
local clipboard_before = vim.o.clipboard
local provider_before = vim.g.clipboard
local tmux_before = vim.env.TMUX
vim.env.TMUX = nil
tmux.init()
assert(vim.o.clipboard == clipboard_before and vim.deep_equal(vim.g.clipboard, provider_before))
vim.env.TMUX = tmux_before

-- Exercise local split navigation and inspect the single asynchronous tmux request.
vim.env.TMUX = "/tmp/not-a-real-tmux-server,1,0"
vim.env.TMUX_PANE = "%42"
local requests = {}
local completions = {}
vim.system = function(command, opts, callback)
    assert(opts.text and callback)
    requests[#requests + 1] = command
    completions[#requests] = callback
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
tmux.init()
assert(vim.tbl_contains(vim.opt.clipboard:get(), "unnamedplus"), "ordinary operations must share the clipboard")
assert(vim.deep_equal(vim.g.clipboard.copy["+"], { "tmux", "load-buffer", "-w", "-" }))
assert(vim.deep_equal(vim.g.clipboard.paste["+"], { "tmux", "save-buffer", "-" }))
assert(vim.g.clipboard.cache_enabled == 0, "clipboard writes must finish before the next operation")
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

-- Role callbacks use literal argv, with no legacy policy wrapper.
vim.env.TMUX = "/tmp/not-a-real-tmux-server,1,0"
for lhs, role in pairs({
    ["<leader>Te"] = "edit",
    ["<leader>Ts"] = "term",
    ["<leader>Ta"] = "agent",
    ["<leader>Tt"] = "tracker",
}) do
    key(tmux, lhs)()
    assert(vim.deep_equal(requests[#requests], { "myran", "role", "open", role, vim.fn.getcwd() }))
end
key(tmux, "<leader>TA")()
assert(vim.deep_equal(requests[#requests], { "myran", "role", "split", "agent", vim.fn.getcwd() }))
local lazygit = spec("lazygit")
local git_requests = #requests
key(lazygit, "<leader>gg")()
assert(#requests == git_requests + 1, "Git role should launch asynchronously")
assert(vim.deep_equal(requests[#requests], { "myran", "role", "open", "git", vim.fn.getcwd() }))
vim.env.TMUX = nil
local native_git = false
vim.api.nvim_create_user_command("LazyGit", function()
    native_git = true
end, {})
key(lazygit, "<leader>gg")()
assert(native_git, "standalone LazyGit must remain native")
local before = #requests
local saved_notify = vim.notify
vim.notify = function() end
key(tmux, "<leader>TA")()
vim.notify = saved_notify
assert(#requests == before, "standalone role split must not call Myran")

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
local oil_opened = false
package.loaded.oil = {
    open = function()
        oil_opened = true
    end,
}
local oil = spec("oil")
key(oil, "-")()
assert(oil_opened, "Oil should use its native directory editor")

local conform = spec("conform")
local format_args
package.loaded.conform = {
    format = function(opts)
        format_args = opts
    end,
}
key(conform, "<leader>f")()
assert(format_args.async, "explicit formatting should remain asynchronous")

local fzf = spec("fzf")
local files
package.loaded["fzf-lua"] = {
    files = function(opts)
        files = opts
    end,
}
local cwd = vim.fn.getcwd()
local project = vim.fn.tempname()
vim.fn.mkdir(project .. "/src", "p")
project = vim.uv.fs_realpath(project)
vim.api.nvim_set_current_dir(project .. "/src")
key(fzf, "<c-p>")()
assert(files == nil, "project picker must not wait for Git")
assert(vim.deep_equal(requests[#requests], { "git", "-C", project .. "/src", "rev-parse", "--show-toplevel" }))
completions[#requests]({ code = 0, stdout = project .. "\n" })
assert(vim.wait(100, function()
    return files ~= nil
end))
assert(files.cwd == project)
local git_dir, git_work_tree = vim.env.GIT_DIR, vim.env.GIT_WORK_TREE
vim.env.GIT_DIR = project .. "/metadata"
vim.env.GIT_WORK_TREE = project .. "/custom-root"
files = nil
key(fzf, "<c-p>")()
completions[#requests]({ code = 0, stdout = vim.env.GIT_WORK_TREE .. "\n" })
assert(vim.wait(100, function()
    return files ~= nil
end))
assert(files.cwd == vim.env.GIT_WORK_TREE, "custom Git roots must come from Git")
vim.env.GIT_DIR, vim.env.GIT_WORK_TREE = git_dir, git_work_tree
files = nil
key(fzf, "<c-p>")()
completions[#requests]({ code = 1, stdout = "" })
assert(vim.wait(100, function()
    return files ~= nil
end))
assert(files.cwd == project .. "/src", "outside Git the picker must use the invoking cwd")
vim.api.nvim_set_current_dir(cwd)
vim.fn.delete(project, "rf")
print("PASS: Neovim clipboard, navigation, role routing, browser, and project picker behavior")
vim.cmd("qa!")
