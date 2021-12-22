vim.cmd [[
try
  colorscheme jellybeans
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme default
  set background=dark
endtry

hi GitSignsChange ctermbg=NONE   ctermfg=yellow
hi StatusLineNC   ctermbg=236    ctermfg=243
hi StatusLine     ctermbg=236    ctermfg=253
hi SignColumn     ctermbg=NONE	 ctermfg=236
hi VertSplit      ctermbg=NONE   ctermfg=236
hi LineNr         ctermbg=NONE   ctermfg=NONE
hi Normal         ctermbg=NONE   ctermfg=NONE
hi NonText        ctermbg=NONE   ctermfg=NONE
hi Comment        ctermbg=NONE   ctermfg=gray
]]
