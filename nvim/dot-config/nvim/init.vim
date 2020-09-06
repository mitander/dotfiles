call plug#begin()
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'mbbill/undotree'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'morhetz/gruvbox'
call plug#end()

if (has("termguicolors"))
  set termguicolors
endif

syntax on
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
set colorcolumn=80
set laststatus=2
set statusline=%t
set background=dark
colorscheme gruvbox

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
nnoremap <leader>cr :CocRestart<CR>
nnoremap <leader>/ :noh<CR>

nmap <silent> K :call <SID>show_documentation()<CR>
nmap <silent>gd <Plug>(coc-definition)
nmap <silent>gy <Plug>(coc-type-definition)
nmap <silent>gi <Plug>(coc-implementation)
nmap <silent>gr <Plug>(coc-references)
nmap <leader>gp <Plug>(coc-diagnostic-prev-error)
nmap <leader>gn <Plug>(coc-diagnostic-next-error)
nmap <leader>rr <Plug>(coc-rename)

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

let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit'
  \}

if executable('Rg')
    let g:rg_derive_root='true'
endif
