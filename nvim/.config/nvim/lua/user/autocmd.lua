vim.cmd[[
  augroup _general_settings
    autocmd!
    autocmd FileType qf,help,man,lspinfo nnoremap <silent> <buffer> q :close<CR>
    autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Visual', timeout = 200})
    autocmd BufWritePre * :%s/\s\+$//e
  augroup end

  augroup _quickfix
    autocmd!
    autocmd FileType qf set nobuflisted
    autocmd FileType qf nnoremap <CR> <CR>:cclose<CR>
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

  cab W  w
  cab Wq wq
  cab wQ wq
  cab WQ wq
  cab Q  q
]]
