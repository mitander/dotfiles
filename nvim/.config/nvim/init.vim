call plug#begin('~/.vim/plugged')
	Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
	Plug 'junegunn/fzf.vim'
	Plug 'tpope/vim-fugitive'
	Plug 'fatih/vim-go'
	Plug 'ziglang/zig.vim'
	Plug 'SirVer/ultisnips'
	Plug 'mbbill/undotree'
	Plug 'nanotech/jellybeans.vim'
	Plug 'kevinhwang91/nvim-bqf'
	Plug 'lewis6991/gitsigns.nvim'
	Plug 'nvim-lua/plenary.nvim'
	Plug 'hrsh7th/nvim-cmp'
	Plug 'hrsh7th/cmp-nvim-lsp'
	Plug 'neovim/nvim-lspconfig'
	Plug 'dstein64/nvim-scrollview'
call plug#end()

" setup lua plugins
lua require('setup')

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
set smartindent expandtab

" colorscheme
syntax on
colorscheme jellybeans

" colors
hi GitSignsChange ctermbg=NONE   ctermfg=yellow
hi StatusLineNC   ctermbg=236    ctermfg=243
hi StatusLine     ctermbg=236    ctermfg=253
hi SignColumn     ctermbg=NONE	 ctermfg=236
hi VertSplit      ctermbg=NONE   ctermfg=236
hi LineNr         ctermbg=NONE   ctermfg=NONE
hi Normal         ctermbg=NONE   ctermfg=NONE
hi NonText        ctermbg=NONE   ctermfg=NONE
hi Comment        ctermbg=NONE   ctermfg=gray

" binds
let mapleader=" "
map <space> <nop>

nnoremap <silent> <leader>u :UndotreeShow<CR>
nnoremap <silent> <leader>/ :noh<CR>
nnoremap <silent> <leader>p "_dP
nnoremap <silent> <C-p> :CtrlP<CR>
nnoremap <silent> <C-f> :Rg<CR>
nnoremap <silent> <C-b> :Buffer<CR>
nnoremap <silent> <C-n> :Lexplore<CR>
nnoremap <silent> gs :Git<CR>
nnoremap <silent> gb :Git blame<CR>
nnoremap <silent> gl :Commits<CR>
nnoremap <silent> gp :Gitsigns preview_hunk<CR>
nnoremap <silent> g. :Gitsigns toggle_signs<CR>

" window
nnoremap <silent> <C-h> :wincmd h<CR>
nnoremap <silent> <C-j> :wincmd j<CR>
nnoremap <silent> <C-k> :wincmd k<CR>
nnoremap <silent> <C-l> :wincmd l<CR>

" lsp
nnoremap <silent> K :lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD :lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> gd :lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gi :lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> gr :lua vim.lsp.buf.references()<CR>
nnoremap <silent> g] :lua vim.lsp.diagnostic.goto_next()<CR>
nnoremap <silent> g[ :lua vim.lsp.diagnostic.goto_prev()<CR>
nnoremap <silent> <leader>rn :lua vim.lsp.buf.rename()<CR>

" move lines
nnoremap <silent> j gj
nnoremap <silent> k gk
nnoremap <silent> <A-j> :m .+1<CR>==
nnoremap <silent> <A-k> :m .-2<CR>==
vnoremap <silent> <A-j> :m '>+1<CR>gv=gv
vnoremap <silent> <A-k> :m '<-2<CR>gv=gv
inoremap <silent> <A-j> <Esc>:m .+1<CR>==gi
inoremap <silent> <A-k> <Esc>:m .-2<CR>==gi

" fzf settings
let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --preview 'batcat --color=always --style=header,grid --line-range :300 {}'"
let g:fzf_layout = { 'window': { 'width': 0.6, 'height': 0.6 } }
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
autocmd TextYankPost * silent! lua vim.highlight.on_yank({timeout = 100})
autocmd BufWritePre * :%s/\s\+$//e
autocmd FileType qf :nnoremap <silent> <buffer><esc> :q<CR>
autocmd FileType qf :nnoremap <silent> <buffer><CR> <CR>:cclose<CR>
autocmd FileType * :nnoremap <silent> <buffer> <C-l> :wincmd l<CR>

command! CtrlP execute (len(system('git rev-parse'))) ? ':Files' : ':GFiles'
