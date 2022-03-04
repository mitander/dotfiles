local M = {}

vim.cmd "hi clear"
if vim.fn.exists "syntax_on" then
  vim.cmd "syntax reset"
end

vim.o.background = "dark"
vim.o.termguicolors = true


function M.load_colors(c)
  C = c
  local util = require "theme.util"
  local base = require "theme.base"
  local others = require "theme.others"

  local theme = {
    base,
    others,
  }

  for _, file in ipairs(theme) do
    for group, colors in pairs(file) do
      util.highlight(group, colors)
    end
  end
end

return M
