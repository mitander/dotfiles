call plug#begin()
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  Plug 'mbbill/undotree'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'morhetz/gruvbox'
  Plug 'tpope/vim-fugitive'
  Plug 'fatih/vim-go'
call plug#end()

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
set statusline=%t
set background=dark

"set colorcolumn=80

syntax on
colorscheme gruvbox

" colors
hi Comment ctermfg=green
hi StatusLine ctermbg=223 ctermfg=239
hi StatusLineNC ctermbg=223 ctermfg=237
hi VertSplit ctermbg=235 ctermfg=240

" binds
let mapleader = " "
nnoremap <silent> <C-h> :wincmd h<CR>
nnoremap <silent> <C-j> :wincmd j<CR>
nnoremap <silent> <C-k> :wincmd k<CR>
nnoremap <silent> <C-l> :wincmd l<CR>
nnoremap <silent> <C-f> :Rg!<CR>
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <C-n> :Buffer<CR>
nnoremap <silent> <leader>u :UndotreeShow<CR>
nnoremap <silent> <leader>/ :noh<CR>
nnoremap <silent> <leader>. :CocDisable<CR>
nnoremap <silent> <leader> p "_dP

" coc binds
nmap <silent> K :call <SID>show_documentation()<CR>
nmap <silent>gd <Plug>(coc-definition)
nmap <silent>gy <Plug>(coc-type-definition)
nmap <silent>gi <Plug>(coc-implementation)
nmap <silent>gr <Plug>(coc-references)
nmap <leader>gp <Plug>(coc-diagnostic-prev-error)
nmap <leader>gn <Plug>(coc-diagnostic-next-error)
nmap <leader>rr <Plug>(coc-rename)
" go specific
nmap <F1> :GoRun<CR>
nmap <F2> :GoTest<CR>
nmap <F3> :!go test<CR>
nmap <silent>cr coc#refresh

" removes whitespace on save
autocmd BufWritePre * :call TrimWhitespace()
fun! TrimWhitespace()
    let l:save = winsaveview()
    keeppatterns %s/\s\+$//e
    call winrestview(l:save)
endfun

" coc show documentation (hover function and press K)
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" new splits from fzf
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-s': 'split',
  \ 'ctrl-v': 'vsplit'
  \}

if executable('Rg')
    let g:rg_derive_root='true'
endif

