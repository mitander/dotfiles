-- bootstrap lazy.nvim!
local path = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(path)

if not vim.uv.fs_stat(path) then
    require("utils").lazy_bootstrap(path)
end

require "options"
require "autocmd"
require "keymaps"
require "plugins"
