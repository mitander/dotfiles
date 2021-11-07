" plugins
call plug#begin('~/.vim/plugged')
	Plug 'neoclide/coc.nvim', {'branch': 'release'}
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	Plug 'tpope/vim-fugitive'
	Plug 'fatih/vim-go'
	Plug 'SirVer/ultisnips'
	Plug 'mbbill/undotree'
	Plug 'nanotech/jellybeans.vim'
	Plug 'ziglang/zig.vim'
	Plug 'kevinhwang91/nvim-bqf'
	Plug 'nvim-treesitter/nvim-treesitter'
	Plug 'ziglang/zig.vim'
	Plug 'neovim/nvim-lspconfig'
	Plug 'lewis6991/gitsigns.nvim'
	Plug 'nvim-lua/plenary.nvim'
	Plug 'hrsh7th/nvim-cmp'
	Plug 'hrsh7th/cmp-nvim-lsp'
	Plug 'dstein64/nvim-scrollview'
call plug#end()

" settings
set mouse=a
set number
set ruler
set tabstop=4
set shiftwidth=4
set smartcase
set ignorecase
set nobackup
set nowritebackup
set undodir=~/.vim/undodir
set undofile
set scrolloff=8
set updatetime=50
set shortmess+=c
set laststatus=2
set background=dark
set autoindent noexpandtab

" colorscheme
syntax on
colorscheme jellybeans

" colors
hi GitSignsChange ctermfg=yellow ctermbg=NONE
hi StatusLineNC ctermbg=236 ctermfg=243
hi StatusLine ctermbg=236 ctermfg=253
hi SignColumn ctermbg=NONE
hi NonText ctermbg=NONE
hi Normal ctermbg=NONE
hi LineNr ctermbg=NONE ctermfg=NONE
hi Comment ctermfg=gray

" binds
let mapleader = " "
nnoremap <silent> <C-h> :wincmd h<CR>
nnoremap <silent> <C-j> :wincmd j<CR>
nnoremap <silent> <C-k> :wincmd k<CR>
nnoremap <silent> <C-l> :wincmd l<CR>
nnoremap <silent> <C-f> :Rg<CR>
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <C-b> :Buffer<CR>
nnoremap <silent> <C-n> :Lexplore<CR>
nnoremap <silent> <leader>u :UndotreeShow<CR>
nnoremap <silent> <leader>/ :noh<CR>
nnoremap <silent> <leader> p "_dP
nnoremap <silent> gb :Git blame<CR>
nnoremap <silent> gc :Commits<CR>
nnoremap <silent> gp :Gitsigns preview_hunk<CR>
nnoremap <silent> gp :Gitsigns toggle_signs<CR>

" lsp binds
nnoremap <silent> K :lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD :lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> gd :lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gi :lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> gr :lua vim.lsp.buf.references()<CR>
nnoremap <silent> gl :lua vim.lsp.diagnostic.show_line_diagnostics()<CR>
nnoremap <silent> <C-]> :lua vim.lsp.diagnostic.goto_next()<CR>
nnoremap <silent> <C-[> :lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent> <leader>rn :lua vim.lsp.buf.rename()<CR>

" move line
nnoremap <silent> <A-j> :m .+1<CR>==
nnoremap <silent> <A-k> :m .-2<CR>==
vnoremap <silent> <A-j> :m '>+1<CR>gv=gv
vnoremap <silent> <A-k> :m '<-2<CR>gv=gv
inoremap <silent> <A-j> <Esc>:m .+1<CR>==gi
inoremap <silent> <A-k> <Esc>:m .-2<CR>==gi

" fzf settings
let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --preview 'batcat --color=always --style=header,grid --line-range :300 {}'"
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9 } }
let g:fzf_action = { 'ctrl-t': 'tab split', 'ctrl-s': 'split', 'ctrl-v': 'vsplit' }

" rg settings
if executable('Rg')
    let g:rg_derive_root = 1
endif

" netrw settings
let g:netrw_chgwin=3
let g:netrw_browse_split=1
let g:netrw_winsize=20
let g:netrw_liststyle=3
let g:netrw_banner = 0

" commands
augroup highlight_yank
    autocmd!
	autocmd TextYankPost * silent! lua vim.highlight.on_yank({timeout = 100})
augroup END

augroup q_buffer_quit
    autocmd!
	autocmd FileType qf :nnoremap <silent> <buffer>q :q<CR>
augroup END

augroup netrw_mapping
    autocmd!
    autocmd FileType netrw :nnoremap <buffer> <C-l> :wincmd l<CR>
augroup END

autocmd BufWritePre * :call TrimWhitespace()
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

" setup lua plugins
lua require('setup')
