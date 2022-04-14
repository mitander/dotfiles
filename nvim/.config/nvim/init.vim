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
set tabstop=4 shiftwidth=4

" colorscheme
syntax on
colorscheme jellybeans
set termguicolors

" leader
let mapleader=" "
map <space> <nop>

" vim config
nnoremap <silent> <leader>c :tabnew $HOME/dotfiles/nvim/.config/nvim/init.vim<enter>
nnoremap <silent> <leader>so :so $HOME/dotfiles/nvim/.config/nvim/init.vim<enter>

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
nnoremap <silent> <s-q> :bd <enter>
nnoremap <silent> <leader>qa :qall!<enter>

" rotate splits
nnoremap <silent> <c-w>s :wincmd L<enter>
nnoremap <silent> <c-w>v :wincmd J<enter>

" resize splits
nnoremap <silent> <s-up> :resize -5<enter>
nnoremap <silent> <s-down> :resize +5<enter>
nnoremap <silent> <s-left> :vertical resize +5<enter>
nnoremap <silent> <s-right> :vertical resize -5<enter>

" move lines
nnoremap <silent> j gj
nnoremap <silent> k gk

" edit file under cursor
nnoremap <silent> gf :edit <cfile><enter>

" pls no
nnoremap <silent> q <nop>
nnoremap <silent> <leader>q <nop>

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

" telescope
nnoremap <silent> <c-p> :CtrlP<enter>
nnoremap <silent> <C-f> <cmd>Telescope live_grep<enter>
nnoremap <silent> <C-b> <cmd>Telescope buffers<enter>
nnoremap <silent> <leader>gs <cmd>Telescope git_status<enter>
nnoremap <silent> <leader>gl <cmd>Telescope git_commits<enter>

command! CtrlP execute (len(system('git rev-parse'))) ? ':Telescope find_files' : ':Telescope git_files'

" commentary
map <silent> <leader>/ :Commentary<enter>

" undotree
if has("persistent_undo")
    set undodir=~/.vim/tmp/undodir
    set undofile
    nnoremap <silent> <leader>u :UndotreeToggle<enter>
endif

" gitsigns
nnoremap <silent> gp :Gitsigns preview_hunk<enter>
nnoremap <silent> g. :Gitsigns toggle_signs<enter>
nnoremap <silent> gl :Gitsigns blame_line<enter>

" rooter
let g:rooter_targets = '/,*'
let g:rooter_silent_chdir = 1

" fugitive
nnoremap <silent> gb :Git blame<enter>

" toggleterm (lazygit)
nnoremap <silent> <leader>gg <cmd>lua _lazygit_toggle()<enter>

" vim-rust
let g:rustfmt_autosave = 1
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 0
let g:rust_clip_command = 'xclip -selection clipboard'

" format json
if executable("jq")
    nnoremap <silent> <leader>fj :%!jq .<enter>
endif

" symbols-outline
nnoremap <silent> <leader>ss :SymbolsOutline<enter>

" autocommands
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

autocmd Filetype rust,zig,go,c,cpp setlocal colorcolumn=100
autocmd Filetype rust,zig,go,c,cpp setlocal tabstop=4 shiftwidth=4
