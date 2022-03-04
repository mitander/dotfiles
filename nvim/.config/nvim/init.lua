local utils = require "core.utils"
local packer = require "plugins.packer"

-- Start packer
packer.startup()

-- Load impatient
utils.load_impatient()

-- Disable vim builtin functions
utils.disable_builtins()

-- Load modules
local modules = {
  "core.options",
  "core.autocmds",
  "core.mappings",
  "plugins.icons",
  "plugins.bufferline",
  "plugins.nvim-tree",
  "plugins.lualine",
  "plugins.treesitter",
  "plugins.cmp",
  "plugins.lsp",
  "plugins.lsp.lspsaga",
  "plugins.symbols-outline",
  "plugins.null-ls",
  "plugins.telescope",
  "plugins.colorizer",
  "plugins.autopairs",
  "plugins.toggleterm",
  "plugins.comment",
  "plugins.indent-line",
  "plugins.which-key",
  "plugins.gitsigns",
  "plugins.mappings",
}
utils.load(modules)

packer.compile()
