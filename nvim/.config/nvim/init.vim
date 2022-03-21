" lua plugins
lua require("plugins.packer")
lua require("plugins.lsp")
lua require("plugins.cmp")
lua require("plugins.treesitter")
lua require("plugins.nvim-tree")
lua require("plugins.impatient")
lua require("plugins.bqf")
lua require("plugins.filetype")
lua require("plugins.lualine")
lua require("plugins.bufferline")
lua require("plugins.indent")
lua require("plugins.null-ls")
lua require("plugins.toggleterm")

" options
set noswapfile
set nobackup
set nolist
set hlsearch
set incsearch
set hidden
set mouse=a
set number
set ruler
set smartcase
set ignorecase
set noshowmode
set scrolloff=8
set updatetime=50
set shortmess+=c
set background=dark
set smartindent
set expandtab
set linebreak
set autoread
set wildmode=longest:full,full
set wildmenu
set history=1000
set scrolloff=8
set ttimeoutlen=50
set virtualedit=block
set wildignore+=*.o
set switchbuf=useopen,usetab
set splitbelow splitright
set shell=/bin/zsh
set signcolumn=yes
set path+=**
set tabstop=2 shiftwidth=2

" set laststatus=2
" set statusline=%{expand('%:p:h:t')}/%t

" colorscheme
syntax on
colorscheme jellybeans
set termguicolors

" leader
let mapleader=" "
map <space> <nop>

" vim config
nnoremap <silent> <leader>c :tabnew $MYVIMRC<enter>
nnoremap <silent> <leader>so :so $MYVIMRC<enter>

" clear highlighting
nnoremap <silent> <enter> :noh<enter>

" paste without yanking
nnoremap <silent> <leader>p "_dP

" tabs
nnoremap <silent> <c-w><C-h> gT
nnoremap <silent> <c-w><C-l> gt

" buffers
nnoremap <silent> <s-h> :bprev<enter>
nnoremap <silent> <s-l> :bnext<enter>

" splits
nnoremap <silent> <c-h> :wincmd h<enter>
nnoremap <silent> <c-j> :wincmd j<enter>
nnoremap <silent> <c-k> :wincmd k<enter>
nnoremap <silent> <c-l> :wincmd l<enter>

" rotate splits
nnoremap <silent> <c-w>s :wincmd L<enter>
nnoremap <silent> <c-w>v :wincmd J<enter>

" resize splits
nnoremap <silent> <up> :resize -5<enter>
nnoremap <silent> <down> :resize +5<enter>
nnoremap <silent> <left> :vertical resize +5<enter>
nnoremap <silent> <right> :vertical resize -5<enter>

" buffers
nnoremap <silent> Q :bd <enter>
nnoremap <silent> <leader>qa :qall!<enter>

" move lines
nnoremap <silent> j gj
nnoremap <silent> k gk
nnoremap <silent> <A-j> :m .+1<enter>==
nnoremap <silent> <A-k> :m .-2<enter>==
vnoremap <silent> <A-j> :m '>+1<enter>gv=gv
vnoremap <silent> <A-k> :m '<-2<enter>gv=gv
inoremap <silent> <A-j> <esc>:m .+1<enter>==gi
inoremap <silent> <A-k> <esc>:m .-2<enter>==gi

" edit file under cursor
nnoremap <silent> gf :edit <cfile><enter>

" pls no
nnoremap <silent> q <nop>

" delete word backwards
inoremap <C-x> <c-w>
nnoremap <C-x> a<c-w><esc>

" keep visual selection when indenting
vnoremap <silent> < <gv
vnoremap <silent> > >gv

" chmod current file
nnoremap <leader>x :silent !chmod +x %<enter>

" quit/save helpers
cabbrev W w
cabbrev Q q
cabbrev Wq wq

" nvim-tree
nnoremap <silent> <c-n> :NvimTreeToggle<enter>

" fzf
nnoremap <silent> <c-b> :Buffers<enter>
nnoremap <silent> <c-f> :Rg<enter>
nnoremap <silent> <c-p> :CtrlP<enter>
command! CtrlP execute (len(system('git rev-parse'))) ? ':Files' : ':GFiles --cached --others --exclude-standard'

let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%'"
let g:fzf_layout = {'window':{'width':0.8,'height':0.8}}
let g:fzf_action = {'ctrl-t':'tab split','ctrl-s':'split','ctrl-v':'vsplit' }

" commentary
map <silent> <leader>/ :Commentary<enter>

" undotree
if has("persistent_undo")
  set undodir=~/.vim/tmp/undodir
  set undofile
  nnoremap <silent> <leader>u :UndotreeToggle<enter>
endif

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

" toggleterm
nnoremap <silent> gg <cmd>lua _lazygit_toggle()<enter>
nnoremap <silent> <c-t> :ToggleTerm<enter>

" vim-rust
let g:rustfmt_autosave = 1
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 0
let g:rust_clip_command = 'xclip -selection clipboard'

" symbols-outline
nnoremap <silent> <leader>ss :SymbolsOutline<enter>

" highlighting
hi SignColumn          guibg=256  guifg=236
hi ColorColumn         guibg=236  guifg=236
hi StatusLineNC        guibg=236  guifg=243
hi StatusLine          guibg=236  guifg=253
hi Pmenu               guibg=236  guifg=253
hi Normal              guibg=NONE guifg=259
hi LineNr              guibg=NONE guifg=253
hi NonText             guibg=NONE guifg=256
hi Comment             guibg=NONE guifg=gray
hi VertSplit           guibg=NONE guifg=gray
hi GitGutterDelete     guibg=NONE guifg=red
hi GitGutterAdd        guibg=NONE guifg=green
hi GitGutterChange     guibg=NONE guifg=yellow
hi IndentBlanklineChar guibg=NONE guifg=gray

" autocommands
augroup _general
  autocmd!
  autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Visual', timeout = 200})
  autocmd BufWritePre * :%s/\s\+$//e
  autocmd InsertLeave * set nopaste
  autocmd BufRead *.orig set readonly
  autocmd BufRead *.pacnew set readonly
augroup end

augroup _quickfix
  autocmd!
  autocmd FileType qf nnoremap <silent> <buffer> q :close<enter>
  autocmd FileType qf nnoremap <silent> <buffer> <enter> <enter>:cclose<enter>
augroup end

augroup _git
  autocmd!
  autocmd FileType gitcommit setlocal wrap
  autocmd FileType gitcommit setlocal spell
augroup end

augroup _markdown
  autocmd!
  autocmd FileType markdown setlocal wrap
  autocmd FileType markdown setlocal spell
augroup end

augroup _filetype
  autocmd!
  autocmd Filetype rust setlocal colorcolumn=100
  autocmd Filetype rust setlocal tabstop=4 shiftwidth=4

  autocmd Filetype zig setlocal colorcolumn=100
  autocmd Filetype zig setlocal tabstop=4 shiftwidth=4

  autocmd Filetype go setlocal colorcolumn=100
  autocmd Filetype go setlocal tabstop=4 shiftwidth=4

  autocmd Filetype c setlocal colorcolumn=80
  autocmd Filetype c setlocal tabstop=2 shiftwidth=2
  autocmd FileType c ClangFormatAutoEnable
augroup end

command FormatJson :%!jq .
