local fn = vim.fn
local packer_compile =  fn.stdpath "data" .. "/lua/plugins/packer/packer_compiled.lua"
local packer_install = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"

-- Automatically install packer
if fn.empty(fn.glob(packer_install)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    packer_install,
  }
  print "Cloning packer...\n"
  vim.cmd [[packadd packer.nvim]]
end

vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost packer.lua source <afile> | PackerSync
  augroup end
]]

local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  }
}

-- Load compiled packer file
local func, _ = loadfile(packer_compile)
if func then
  func()
else
  print "Run :PackerSync to start"
end


packer.startup {
  function(use)
    use 'wbthomason/packer.nvim'
    use 'fatih/vim-go'
    use 'ziglang/zig.vim'
    use 'rust-lang/rust.vim'
    use 'tpope/vim-fugitive'
    use 'SirVer/ultisnips'
    use 'mbbill/undotree'
    use 'lewis6991/gitsigns.nvim'
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
    use 'neovim/nvim-lspconfig'
    use 'nvim-lua/lsp-status.nvim'
    use 'williamboman/nvim-lsp-installer'
    use 'saadparwaiz1/cmp_luasnip'
    use 'jose-elias-alvarez/null-ls.nvim'
    use 'L3MON4D3/LuaSnip'
    use 'junegunn/fzf.vim'
    use 'lukas-reineke/indent-blankline.nvim'
    use 'nathom/filetype.nvim'
    use 'simrat39/symbols-outline.nvim'
    use 'nvim-lua/popup.nvim'
    use 'akinsho/toggleterm.nvim'
    use 'nvim-lualine/lualine.nvim'
    use {'junegunn/fzf', run = function() vim.fn['fzf#install']() end}
    use {'kevinhwang91/nvim-bqf', ft = 'qf'}
    use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}
    use {'akinsho/bufferline.nvim', after = 'nvim-web-devicons'}
    use({"aserowy/tmux.nvim"})

    if PACKER_BOOTSTRAP then
      require("packer").sync()
    end
  end,

  config = {
    compile_path = packer_compile,
    display = {
      open_fn = function()
        return require("packer.util").float { border = "rounded" }
      end,
    },
    profile = {
      enable = true,
      threshold = 0.0001,
    },
    git = {
      clone_timeout = 300,
    },
    auto_clean = true,
    compile_on_sync = true,
  }
}
