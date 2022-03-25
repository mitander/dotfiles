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
lua require("plugins.gitsigns")
lua require("plugins.tmux")

" options
set noswapfile
set nobackup
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
nnoremap <silent> gp :Gitsigns preview_hunk<enter>
nnoremap <silent> g. :Gitsigns toggle_signs<enter>

" rooter
let g:rooter_targets = '/,*'
let g:rooter_silent_chdir = 1

" fugitive
nnoremap <silent> gs :Git<enter>
nnoremap <silent> gb :Git blame<enter>
nnoremap <silent> gl :Commits<enter>

" toggleterm
nnoremap <silent> <leader>gg <cmd>lua _lazygit_toggle()<enter>
nnoremap <silent> <c-t> :ToggleTerm<enter>

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

autocmd Filetype rust setlocal colorcolumn=100
autocmd Filetype rust setlocal tabstop=4 shiftwidth=4

autocmd Filetype zig setlocal colorcolumn=100
autocmd Filetype zig setlocal tabstop=4 shiftwidth=4

autocmd Filetype go setlocal colorcolumn=100
autocmd Filetype go setlocal tabstop=4 shiftwidth=4

autocmd Filetype c setlocal colorcolumn=80
autocmd Filetype c setlocal tabstop=2 shiftwidth=2
autocmd FileType c ClangFormatAutoEnable
