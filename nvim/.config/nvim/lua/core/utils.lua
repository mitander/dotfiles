local M = {}

function M.load(modules)
  for _, m in ipairs(modules) do
    local ok, err = pcall(require, m)
    if not ok then
      return error("Failed to load module: " .. m .. "\n\n Error: " .. err)
    end
  end
end

function M.disable_builtins()
  vim.g.loaded_gzip = false
  vim.g.loaded_netrwPlugin = false
  vim.g.loaded_netrwSettngs = false
  vim.g.loaded_netrwFileHandlers = false
  vim.g.loaded_2html_plugin = false
  vim.g.loaded_remote_plugins = false
  vim.g.loaded_tar = false
  vim.g.loaded_tarPlugin = false
  vim.g.zipPlugin = false
  vim.g.loaded_zipPlugin = false
end

function M.list_lsp_sources(filetype)
  local s = require "null-ls.sources"
  local available_sources = s.get_available(filetype)
  local registered = {}
  for _, source in ipairs(available_sources) do
    for method in pairs(source.methods) do
      registered[method] = registered[method] or {}
      table.insert(registered[method], source.name)
    end
  end
  return registered
end

function M.list_formatters(filetype)
  local null_ls_methods = require "null-ls.methods"
  local formatter_method = null_ls_methods.internal["FORMATTING"]
  local registered_providers = M.list_lsp_sources(filetype)
  return registered_providers[formatter_method] or {}
end

function M.list_linters(filetype)
  local null_ls_methods = require "null-ls.methods"
  local formatter_method = null_ls_methods.internal["DIAGNOSTICS"]
  local registered_providers = M.list_lsp_sources(filetype)
  return registered_providers[formatter_method] or {}
end

function M.impatient()
  local impatient_ok, _ = pcall(require, "impatient")
  if impatient_ok then
    require("impatient").enable_profile()
  end
end

return M
