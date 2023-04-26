-- mapping functions
local map = vim.api.nvim_set_keymap
local nnoremap = require("utils").bind "n"
local nnoremap_buf = require("utils").bind_buf "n"

-- leader
vim.g.mapleader = " "

-- better line navigation
map("n", "j", "gj", {})
map("n", "k", "gk", {})

-- keep visual block on indentation
map("v", "<", "<gv", {})
map("v", ">", ">gv", {})

-- disable ex-mode
map("n", "q", "<nop>", {})

-- don't yank on paste
map("x", "p", "pgvy", {})

-- open/reload config
nnoremap("<leader>c", ":tabnew ~/dotfiles/nvim/.config/nvim/init.lua")
nnoremap("<leader>rl", ":luafile ~/dotfiles/nvim/.config/nvim/init.lua")

-- clear highlight
nnoremap("<enter>", ":noh")

-- tab navigation
nnoremap("<s-h>", ":tabp")
nnoremap("<s-l>", ":tabn")
nnoremap("<s-q>", ":tabc")
nnoremap("<c-t>", ":tabe")

-- rotate split layout
nnoremap("<c-w>s", ":wincmd L")
nnoremap("<c-w>v", ":wincmd J")

-- resize splits
nnoremap("<s-up>", ":resize -5")
nnoremap("<s-down>", ":resize +5")
nnoremap("<s-left>", ":resize +5")
nnoremap("<s-right>", ":resize -5")

-- toggle colorcolumn
nnoremap("<leader>.", ":execute 'set cc=' . (&colorcolumn == '' ? '100' : '')")

-- reload modules
nnoremap("<leader>rl", "lua require('keymaps').reload()")

local M = {}

function M.nvimtree()
    nnoremap("<c-n>", "NvimTreeToggle")
end

function M.toggleterm()
    nnoremap("<leader>gg", "lua _lazygit_toggle()")
end

function M.fugitive()
    nnoremap("gb", "Git blame")
end

function M.commentary()
    vim.cmd [[map <silent> <leader>/ :Commentary<enter>]]
end

function M.undotree()
    nnoremap("<leader>u", "UndotreeToggle")
end

function M.gitsigns()
    nnoremap("gp", "Gitsigns preview_hunk")
    nnoremap("g.", "Gitsigns toggle_signs")
    nnoremap("g,", "Gitsigns toggle_current_line_blame")
    nnoremap("gl", "Gitsigns blame_line")
    nnoremap("<leader><bs>", "Gitsigns reset_hunk")
end

function M.lsp(bufnr)
    nnoremap_buf(bufnr, "gr", "lua vim.lsp.buf.references()", {})
    nnoremap_buf(bufnr, "gd", "lua vim.lsp.buf.definition()", {})
    nnoremap_buf(bufnr, "<leader>rn", "lua vim.lsp.buf.rename()", {})
    nnoremap_buf(bufnr, "gi", "lua vim.lsp.buf.implementation()", {})
    nnoremap_buf(bufnr, "go", "lua vim.diagnostic.open_float()", {})
    nnoremap_buf(bufnr, "[d", "lua vim.diagnostic.goto_prev()", {})
    nnoremap_buf(bufnr, "]d", "lua vim.diagnostic.goto_next()", {})
    nnoremap_buf(bufnr, "<leader>d", "lua vim.diagnostic.setloclist()", {})
    nnoremap_buf(bufnr, "K", "lua vim.lsp.buf.hover()", {})
    nnoremap_buf(bufnr, "ga", "lua vim.lsp.buf.code_action()", {})
end

function M.telescope()
    vim.cmd [[command! Files exec (len(system('git rev-parse'))) ? ':Telescope find_files' : ':Telescope git_files']]
    nnoremap("<c-p>", "Files")
    nnoremap("<c-f>", "Telescope live_grep")
    nnoremap("<c-b>", "Telescope buffers")
    nnoremap("<leader>h", "Telescope help_tags")
    nnoremap("<leader>p", "Telescope projects")
    nnoremap("<leader>gs", "Telescope git_status")
    nnoremap("<leader>gl", "Telescope git_commits")
    nnoremap("<leader>gb", "Telescope git_branches")
    nnoremap("<leader>gc", "Telescope git_bcommits")
end

function M.reload()
    for _, file in ipairs(vim.fn.readdir(vim.fn.stdpath "config" .. "/lua", [[v:val =~ '\.lua$']])) do
        local name = file:gsub("%.lua$", "")
        require("plenary.reload").reload_module(name)
    end
    for _, file in ipairs(vim.fn.readdir(vim.fn.stdpath "config" .. "/lua/plugins", [[v:val =~ '\.lua$']])) do
        local name = "plugins." .. file:gsub("%.lua$", "")
        require("plenary.reload").reload_module(name)
    end
    print "modules reloaded"
end

return M
