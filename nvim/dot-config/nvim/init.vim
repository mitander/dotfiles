" Plug
call plug#begin()
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'tpope/vim-fugitive'
Plug 'vim-utils/vim-man'
Plug 'mbbill/undotree'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'morhetz/gruvbox'
Plug 'jiangmiao/auto-pairs'
call plug#end()

" Settings
syntax on
set t_Co=256
set guicursor=
set mouse=a
set relativenumber
set nohlsearch
set hidden
set noerrorbells
set tabstop=2
set shiftwidth=2
set expandtab
set smartindent
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set nowritebackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set scrolloff=8
set updatetime=50
set shortmess+=c
set colorcolumn=80
set background=dark
colorscheme gruvbox
let loaded_matchparen = 1
let g:vrfr_rg = 'true'
let g:netrw_banner = 0
let g:netrw_winsize = 25
let g:netrw_browse_split = 2
set showmatch
set noruler
set noshowmode

" Splits
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit'
  \}

" RG
if executable('Rg')
    let g:rg_derive_root='true'
endif

" Coc extensions
let g:coc_global_extensions = [
    \ 'coc-tsserver',
    \ ]

" Leader (Space)
let mapleader = " "

nnoremap <C-h> :wincmd h<CR>
nnoremap <C-j> :wincmd j<CR>
nnoremap <C-k> :wincmd k<CR>
nnoremap <C-l> :wincmd l<CR>
nnoremap <C-f> :Rg!
nnoremap <C-n> :Files<CR>
nnoremap <C-p> :GFiles<CR>

nnoremap <leader>p :Buffer<CR>
nnoremap <leader>u :UndotreeShow<CR>
nnoremap <leader>rc :so ~/.config/nvim/init.vim<CR>
nnoremap <leader>+ :vertical resize +5<CR>
nnoremap <Leader>- :vertical resize -5<CR>
nnoremap <leader>cr :CocRestart

nmap <silent> K :call <SID>show_documentation()<CR>
nmap <silent>gd <Plug>(coc-definition)
nmap <silent>gy <Plug>(coc-type-definition)
nmap <silent>gi <Plug>(coc-implementation)
nmap <silent>gr <Plug>(coc-references)
nmap <leader>gp <Plug>(coc-diagnostic-prev-error)
nmap <leader>gn <Plug>(coc-diagnostic-next-error)
nmap <leader>rr <Plug>(coc-rename)
nmap <leader>g[ <Plug>(coc-diagnostic-prev)
nmap <leader>g] <Plug>(coc-diagnostic-next)
nmap <leader>g3 :diffget //3<CR>
nmap <leader>g2 :diffget //2<CR>
nmap <leader>gs :G<CR>

" Functions
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

autocmd BufWritePre * :call TrimWhitespace()

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

let g:lightline = {
      \ 'colorscheme': 'gruvbox',
      \ }

if (has("termguicolors"))
  set termguicolors
endif
