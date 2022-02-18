local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer close and reopen Neovim..."
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  }
}

return packer.startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'fatih/vim-go'
  use 'ziglang/zig.vim'
  use 'rust-lang/rust.vim'
  use 'tpope/vim-fugitive'
  use 'SirVer/ultisnips'
  use 'mbbill/undotree'
  use 'airblade/vim-gitgutter'
  use 'nanotech/jellybeans.vim'
  use 'airblade/vim-rooter'
  use 'rhysd/vim-clang-format'
  use 'tpope/vim-commentary'
  use 'kyazdani42/nvim-tree.lua'
  use 'kyazdani42/nvim-web-devicons'
  use 'nvim-lua/plenary.nvim'
  use 'lewis6991/impatient.nvim'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use "neovim/nvim-lspconfig"
  use 'williamboman/nvim-lsp-installer'
  use 'saadparwaiz1/cmp_luasnip'
  use 'jose-elias-alvarez/null-ls.nvim'
  use 'L3MON4D3/LuaSnip'
  use 'junegunn/fzf.vim'
  use {'junegunn/fzf', run = function() vim.fn['fzf#install']() end}
  use {'kevinhwang91/nvim-bqf', ft = 'qf'}
  use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}

  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
