-- packages
local paq = require('paq-nvim').paq
paq {'savq/paq-nvim', opt = true}
paq {'junegunn/fzf', run = vim.fn['fzf#install']}
paq {'junegunn/fzf.vim'}
paq {'nvim-treesitter/nvim-treesitter'}
paq {'neovim/nvim-lspconfig'}
paq {'kevinhwang91/nvim-bqf'}
paq {'ziglang/zig.vim'}
paq {'fatih/vim-go'}
paq {'tpope/vim-fugitive'}
paq {'SirVer/ultisnips'}
paq {'mbbill/undotree'}
paq {'nanotech/jellybeans.vim'}
paq {'neovim/nvim-lspconfig'}
paq {'lewis6991/gitsigns.nvim'}
paq {'hrsh7th/nvim-cmp'}
paq {'hrsh7th/cmp-nvim-lsp'}
paq {'dstein64/nvim-scrollview'}

-- settings
vim.opt.mouse = 'a'
vim.opt.number = true
vim.opt.ruler = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.scrolloff = 8
vim.opt.expandtab = false
vim.opt.autoindent = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undodir = '.vim/undodir'
vim.opt.undofile = true
vim.opt.updatetime = 50
vim.opt.wrap = false
vim.opt.laststatus = 2
vim.opt.background = 'dark'
vim.opt.shortmess:append {c = true}


-- colors
local cmd = vim.cmd
cmd('colorscheme jellybeans')
cmd('syntax on')
cmd('hi StatusLineNC ctermbg=236 ctermfg=243')
cmd('hi StatusLine ctermbg=236 ctermfg=253')
cmd('hi SignColumn ctermbg=NONE')
cmd('hi NonText ctermbg=NONE')
cmd('hi Normal ctermbg=NONE')
cmd('hi Normal ctermbg=NONE')
cmd('hi LineNr ctermbg=NONE ctermfg=NONE')
cmd('hi Comment ctermfg=gray')

--- commands
cmd 'au TextYankPost * lua vim.highlight.on_yank {on_visual = true}'
cmd 'au FileType qf :nnoremap <buffer><esc> :q<CR>'
-- TODO: fix whitespace removal on save

-- keybinds
vim.g.mapleader = " "

local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then options = vim.tbl_extend('force', options, opts) end
  vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

map('n', '<leader>u', '<cmd>UndotreeShow<CR>')
map('n', '<leader>/', '<cmd>noh<CR>')
map('n', '<leader>p', '<cmd>"_dP<CR>')
map('n', '<leader>gb', '<cmd>Git blame<CR>')
map('n', '<C-h>', '<cmd>wincmd h<CR>')
map('n', '<C-l>', '<cmd>wincmd l<CR>')
map('n', '<C-j>', '<cmd>wincmd j<CR>')
map('n', '<C-k>', '<cmd>wincmd k<CR>')
map('n', '<C-f>', '<cmd>Rg<CR>')
map('n', '<C-p>', '<cmd>Files<CR>')
map('n', '<C-b>', '<cmd>Buffer<CR>')
map('n', '<A-j>', '<cmd>m .+1<CR>==')
map('n', '<A-k>', '<cmd>m .-2<CR>==')
map('i', '<A-j>', '<Esc><cmd>m .+1<CR>==gi')
map('i', '<A-k>', '<Esc><cmd>m .-2<CR>==gi')
map('v', '<A-j>', "<cmd>m '>+1<CR>gv=gv")
map('v', '<A-k>', "<cmd>m '<-2<CR>gv=gv")
map('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>')
map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>')
map('n', 'gl', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>')
map('n', 'gn', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>')
map('n', 'gp', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>')
map('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')

-- setup treesitter
local ts = require 'nvim-treesitter.configs'
ts.setup {ensure_installed = 'maintained', highlight = {enable = true}}

-- setup cmp
local cmp = require 'cmp'
cmp.setup({
    snippet = { expand = function(args) vim.fn["UltiSnips#Anon"](args.body) end },
    sources = cmp.config.sources({{ name = 'nvim_lsp' },{ name = 'buffer' }}),
    mapping = {
      ['<C-u>'] = cmp.mapping.scroll_docs((-4), { 'i', 'c' }),
      ['<C-d>'] = cmp.mapping.scroll_docs((4), { 'i', 'c' }),
      ['<CR>'] = cmp.mapping.confirm({ select = false }),
    }
})

-- setup lsp
local lsp = require 'lspconfig'
local cap = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())

lsp.zls.setup {capabilities = cap} 
lsp.ccls.setup {capabilities = cap} 
lsp.gopls.setup {capabilities = cap} 
lsp.tsserver.setup {capabilities = cap} 
