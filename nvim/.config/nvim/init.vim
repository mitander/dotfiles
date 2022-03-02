source ~/.config/nvim/plugins.vim

set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath

set noswapfile
set nobackup
set nolist
set hlsearch
set incsearch
set hidden
set mouse=a
set number
set ruler
set tabstop=2
set shiftwidth=2
set smartcase
set ignorecase
set scrolloff=8
set updatetime=50
set shortmess+=c
set background=dark
set smartindent
set expandtab
set linebreak
set autoread
set wildmode=longest:full,full
set history=1000
set scrolloff=8
set ttimeoutlen=50
set virtualedit=block
set wildignore+=*.o
set switchbuf=useopen,usetab
set splitbelow splitright
set shell=/bin/zsh
set signcolumn=yes
set laststatus=2
set statusline=%{expand('%:p:h:t')}/%t

syntax on
colorscheme jellybeans

hi VertSplit       ctermbg=256    ctermfg=236
hi SignColumn      ctermbg=256    ctermfg=236
hi ColorColumn     ctermbg=236    ctermfg=236
hi StatusLineNC    ctermbg=236    ctermfg=243
hi StatusLine      ctermbg=236    ctermfg=253
hi Normal          ctermbg=NONE   ctermfg=256
hi LineNr          ctermbg=NONE   ctermfg=253
hi NonText         ctermbg=NONE   ctermfg=256
hi Comment         ctermbg=NONE   ctermfg=gray
hi GitGutterDelete ctermbg=NONE   ctermfg=red
hi GitGutterAdd    ctermbg=NONE   ctermfg=green
hi GitGutterChange ctermbg=NONE   ctermfg=yellow

let mapleader=" "
map <space> <nop>

" misc
nnoremap <silent> <enter> :noh<enter>
nnoremap <silent> <leader>c :tabnew $MYVIMRC<enter>
nnoremap <silent> <leader>so :so $MYVIMRC<enter>
nnoremap <silent> <leader>p "_dP

" tabs
nnoremap <silent> <c-t> :tabnew<enter>
nnoremap <silent> <c-w><C-h> gT
nnoremap <silent> <c-w><C-l> gt

" splits
nnoremap <silent> <c-h> :wincmd h<enter>
nnoremap <silent> <c-j> :wincmd j<enter>
nnoremap <silent> <c-k> :wincmd k<enter>
nnoremap <silent> <c-l> :wincmd l<enter>

" rotate splits
nnoremap <silent> <c-w>s :wincmd L<enter>
nnoremap <silent> <c-w>v :wincmd J<enter>

" resize splits
nnoremap <silent> <up> :resize +2<enter>
nnoremap <silent> <down> :resize -2<enter>
nnoremap <silent> <left> :vertical resize +2<enter>
nnoremap <silent> <right> :vertical resize -2<enter>

" move lines
nnoremap <silent> j gj
nnoremap <silent> k gk
nnoremap <silent> <A-k> :m .-2<enter>==
nnoremap <silent> <A-j> :m .+1<enter>==
vnoremap <silent> <A-k> :m '>+1<enter>gv=gv
vnoremap <silent> <A-j> :m '<-2<enter>gv=gv
inoremap <silent> <A-k> <esc>:m .+1<enter>==gi
inoremap <silent> <A-j> <esc>:m .-2<enter>==gi

" edit file under cursor
nnoremap <silent> gf :edit <cfile><enter>

" pls no
nnoremap <silent> q <nop>
nnoremap <silent> Q <nop>

" delete word backwards
inoremap <C-x> <c-w>
nnoremap <C-x> a<c-w><esc>

" indent
vnoremap <silent> < <gv
vnoremap <silent> > >gv

" quit/save maps
cabbrev W w
cabbrev Q q
cabbrev Wq wq

" format json
command FormatJson :%!jq .

" -- commands
autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Visual', timeout = 200})
autocmd BufWritePre * :%s/\s\+$//e
autocmd InsertLeave * set nopaste
autocmd BufRead *.orig set readonly
autocmd BufRead *.pacnew set readonly

autocmd FileType qf nnoremap <silent> <buffer> q :close<enter>
autocmd FileType qf nnoremap <silent> <buffer> <enter> <enter>:cclose<enter>

autocmd FileType gitcommit setlocal wrap
autocmd FileType gitcommit setlocal spell

autocmd FileType markdown setlocal wrap
autocmd FileType markdown setlocal spell

autocmd Filetype rust set colorcolumn=100
autocmd Filetype rust set tabstop=4 shiftwidth=4
autocmd Filetype rust nnoremap <silent> <leader><enter> :RustRun<enter>

autocmd Filetype go set colorcolumn=100
autocmd Filetype go set tabstop=4 shiftwidth=4
autocmd Filetype go nnoremap <silent> <leader><enter> :GoRun<enter>

autocmd Filetype c set colorcolumn=80
autocmd Filetype c set tabstop=2 shiftwidth=2
autocmd FileType c ClangFormatAutoEnable
autocmd Filetype c nnoremap <silent> <leader><enter> :w <enter> :!g++ % -o %< <enter>
