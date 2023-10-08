local utils = require "utils"
local nmap = utils.nmap
local vmap = utils.vmap
local nmap_cmd = utils.nmap_cmd

-- just exit pls
vim.cmd [[
    cab W w
    cab Q q
    cab Wq wq
    cab wQ wq
    cab WQ wq
]]

-- better line navigation
nmap { "j", "gj" }
nmap { "k", "gk" }

-- keep visual block on indentation
vmap { "<", "<gv" }
vmap { ">", ">gv" }

-- disable ex-mode
nmap { "q", "<nop>" }

-- don't yank on paste
vmap { "p", "pgvy" }

-- clear highlight
nmap_cmd { "<enter>", "noh" }

-- tab navigation
nmap_cmd { "<s-h>", "tabp" }
nmap_cmd { "<s-l>", "tabn" }
nmap_cmd { "<s-q>", "tabc" }
nmap_cmd { "<c-t>", "tabe" }

-- rotate split layout
nmap_cmd { "<c-w>s", "wincmd L" }
nmap_cmd { "<c-w>v", "wincmd J" }

-- resize splits
nmap_cmd { "<s-up>", "resize -5" }
nmap_cmd { "<s-down>", "resize +5" }
nmap_cmd { "<s-left>", "resize +5" }
nmap_cmd { "<s-right>", "resize -5" }

-- toggle colorcolumn
nmap_cmd { "<leader>.", "execute 'set cc=' . (&colorcolumn == '' ? '100' : '')" }

-- compile
nmap_cmd { "<leader><cr>", "make" }
