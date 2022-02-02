"-----Plugged------------------------------------------------------------------
call plug#begin('~/.vim/plugged')
    Plug 'fatih/vim-go'
    Plug 'ziglang/zig.vim'
    Plug 'rust-lang/rust.vim'
    Plug 'junegunn/fzf.vim'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'tpope/vim-fugitive'
    Plug 'SirVer/ultisnips'
    Plug 'mbbill/undotree'
    Plug 'airblade/vim-gitgutter'
    Plug 'nanotech/jellybeans.vim'
    Plug 'airblade/vim-rooter'
    Plug 'rhysd/vim-clang-format'
    Plug 'tpope/vim-commentary'
    Plug 'ahmedkhalf/project.nvim'
    Plug 'Yggdroot/indentLine'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim'
    Plug 'fabi1cazenave/termopen.vim'
call plug#end()

"-----Settings-----------------------------------------------------------------
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
set undodir=~/.vim/tmp/undodir
set undofile
set laststatus=2
set statusline=%{expand('%:p:h:t')}/%t

"-----Mappings-----------------------------------------------------------------
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
nnoremap <silent> <a-j> :m .+1<enter>==
nnoremap <silent> <a-k> :m .-2<enter>==
vnoremap <silent> <a-j> :m '>+1<enter>gv=gv
vnoremap <silent> <a-k> :m '<-2<enter>gv=gv
inoremap <silent> <a-j> <esc>:m .+1<enter>==gi
inoremap <silent> <a-k> <esc>:m .-2<enter>==gi

" edit file under cursor
nnoremap <silent> gf :edit <cfile><enter>

" pls no
nnoremap <silent> Q <nop>
nnoremap <silent> qq <nop>

" delete word backwards
inoremap <C-x> <C-w>

" indent
vnoremap <silent> < <gv
vnoremap <silent> > >gv

" quit/save maps
cabbrev W w
cabbrev Q q
cabbrev Wq wq

"-----Plugins------------------------------------------------------------------
" fzf
nnoremap <silent> <c-f> :Rg<enter>
nnoremap <silent> <c-n> :Lexplore<enter>
nnoremap <silent> <c-p> :Files<enter>
command! CtrlP execute (len(system('git rev-parse'))) ? ':Files' : ':GFiles'

let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%'"
let g:fzf_layout = {'window':{'width':0.8,'height':0.8}}
let g:fzf_action = {'ctrl-t':'tab split','ctrl-s':'split','ctrl-v':'vsplit' }

" ripgrep
if executable('Rg')
    let g:rg_derive_root = 1
endif

" commentary
vnoremap <silent> <leader>/ :Commentary<enter>
nnoremap <silent> <leader>/ :Commentary<enter>

" undotree
nnoremap <silent> <leader>u :UndotreeToggle<enter>

" git-gutter
nnoremap <silent> gp :GitGutterPreviewHunk<enter>
nnoremap <silent> g. :GitGutterToggle<enter>

let g:gitgutter_enabled = 0
let g:gitgutter_sign_added = '|'
let g:gitgutter_sign_modified = '|'
let g:gitgutter_sign_removed = '|'
let g:gitgutter_sign_removed_first_line = '|'
let g:gitgutter_sign_removed_above_and_below = '|'
let g:gitgutter_sign_modified_removed = '|'

" rooter
let g:rooter_targets = '/,*'
let g:rooter_silent_chdir = 1

" fugitive
nnoremap <silent> gs :Git<enter>
nnoremap <silent> gb :Git blame<enter>
nnoremap <silent> gl :Commits<enter>

" vim-rust
let g:rustfmt_autosave = 1
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 0
let g:rust_clip_command = 'xclip -selection clipboard'

" coc
nmap <silent> <c-n> :CocCommand explorer<enter>
nmap <silent> <leader>rn <plug>(coc-rename)
nmap <silent> <leader>a  :<c-u>CocList diagnostics<enter>
nmap <silent> gd <plug>(coc-definition)
nmap <silent> gy <plug>(coc-type-definition)
nmap <silent> gi <plug>(coc-implementation)
nmap <silent> gr <plug>(coc-references)
nmap <silent> g[ <plug>(coc-diagnostic-prev)
nmap <silent> g] <plug>(coc-diagnostic-next)
nmap <silent> K :call <sid>show_documentation()<enter>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

inoremap <silent><expr> <enter>
            \ pumvisible() ? coc#_select_confirm() :
            \ "\<C-g>u\<enter>\<c-r>=coc#on_enter()\<enter>"

let g:coc_global_extensions = [
  \ 'coc-tsserver',
  \ 'coc-pairs',
  \ 'coc-lists',
  \ 'coc-explorer',
  \ 'coc-rust-analyzer',
  \ 'coc-go',
  \ 'coc-zls',
  \ ]

"-----Colors-------------------------------------------------------------------
syntax on
colorscheme jellybeans

hi StatusLineNC    ctermbg=236    ctermfg=243
hi StatusLine      ctermbg=236    ctermfg=253
hi SignColumn      ctermbg=NONE   ctermfg=236
hi ColorColumn     ctermbg=236    ctermfg=236
hi VertSplit       ctermbg=NONE   ctermfg=244
hi LineNr          ctermbg=NONE   ctermfg=NONE
hi Normal          ctermbg=NONE   ctermfg=NONE
hi NonText         ctermbg=NONE   ctermfg=NONE
hi Comment         ctermbg=NONE   ctermfg=gray
hi GitGutterDelete ctermbg=NONE   ctermfg=red
hi GitGutterAdd    ctermbg=NONE   ctermfg=green
hi GitGutterChange ctermbg=NONE   ctermfg=yellow

"-----Commands-----------------------------------------------------------------
autocmd Filetype rust set colorcolumn=100
autocmd Filetype rust set tabstop=4 shiftwidth=4

" autocmd Filetype go set colorcolumn=100
autocmd Filetype go set tabstop=4 shiftwidth=4

autocmd Filetype c set colorcolumn=80
autocmd Filetype c set tabstop=4 shiftwidth=4
autocmd FileType c ClangFormatAutoEnable

autocmd Filetype vim set colorcolumn=80
autocmd CursorHold * silent call CocActionAsync('highlight')

autocmd BufRead *.orig set readonly
autocmd BufRead *.pacnew set readonly

autocmd TextYankPost * silent! lua vim.highlight.on_yank({})
autocmd InsertLeave * set nopaste
autocmd BufWritePre * :%s/\s\+$//e
autocmd FileType list :nnoremap <silent> <buffer>q :q<enter>:q<enter>

echo "~ happy coding ~"
