local fn = vim.fn
local packer_compile = fn.stdpath("data") .. "/lua/plugins/packer/packer_compiled.lua"
local packer_install = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

-- Automatically install packer
if fn.empty(fn.glob(packer_install)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		packer_install,
	})
	print("Cloning packer...\n")
	vim.cmd([[packadd packer.nvim]])
end

vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost packer.lua source <afile> | PackerSync
  augroup end
]])

local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

-- Load compiled packer file
local func, _ = loadfile(packer_compile)
if func then
	func()
else
	print("Run :PackerSync to start")
end

packer.startup({
	function(use)
		use({ "wbthomason/packer.nvim" })
		use({ "nanotech/jellybeans.vim" })
		use({ "fatih/vim-go" })
		use({ "ziglang/zig.vim" })
		use({ "rust-lang/rust.vim" })
		use({ "nvim-lua/plenary.nvim" })
		use({ "nvim-lua/popup.nvim" })
		use({ "nvim-lua/lsp-status.nvim" })
		use({ "williamboman/nvim-lsp-installer" })
		use({ "SirVer/ultisnips" })
		use({ "kyazdani42/nvim-web-devicons" })
		use({ "L3MON4D3/LuaSnip" })
		use({ "hrsh7th/cmp-nvim-lsp" })
		use({ "saadparwaiz1/cmp_luasnip" })
		use({
			"airblade/vim-rooter",
			config = function()
				vim.g.rooter_targets = "/,*"
				vim.g.rooter_silent_chdir = 1
			end,
		})
		use({
			"akinsho/bufferline.nvim",
			after = "nvim-web-devicons",
			config = function()
				require("plugins.bufferline")
				require("plugins.mappings").bufferline()
			end,
		})
		use({
			"tpope/vim-commentary",
			config = function()
				require("plugins.mappings").commentary()
			end,
		})
		use({
			"tpope/vim-fugitive",
			config = function()
				require("plugins.mappings").fugitive()
			end,
		})
		use({
			"mbbill/undotree",
			config = function()
				require("plugins.mappings").undotree()
			end,
		})
		use({
			"simrat39/symbols-outline.nvim",
			config = function()
				require("plugins.symbols-outline")
				require("plugins.mappings").symbolsoutline()
			end,
		})
		use({
			"nvim-telescope/telescope.nvim",
			config = function()
				require("plugins.telescope")
				require("plugins.mappings").telescope()
			end,
		})
		use({
			"lewis6991/gitsigns.nvim",
			config = function()
				require("plugins.gitsigns")
				require("plugins.mappings").gitsigns()
			end,
		})
		use({
			"kyazdani42/nvim-tree.lua",
			config = function()
				require("plugins.nvim-tree")
				require("plugins.mappings").nvimtree()
			end,
		})
		use({
			"akinsho/toggleterm.nvim",
			config = function()
				require("plugins.toggleterm")
				require("plugins.mappings").toggleterm()
			end,
		})
		use({
			"neovim/nvim-lspconfig",
			config = function()
				require("plugins.lsp")
			end,
		})
		use({
			"ahmedkhalf/project.nvim",
			config = function()
				require("plugins.project")
			end,
		})
		use({
			"lewis6991/impatient.nvim",
			config = function()
				require("plugins.impatient")
			end,
		})
		use({
			"hrsh7th/nvim-cmp",
			config = function()
				require("plugins.cmp")
			end,
		})
		use({
			"jose-elias-alvarez/null-ls.nvim",
			config = function()
				require("plugins.null-ls")
			end,
		})
		use({
			"nathom/filetype.nvim",
			config = function()
				require("plugins.filetype")
			end,
		})
		use({
			"nvim-lualine/lualine.nvim",
			config = function()
				require("plugins.lualine")
			end,
		})
		use({
			"kevinhwang91/nvim-bqf",
			config = function()
				require("plugins.bqf")
			end,
		})
		use({
			"nvim-treesitter/nvim-treesitter",
			run = ":TSUpdate",
			config = function()
				require("plugins.treesitter")
			end,
		})
		use({
			"aserowy/tmux.nvim",
			config = function()
				require("plugins.tmux")
			end,
		})
		use({
			"lukas-reineke/indent-blankline.nvim",
			config = function()
				require("plugins.indent")
			end,
		})
		if PACKER_BOOTSTRAP then
			require("packer").sync()
		end
	end,

	config = {
		compile_path = packer_compile,
		display = {
			open_fn = function()
				return require("packer.util").float({ border = "rounded" })
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
})
