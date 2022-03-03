local packer_status_ok, packer = pcall(require, "packer")
if not packer_status_ok then
  return
end

local packer_file = vim.fn.stdpath "config" .. "/lua/packer_compiled.lua"

packer.startup {
  function(use)
    use { "wbthomason/packer.nvim" }
    use { "lewis6991/impatient.nvim" }
    use { "nvim-lua/plenary.nvim" }
    use { "nvim-lua/popup.nvim" }
    use { "moll/vim-bbye" }
    use { "b0o/SchemaStore.nvim" }
    use { "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" }
    use { "hrsh7th/cmp-buffer", after = "nvim-cmp" }
    use { "hrsh7th/cmp-path", after = "nvim-cmp" }
    use { "hrsh7th/cmp-nvim-lsp" }
    use { "kyazdani42/nvim-web-devicons" }
    use { "akinsho/bufferline.nvim", after = "nvim-web-devicons" }
    use { "kyazdani42/nvim-tree.lua", cmd = { "NvimTreeToggle", "NvimTreeFocus" } }
    use { "nvim-lualine/lualine.nvim" }
    use { "hrsh7th/nvim-cmp", event = "BufRead" }
    use { "neovim/nvim-lspconfig", event = "BufRead" }
    use { "tami5/lspsaga.nvim", event = "BufRead" }
    use { "simrat39/symbols-outline.nvim", cmd = "SymbolsOutline" }
    use { "jose-elias-alvarez/null-ls.nvim", event = "BufRead" }
    use { "nvim-telescope/telescope.nvim", cmd = "Telescope" }
    use { "nvim-telescope/telescope-fzf-native.nvim", run = "make" }
    use { "lewis6991/gitsigns.nvim", event = "BufRead" }
    use { "norcalli/nvim-colorizer.lua", event = "BufRead" }
    use { "windwp/nvim-autopairs", event = "InsertEnter" }
    use { "akinsho/nvim-toggleterm.lua", cmd = "ToggleTerm" }
    use { "numToStr/Comment.nvim", event = "BufRead" }
    use { "lukas-reineke/indent-blankline.nvim" }
    use { "folke/which-key.nvim" }

    use {
      "nathom/filetype.nvim",
      config = function()
        vim.g.did_load_filetypes = 1
      end,
    }

    use {
      "antoinemadec/FixCursorHold.nvim",
      event = "BufRead",
      config = function()
        vim.g.cursorhold_updatetime = 100
      end,
    }


    use {
      "nvim-treesitter/nvim-treesitter",
      run = ":TSUpdate",
      event = "BufRead",
      cmd = {
        "TSInstall",
        "TSInstallInfo",
        "TSInstallSync",
        "TSUninstall",
        "TSUpdate",
        "TSUpdateSync",
        "TSDisableAll",
        "TSEnableAll",
      },
      requires = {
        {
          "p00f/nvim-ts-rainbow",
          after = "nvim-treesitter",
        },
        {
          "windwp/nvim-ts-autotag",
          after = "nvim-treesitter",
        },
        {
          "JoosepAlviste/nvim-ts-context-commentstring",
          after = "nvim-treesitter",
        },
      },
    }

    use {
      "L3MON4D3/LuaSnip",
      config = function()
        require "luasnip/loaders/from_vscode".lazy_load()
      end,
      requires = {
        "rafamadriz/friendly-snippets",
      },
    }

    use {
      "williamboman/nvim-lsp-installer",
      event = "BufRead",
      cmd = {
        "LspInstall",
        "LspInstallInfo",
        "LspPrintInstalled",
        "LspRestart",
        "LspStart",
        "LspStop",
        "LspUninstall",
        "LspUninstallAll",
      },
    }


  end,
  config = {
    compile_path = packer_file,
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
  },
}

-- Plugin configs
require("configs.icons").config()
require("configs.bufferline").config()
require("configs.nvim-tree").config()
require("configs.lualine").config()
-- require("configs.treesitter").config()
require("configs.cmp").config()
require("configs.lsp")
require("configs.lsp.lspsaga").config()
require("configs.symbols-outline").setup()
require("configs.null-ls").config()
require("configs.telescope").config()
require("configs.colorizer").config()
require("configs.autopairs").config()
require("configs.toggleterm").config()
require("configs.comment").config()
require("configs.indent-line").config()
require("configs.which-key").config()
require("configs.gitsigns").config()
