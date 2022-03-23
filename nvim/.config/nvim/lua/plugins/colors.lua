local M = {
  red = '#cf6a4c',
  green = '#99ad6a',
  yellow = '#d8ad4c',
  magneta = '#8197bf',
  cyan = '#71b9f8',
  white = '#e8e8de',
  gray = '#3b3b3b',
  dark_gray = '#30302c',
  light_gray = '#b0b0b0',
  none = 'NONE'
}

function M.highlight(group, bg, fg)
  vim.cmd("au ColorScheme * hi " .. group .. " guibg=" .. bg .. " guifg=" .. fg .. " ")
end

-- General vim highlights
M.highlight("Pmenu", M.none, M.white)
M.highlight("Normal", M.none, M.white)
M.highlight("LineNr", M.none, M.white)
M.highlight("NonText", M.none, M.white)
M.highlight("VertSplit", M.none, M.gray)
M.highlight("SignColumn", M.none, M.none)
M.highlight("ColorColumn",M.gray, M.gray)
M.highlight("StatusLine", M.none, M.none)
M.highlight("StatusLineNC", M.none, M.none)
M.highlight("Comment", M.none, M.light_gray)

return M
