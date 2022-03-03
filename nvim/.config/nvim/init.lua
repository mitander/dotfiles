local utils = require "core.utils"
local packer = require "plugins.packer"

-- Bootstrap packer (automatic install)
packer.bootstrap()

-- Load impatient
utils.impatient()

-- Disable vim builtin functions
utils.disable_builtins()

-- Core modules
local core_modules = {
  "core.options",
  "core.autocmds",
  "core.mappings",
}

-- Plugin modules
local plugin_modules = {
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
}

-- Load core modules
local core_err = utils.load(core_modules)
if core_err then
  print("Failed to load core modules: " .. core_err)
  return
end

-- Load plugin modules
local plug_err = utils.load(plugin_modules)
if plug_err then
  print("Failed to load plugin modules: " .. plug_err)
  return
end

-- Packer startup
packer.startup()

-- Packer compile
packer.compile()
