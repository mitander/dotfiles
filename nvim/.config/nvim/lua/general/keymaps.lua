local map = vim.api.nvim_set_keymap

-- helpers
local bind = function(mode, outer_opts)
	outer_opts = outer_opts or { noremap = true, silent = true }
	return function(key, cmd, opts)
		cmd = "<cmd>" .. cmd .. "<enter>"
		opts = vim.tbl_extend("force", outer_opts, opts or {})
		vim.api.nvim_set_keymap(mode, key, cmd, opts)
	end
end

local bind_buf = function(mode, outer_opts)
	outer_opts = outer_opts or { noremap = true, silent = true }
	return function(buf, key, cmd, opts)
		cmd = "<cmd>" .. cmd .. "<enter>"
		opts = vim.tbl_extend("force", opts, opts or {})
		vim.api.nvim_buf_set_keymap(buf, mode, key, cmd, opts)
	end
end

-- map funcs
local nnoremap = bind("n")
local vnoremap = bind("v")
local xnoremap = bind("x")
local inoremap = bind("i")

local nnoremap_buf = bind_buf("n")
local vnoremap_buf = bind_buf("v")
local xnoremap_buf = bind_buf("x")
local inoremap_buf = bind_buf("i")

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
	vim.cmd([[map <silent> <leader>/ :Commentary<enter>]])
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

function M.fzf()
	vim.cmd([[
        " fzf
        command! CtrlP execute (len(system('git rev-parse'))) ? ':Files' : ':GFiles --cached --others --exclude-standard'
        command! -bang -nargs=* Rg call fzf#vim#grep('rg --column --no-heading --color=always --hidden --smart-case -g "!{.git,vendor,.vscode,.gitlab,*cache*}/*" '.shellescape(<q-args>), 1,  0)
        nnoremap <silent> <c-p> :CtrlP<enter>
        nnoremap <silent> <c-f> :Rg<enter>

        let g:fzf_layout = {'down': '35%'}
        let g:fzf_preview_window = ['right:hidden', 'ctrl-_']
        let g:fzf_action = {'ctrl-t':'tab split','ctrl-s':'split','ctrl-v':'vsplit' }
    ]])
end

return M
