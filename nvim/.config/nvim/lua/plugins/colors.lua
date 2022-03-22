vim.cmd[[syntax on]]
vim.cmd[[colorscheme jellybeans]]
vim.cmd[[set termguicolors]]

local M = {
  black = '#3b3b3b',
  red = '#cf6a4c',
  green = '#99ad6a',
  yellow = '#d8ad4c',
  magneta = '#8197bf',
  cyan = '#71b9f8',
  white = '#e8e8de',
  gray = '#30302c',
  dark_gray = '#1d1e1f',
  light_gray = '#b0b0b0',
  none = 'NONE'
}

function M.hl(group, bg, fg)
  vim.cmd("au ColorScheme * hi " .. group .. " guibg=" .. bg .. " guifg=" .. fg .. " ")
end

-- General vim highlights
M.hl("Pmenu", M.none, M.white)
M.hl("Normal", M.none, M.white)
M.hl("LineNr", M.none, M.white)
M.hl("NonText", M.none, M.white)
M.hl("VertSplit", M.none, M.gray)
M.hl("SignColumn", M.none, M.none)
M.hl("ColorColumn",M.white, M.white)
M.hl("StatusLine", M.none, M.none)
M.hl("StatusLineNC", M.none, M.none)
M.hl("Comment", M.none, M.light_gray)

return M
