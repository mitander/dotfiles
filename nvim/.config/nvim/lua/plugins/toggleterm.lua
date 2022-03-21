local status_ok, toggleterm = pcall(require, "toggleterm")
if not status_ok then
  return
end

toggleterm.setup({
  size = 15,
  open_mapping = [[<c-\>]],
  hide_numbers = true,
  shade_filetypes = {},
  shade_terminals = true,
  shading_factor = 2,
  start_in_insert = true,
  insert_mappings = true,
  persist_size = true,
  direction = "horizontal",
  close_on_exit = true,
  shell = vim.o.shell,
  float_opts = {
    border = "curved",
    winblend = 0,
    highlights = {
      border = "Normal",
      background = "Normal",
    },
  },
})

local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new { cmd = "lazygit", hidden = true, direction ="float" }

function _G._lazygit_toggle()
  lazygit:toggle()
end

function _G.terminal_keymaps()
  local opts = {noremap = true}
  vim.api.nvim_buf_set_keymap(0, 't', '<C-j>', [[<C-\><C-n><C-W>j]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<C-k>', [[<C-\><C-n><C-W>k]], opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<up>', '<cmd>resize +5<enter>', opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<down>', '<cmd>resize -5<enter>', opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<left>', '<cmd>vertical resize +5<enter>', opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<right>', '<cmd>vertical resize -5<enter>', opts)
  vim.api.nvim_buf_set_keymap(0, 't', '<c-t>', '<cmd>ToggleTerm <enter>', opts)
end

vim.cmd('autocmd! TermOpen term://*toggleterm#* lua terminal_keymaps()')
