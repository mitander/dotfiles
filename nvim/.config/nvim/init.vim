let $vimrc="$HOME/dotfiles/nvim/.config/nvim/init.vim"

" lua plugins
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

" general mappings
let mapleader=" "
map <space> <nop>

nnoremap <silent><leader>c :tabnew $vimrc<enter>
nnoremap <silent> <enter> :noh<enter>

nnoremap <silent> <c-w><C-h> gT
nnoremap <silent> <c-w><C-l> gt

nnoremap <silent> <s-h> :bprev <enter>
nnoremap <silent> <s-l> :bnext <enter>
nnoremap <silent> <s-q> :bd <enter>

nnoremap <silent> <c-w>s :wincmd L <enter>
nnoremap <silent> <c-w>v :wincmd J <enter>

nnoremap <silent> <s-up> :resize -5<enter>
nnoremap <silent> <s-down> :resize +5<enter>
nnoremap <silent> <s-left> :vertical resize +5<enter>
nnoremap <silent> <s-right> :vertical resize -5<enter>

nnoremap <silent> j gj
nnoremap <silent> k gk

vnoremap <silent> < <gv
vnoremap <silent> > >gv

nnoremap <silent> q <nop>
xnoremap <silent> p pgvy

" abbreviations
cabbrev W w
cabbrev Q q
cabbrev Wq wq
cabbrev q q

" auto-commands
autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Visual', timeout = 200})
autocmd BufWritePre * :%s/\s\+$//e
autocmd InsertLeave * set nopaste

autocmd FileType qf nnoremap <silent> <buffer> q :close<enter>
autocmd FileType qf nnoremap <silent> <buffer> <enter> <enter>:cclose<enter>

autocmd Filetype rust,zig,go,c,cpp setlocal colorcolumn=100
autocmd Filetype rust,zig,go,c,cpp setlocal tabstop=4 shiftwidth=4
