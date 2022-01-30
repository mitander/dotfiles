"----[init.vim]----------------------------------------------------------------

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
set laststatus=2
set background=dark
set smartindent
set expandtab
set ww=h,l,<,>,[,]
set linebreak
set autoread
set wildmenu
set wildmode=longest:full,full
set history=1000
set scrolloff=8
set ttimeoutlen=50
set virtualedit=block
set showmatch
set wildignore+=*.o
set switchbuf=useopen,usetab
set splitbelow
set splitright
set shell=/bin/zsh
set statusline=%{expand('%:p:h:t')}/%t
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

"-----Mappings-----------------------------------------------------------------
let mapleader=" "
map <space> <nop>

nnoremap <silent> <CR> :noh<CR>
nnoremap <silent> <leader>c :tabnew $MYVIMRC<CR>
nnoremap <silent> <leader>so :so $MYVIMRC<CR> :echo "[init.vim sourced]"<CR>
nnoremap <silent> <leader>p "_dP

nnoremap <silent> <c-t> :tabnew<CR>
nnoremap <silent> <c-w><c-h> gt
nnoremap <silent> <c-w><c-l> gT

nnoremap <silent> <C-h> :wincmd h<CR>
nnoremap <silent> <C-j> :wincmd j<CR>
nnoremap <silent> <C-k> :wincmd k<CR>
nnoremap <silent> <C-l> :wincmd l<CR>

nnoremap <silent> <Up> :resize +2<CR>
nnoremap <silent> <Down> :resize -2<CR>
nnoremap <silent> <Left> :vertical resize +2<CR>
nnoremap <silent> <Right> :vertical resize -2<CR>

nnoremap <silent> j gj
nnoremap <silent> k gk
nnoremap <silent> <A-j> :m .+1<CR>==
nnoremap <silent> <A-k> :m .-2<CR>==
vnoremap <silent> <A-j> :m '>+1<CR>gv=gv
vnoremap <silent> <A-k> :m '<-2<CR>gv=gv
inoremap <silent> <A-j> <Esc>:m .+1<CR>==gi
inoremap <silent> <A-k> <Esc>:m .-2<CR>==gi
vnoremap <silent> < <gv
vnoremap <silent> > >gv

cab W  w
cab Wq wq
cab Q q

"-----Plugins------------------------------------------------------------------
" ripgrep
nnoremap <silent> <C-f> :Rg<CR>
if executable('Rg')
    let g:rg_derive_root = 1
endif

" fzf
nnoremap <silent> <C-p> :Files<CR>
let g:fzf_layout = { 'window': { 'width': 0.7, 'height': 0.6 } }
let g:fzf_action = {
    \'ctrl-t': 'tab split',
    \'ctrl-s': 'split',
    \'ctrl-v': 'vsplit'}

" commentary
vnoremap <silent> <leader>/ :Commentary<CR>
nnoremap <silent> <leader>/ :Commentary<CR>

" undotree
if has("persistent_undo")
    nnoremap <silent> <leader>u :UndotreeToggle<CR>
    set undodir=~/.vim/tmp/undodir
    set undofile
endif

" git-gutter
nnoremap <silent> gp :GitGutterPreviewHunk<CR>
nnoremap <silent> g. :GitGutterToggle<CR>

let g:gitgutter_enabled = 0
let g:gitgutter_sign_added = '|'
let g:gitgutter_sign_modified = '|'
let g:gitgutter_sign_removed = '|'
let g:gitgutter_sign_removed_first_line = '|'
let g:gitgutter_sign_removed_above_and_below = '|'
let g:gitgutter_sign_modified_removed = '|'

" rooter
let g:rooter_targets = '*'
let g:rooter_silent_chdir = 1

" fugitive
nnoremap <silent> gs :Git<CR>
nnoremap <silent> gb :Git blame<CR>
nnoremap <silent> gl :Commits<CR>

" vim-go
let g:go_play_open_browser = 0
let g:go_fmt_fail_silently = 1
let g:go_fmt_command = "goimports"

" vim-rust
let g:rustfmt_autosave = 1
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 0
let g:rust_clip_command = 'xclip -selection clipboard'

" telescope
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" coc
nmap <silent> <C-n> :CocCommand explorer<CR>
nmap <silent> <leader>rn <Plug>(coc-rename)
nmap <silent> <leader>a  :<C-u>CocList diagnostics<cr>
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> g[ <Plug>(coc-diagnostic-prev)
nmap <silent> g] <Plug>(coc-diagnostic-next)
nmap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

inoremap <silent><expr> <CR>
            \ pumvisible() ? coc#_select_confirm() :
            \ "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

let g:coc_global_extensions = [
  \ 'coc-tsserver',
  \ 'coc-pairs',
  \ 'coc-lists',
  \ 'coc-explorer',
  \ 'coc-rust-analyzer',
  \ 'coc-go',
  \ 'coc-zls',
  \ ]

"-----term-open----------------------------------------------------------------
"
" navigate term split
tnoremap <silent> <C-k> <C-\><C-n>:wincmd k<CR>
tnoremap <silent> <C-j> <C-\><C-n>:wincmd j<CR>
tnoremap <silent> <C-h> <C-\><C-n>:wincmd h<CR>
tnoremap <silent> <C-l> <C-\><C-n>:wincmd l<CR>

" navigate term tab
tnoremap <silent> <C-w><C-h> <C-\><C-n>gT
tnoremap <silent> <C-w><C-l> <C-\><C-n>gt

" navigate term tab
tnoremap <silent> <C-w><C-v> <C-\><C-n>:wincmd L<CR>i
tnoremap <silent> <C-w><C-s> <C-\><C-n>:wincmd J<CR>i
tnoremap <silent> <ESC> <C-\><C-n>

" open terminal split

let $NVIM_LISTEN_ADDRESS='/tmp/nvimsocket'
nnoremap <silent><C-w><CR> :call TermOpen()<CR>
nnoremap <silent><C-w><C-s> :call TermOpen("", "s")<CR>
nnoremap <silent><C-w><C-v> :call TermOpen("", "v")<CR>
nnoremap <silent><C-w><C-t> :call TermOpen("", "t")<CR>
nnoremap <silent><leader>g :call TermOpen("lazygit", "t")<CR>
"-----Colors-------------------------------------------------------------------
syntax on
colorscheme jellybeans

hi StatusLineNC    ctermbg=236    ctermfg=243
hi StatusLine      ctermbg=236    ctermfg=253
hi SignColumn      ctermbg=NONE	  ctermfg=236
hi ColorColumn     ctermbg=236	  ctermfg=236
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

autocmd Filetype go set colorcolumn=100
autocmd Filetype go set tabstop=4 shiftwidth=4

autocmd Filetype c set colorcolumn=80
autocmd Filetype c set tabstop=4 shiftwidth=4
autocmd Filetype vim set colorcolumn=80

autocmd CursorHold * silent call CocActionAsync('highlight')
autocmd FileType c ClangFormatAutoEnable

autocmd BufRead *.orig set readonly
autocmd BufRead *.pacnew set readonly

autocmd TextYankPost * silent! lua vim.highlight.on_yank({})
autocmd InsertLeave * set nopaste
autocmd BufWritePre * :%s/\s\+$//e
autocmd FileType list :nnoremap <silent> <buffer>q :q<CR>:q<CR>
