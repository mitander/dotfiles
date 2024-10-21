vim.g.mapleader = " "

-- just exit pls
vim.cmd([[
    cab W w
    cab Q q
    cab Wq wq
    cab wQ wq
    cab WQ wq
]])

-- better line navigation
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")

-- keep visual block on indentation
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- disable ex-mode
vim.keymap.set("n", "q", "<nop>")

-- clear highlight
vim.keymap.set("n", "<enter>", vim.cmd.noh)

-- tab navigation
vim.keymap.set("n", "<s-h>", vim.cmd.tabp)
vim.keymap.set("n", "<s-l>", vim.cmd.tabn)
vim.keymap.set("n", "<s-q>", vim.cmd.tabc)
vim.keymap.set("n", "<c-t>", vim.cmd.tabe)

-- compile
vim.keymap.set("n", "<leader><enter>", vim.cmd.make)

-- keep centered
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<c-d>", "<C-d>zz")
vim.keymap.set("n", "<c-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "[d", "cprev<enter>zz")
vim.keymap.set("n", "]d", "cnext<enter>zz")

-- resize splits
vim.keymap.set("n", "<s-up>", "resize -5")
vim.keymap.set("n", "<s-down>", "resize +5")
vim.keymap.set("n", "<s-left>", "resize +5")
vim.keymap.set("n", "<s-right>", "resize -5")

-- toggle colorcolumn
vim.keymap.set("n", "<leader>.", "<cmd>exec 'set cc=' . (&colorcolumn == '' ? '100' : '')<enter>")

-- go, pls..
vim.keymap.set("n", "<leader>e", "oif err != nil {<enter>}<esc>Oreturn err<esc>")

-- replace string
vim.keymap.set("n", "<leader>rs", [[:%s/\<<c-r><c-w>\>/<c-r><c-w>/gI<left><left><left>]])

-- fun
vim.keymap.set("n", "<leader>mr", "<cmd>CellularAutomaton make_it_rain<enter>")

-- reload
vim.keymap.set("n", "<leader>rl", function()
    vim.cmd("so")
end)

-- netrw
vim.keymap.set("n", "<c-n>", "<cmd>Oil<enter>")
