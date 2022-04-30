" initialize plugins with packer
lua require("plugins.packer")

" options
set noswapfile
set nobackup
set hlsearch
set incsearch
set hidden
set mouse=a
set number
set ruler
set cursorline
set smartcase
set ignorecase
set noshowmode
set scrolloff=8
set updatetime=200
set shortmess+=c
set background=dark
set smartindent
set expandtab
set autoread
set wildmode=longest:full,full
set wildmenu
set history=1000
set scrolloff=8
set virtualedit=block
set wildignore+=*.o,*.obj
set switchbuf=useopen,usetab
set splitbelow splitright
set shell=/bin/zsh
set signcolumn=yes
set path+=**
set tabstop=4 shiftwidth=4
set termguicolors
set undodir=~/.vim/tmp/undodir
set undofile
syntax on

" leader
let mapleader=" "
map <space> <nop>

" open config
let $vimrc="~/dotfiles/nvim/.config/nvim/init.vim"
nnoremap <silent><leader>c :tabnew $vimrc<enter>

" clear highlight
nnoremap <silent> <enter> :noh<enter>

" tab navigation
nnoremap <silent> <c-w><C-h> gT
nnoremap <silent> <c-w><C-l> gt

" buffer navigation
nnoremap <silent> <s-h> :bprev <enter>
nnoremap <silent> <s-l> :bnext <enter>
nnoremap <silent> <s-q> :bd <enter>

" rotate split layout
nnoremap <silent> <c-w>s :wincmd L <enter>
nnoremap <silent> <c-w>v :wincmd J <enter>

" resize splits
nnoremap <silent> <s-up> :resize -5<enter>
nnoremap <silent> <s-down> :resize +5<enter>
nnoremap <silent> <s-left> :vertical resize +5<enter>
nnoremap <silent> <s-right> :vertical resize -5<enter>

" better line navigation
nnoremap <silent> j gj
nnoremap <silent> k gk

" keep visual block on indentation
vnoremap <silent> < <gv
vnoremap <silent> > >gv

" disable ex-mode
nnoremap <silent> q <nop>

" don't yank on paste
xnoremap <silent> p pgvy

" abbreviate quit/save commands
cab W w
cab Q q
cab Wq wq
cab wQ wq
cab WQ wq

" highlight on yank
autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Visual', timeout = 200})

" remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" better paste
autocmd InsertLeave * set nopaste

" quickfix binds
autocmd FileType qf nnoremap <silent> <buffer> q :close<enter>
autocmd FileType qf nnoremap <silent> <buffer> <enter> <enter>:cclose<enter>

" indentation
autocmd Filetype rust,zig,go,c,cpp setlocal tabstop=4 shiftwidth=4

" use cursorline in normal mode and colorcolumn in insert mode
autocmd InsertEnter * setlocal nocul cc=100,101
autocmd InsertLeave * setlocal cul cc=0
