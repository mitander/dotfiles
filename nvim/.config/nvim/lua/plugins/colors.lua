local M = {
  black = '#3b3b3b',
  red = '#cf6a4c',
  green = '#99ad6a',
  yellow = '#d8ad4c',
  blue = '#8197bf',
  magenta = '#a037b0',
  cyan = '#71b9f8',
  white = '#e8e8de',
  gray = '#30302c',
  gray2 = '#b0b0b0',
  none = 'NONE'
}

vim.cmd[[ syntax on ]]
vim.cmd[[ colorscheme jellybeans ]]
vim.cmd[[ set termguicolors ]]

function M.hl(group, bg, fg)
  vim.cmd("au ColorScheme * hi " .. group .. " guibg=" .. bg .. " guifg=" .. fg .. " ")
end

-- General vim highlights
M.hl("Pmenu", M.none, M.white)
M.hl("Normal", M.none, M.white)
M.hl("LineNr", M.none, M.white)
M.hl("NonText", M.none, M.white)
M.hl("Comment", M.none, M.gray2)
M.hl("VertSplit", M.none, M.gray)
M.hl("SignColumn", M.none, M.none)
M.hl("ColorColumn",M.white, M.white)
M.hl("StatusLineNC", M.none, M.none)
M.hl("StatusLine", M.none, M.none)

return M
