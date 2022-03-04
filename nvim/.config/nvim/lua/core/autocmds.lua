local M = {}

vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost init.lua source <afile> | PackerCompile 
  augroup end
]]

vim.cmd [[
  augroup cursor_off
    autocmd!
    autocmd WinLeave * set nocursorline
    autocmd WinEnter * set cursorline
  augroup end
]]

vim.cmd [[
  augroup colorscheme
      autocmd!
      autocmd VimEnter * colorscheme onedark
  augroup end
]]


return M
