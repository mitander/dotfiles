" plugins
call plug#begin()
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'tpope/vim-fugitive'
  Plug 'fatih/vim-go'
  Plug 'SirVer/ultisnips'
  Plug 'mbbill/undotree'
  Plug 'nanotech/jellybeans.vim'
  Plug 'ziglang/zig.vim'
  Plug 'airblade/vim-gitgutter'
  Plug 'kevinhwang91/nvim-bqf'
  Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
call plug#end()

" settings
set mouse=a
set number
set ruler
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set smartcase
set ignorecase
set noswapfile
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

" coc colors
hi CocErrorFloat ctermfg=red
hi CocWarningSign ctermfg=red
hi CocHintFloat ctermfg=red

" vim colors
hi StatusLineNC ctermbg=236 ctermfg=243
hi StatusLine ctermbg=236 ctermfg=253
hi SignColumn ctermbg=NONE
hi NonText ctermbg=NONE
hi Normal ctermbg=NONE
hi Normal ctermbg=NONE
hi LineNr ctermbg=NONE ctermfg=NONE

" binds
let mapleader = " "
nnoremap <silent> <C-h> :wincmd h<CR>
nnoremap <silent> <C-j> :wincmd j<CR>
nnoremap <silent> <C-k> :wincmd k<CR>
nnoremap <silent> <C-l> :wincmd l<CR>
nnoremap <silent> <C-f> :Rg<CR>
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <C-b> :Buffer<CR>
nnoremap <silent> <leader>u :UndotreeShow<CR>
nnoremap <silent> <leader>/ :noh<CR>
nnoremap <silent> <leader>. :CocDisable<CR>
nnoremap <silent> <leader> p "_dP
nnoremap <silent> <C-n> :CocCommand explorer<CR>
nnoremap <silent> gb :Git blame<CR>

" coc binds
nmap <silent>K :call <SID>show_documentation()<CR>
nmap <silent>gd <Plug>(coc-definition)
nmap <silent>gy <Plug>(coc-type-definition)
nmap <silent>gi <Plug>(coc-implementation)
nmap <silent>gr <Plug>(coc-references)
nmap <leader>gp <Plug>(coc-diagnostic-prev-error)
nmap <leader>gn <Plug>(coc-diagnostic-next-error)
nmap <leader>rr <Plug>(coc-rename)

" move line
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi


" vim-go
nmap <F1> :GoRun main.go
nmap <F2> :GoTest<CR>
nmap <F3> :!go test ./...
nmap <F3> :GoTestFunc<CR>

" trim whitespace on save
autocmd BufWritePre * :call TrimWhitespace()
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

" show documentation (hover function + K)
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" fzf settings
let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --preview 'batcat --color=always --style=header,grid --line-range :300 {}'"
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.9 } }
let g:fzf_action = { 'ctrl-t': 'tab split', 'ctrl-s': 'split', 'ctrl-v': 'vsplit' }

" rg derives from project root
if executable('Rg')
    let g:rg_derive_root = 1
endif

" append (), {}, [] behind coc-menu selection
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
