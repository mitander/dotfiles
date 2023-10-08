-- leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- helper functions
local vmap = function(tbl)
    vim.keymap.set("v", tbl[1], tbl[2], tbl[3])
end

local nmap = function(tbl)
    vim.keymap.set("n", tbl[1], tbl[2], tbl[3])
end

local nmap_cmd = function(tbl)
    tbl[2] = "<cmd>" .. tbl[2] .. "<enter>"
    vim.keymap.set("n", tbl[1], tbl[2], tbl[3])
end

local nmap_buf = function(tbl)
    if tbl[3] == nil then
        tbl[3] = { buffer = 0 }
    end
    nmap(tbl)
end

-- just exit pls
vim.cmd [[
    cab W w
    cab Q q
    cab Wq wq
    cab wQ wq
    cab WQ wq
]]

-- better line navigation
nmap { "j", "gj" }
nmap { "k", "gk" }

-- keep visual block on indentation
vmap { "<", "<gv" }
vmap { ">", ">gv" }

-- disable ex-mode
nmap { "q", "<nop>" }

-- don't yank on paste
vmap { "p", "pgvy" }

-- clear highlight
nmap_cmd { "<enter>", "noh" }

-- tab navigation
nmap_cmd { "<s-h>", "tabp" }
nmap_cmd { "<s-l>", "tabn" }
nmap_cmd { "<s-q>", "tabc" }
nmap_cmd { "<c-t>", "tabe" }

-- rotate split layout
nmap_cmd { "<c-w>s", "wincmd L" }
nmap_cmd { "<c-w>v", "wincmd J" }

-- resize splits
nmap_cmd { "<s-up>", "resize -5" }
nmap_cmd { "<s-down>", "resize +5" }
nmap_cmd { "<s-left>", "resize +5" }
nmap_cmd { "<s-right>", "resize -5" }

-- toggle colorcolumn
nmap_cmd { "<leader>.", "execute 'set cc=' . (&colorcolumn == '' ? '100' : '')" }

-- compile
nmap_cmd { "<leader><cr>", "make" }

local M = {}

M.nvimtree = function()
    nmap { "<c-n>", require("nvim-tree.api").tree.toggle }
end

M.lazygit = function()
    nmap_cmd { "<leader>gg", "LazyGit" }
end

M.fugitive = function()
    nmap_cmd { "gb", "Git blame" }
end

M.commentary = function()
    vim.cmd [[map <silent> <leader>/ :Commentary<enter>]]
end

M.undotree = function()
    nmap_cmd { "<leader>u", "UndotreeToggle" }
end

M.gitsigns = function()
    nmap { "gp", require("gitsigns").preview_hunk_inline }
    nmap { "g.", require("gitsigns").toggle_signs }
    nmap { "[g", require("gitsigns").prev_hunk }
    nmap { "]g", require("gitsigns").next_hunk }
    nmap { "g,", require("gitsigns").toggle_current_line_blame }
    nmap { "gl", require("gitsigns").blame_line }
    nmap { "<leader><bs>", require("gitsigns").reset_hunk }
end

M.lsp = function(bufnr)
    local opts = { buffer = bufnr, remap = false }
    nmap_buf { "gr", vim.lsp.buf.references, opts }
    nmap_buf { "gd", vim.lsp.buf.definition, opts }
    nmap_buf { "gi", vim.lsp.buf.implementation, opts }
    nmap_buf { "go", vim.diagnostic.open_float, opts }
    nmap_buf { "[d", vim.diagnostic.goto_prev, opts }
    nmap_buf { "]d", vim.diagnostic.goto_next, opts }
    nmap_buf { "<leader>d", vim.diagnostic.setloclist, opts }
    nmap_buf { "<leader>rn", vim.lsp.buf.rename, opts }
    nmap_buf { "K", vim.lsp.buf.hover, opts }
    nmap_buf { "ga", vim.lsp.buf.code_action, opts }
end

M.dap = function()
    nmap { "<leader>dr", function()
        require("dap").continue()
        require("dap").open()
    end }
    nmap { "<leader>q", function()
        require("dap").terminate()
        require("dap").close()
    end }
    nmap { "<leader>bp", require 'dap'.toggle_breakpoint }
    nmap { "<leader>bd", require 'dap'.clear_breakpoints }
    nmap { "<leader>so", require 'dap'.step_over }
    nmap { "<leader>si", require 'dap'.step_into }
    nmap { "<leader>du", require 'dapui'.toggle }
end

M.fzf = function()
    vim.cmd [[command! Files exec (len(system('git rev-parse'))) ? ':FzfLua files' : ':FzfLua git_files']]
    nmap_cmd { "<c-p>", "Files" }
    nmap { "<c-f>", require("fzf-lua").grep_project }
    nmap { "<c-b>", require("fzf-lua").buffers }
    nmap { "<leader>h", require("fzf-lua").help_tags }
    nmap { "<leader>gs", require("fzf-lua").git_status }
    nmap { "<leader>gl", require("fzf-lua").git_commits }
    nmap { "<leader>gb", require("fzf-lua").git_branches }
    nmap { "<leader>gc", require("fzf-lua").git_bcommits }
    nmap { "<leader>p", require("fzf-lua").tmux_buffers }
end

return M
