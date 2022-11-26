local fn = vim.fn
local packer_compile = fn.stdpath("data") .. "/lua/plugins/packer/packer_compiled.lua"
local packer_install = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

-- Bootstrap packer
if fn.empty(fn.glob(packer_install)) > 0 then
	print("Packer could not be found. Installing..\n")
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		packer_install,
	})
	print("Cloning packer..\n")
	vim.cmd([[packadd packer.nvim]])
	print("Packer installed!\n")
end

local ok, packer = pcall(require, "packer")
if not ok then
	print("error: could not load packer")
end

-- Load compiled packer file
local func, _ = loadfile(packer_compile)
if func then
	func()
end

-- faster load times
local ok, impatient = pcall(require, "impatient")
if ok then
	impatient.enable_profile()
end

-- Use PackerSync when saving this file
vim.cmd([[
      augroup packer_user_config
        autocmd!
        autocmd BufWritePost plugins.lua source <afile> | PackerSync
      augroup end
    ]])

-- Plugins
packer.startup({
	function(use)
		-- Packer manages itself
		use({ "wbthomason/packer.nvim" })

		-- Faster load times
		use({ "lewis6991/impatient.nvim" })

		-- Colorscheme
		use({
			"nanotech/jellybeans.vim",
			config = function()
				vim.cmd([[colorscheme jellybeans]])
				vim.cmd([[ source ~/.config/nvim/lua/colors.lua ]])
			end,
		})

		-- Language plugins
		use({ "fatih/vim-go" })
		use({ "ziglang/zig.vim" })
		use({ "rust-lang/rust.vim" })

		-- Git commands
		use({
			"tpope/vim-fugitive",
			config = function()
				require("keymaps").fugitive()
			end,
		})

		-- Easier commenting
		use({
			"tpope/vim-commentary",
			config = function()
				require("keymaps").commentary()
			end,
		})

		-- Better qf
		use({
			"kevinhwang91/nvim-bqf",
			ft = "qf",
			config = function()
				require("plugins.bqf")
			end,
		})

		-- Show history
		use({
			"mbbill/undotree",
			config = function()
				require("keymaps").undotree()
			end,
		})

		-- Show indentation
		use({
			"lukas-reineke/indent-blankline.nvim",
			config = function()
				require("plugins.indent")
			end,
		})

		-- Use project root as work directory
		use({
			"airblade/vim-rooter",
			config = function()
				vim.g.rooter_targets = "/,*"
				vim.g.rooter_silent_chdir = 1
			end,
		})

		-- Git signcolumn
		use({
			"lewis6991/gitsigns.nvim",
			config = function()
				require("plugins.gitsigns")
				require("keymaps").gitsigns()
			end,
			requires = { "nvim-lua/plenary.nvim" },
		})

		-- File navigatior
		use({
			"kyazdani42/nvim-tree.lua",
			config = function()
				require("plugins.nvim-tree")
				require("keymaps").nvimtree()
			end,
			requires = { "kyazdani42/nvim-web-devicons" },
		})

		-- Lsp configuration
		use({
			"neovim/nvim-lspconfig",
			config = function()
				require("plugins.lsp")
			end,
			requires = {
				{ "nvim-lua/lsp-status.nvim" },
				{ "williamboman/mason.nvim" },
				{ "williamboman/mason-lspconfig.nvim" },
			},
		})

		-- Completions
		use({
			"hrsh7th/nvim-cmp",
			config = function()
				require("plugins.cmp")
			end,
			requires = {
				{ "L3MON4D3/LuaSnip" },
				{ "saadparwaiz1/cmp_luasnip" },
				{ "kyazdani42/nvim-web-devicons" },
				{ "hrsh7th/cmp-nvim-lsp" },
				{ "hrsh7th/cmp-buffer" },
				{ "hrsh7th/cmp-path" },
				{ "hrsh7th/cmp-cmdline" },
			},
		})

		-- Formatting
		use({
			"jose-elias-alvarez/null-ls.nvim",
			config = function()
				require("plugins.null-ls")
			end,
		})

		-- Syntax highlighting
		use({
			"nvim-treesitter/nvim-treesitter",
			run = function()
				local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
				ts_update()
			end,
			requires = { { "nvim-lua/plenary.nvim" } },
			config = function()
				require("plugins.treesitter")
			end,
		})

		-- Tmux interaction
		use({
			"aserowy/tmux.nvim",
			config = function()
				require("plugins.tmux")
			end,
		})

		-- Toggleterm with Lazygit
		use({
			"akinsho/toggleterm.nvim",
			config = function()
				require("plugins.toggleterm")
				require("keymaps").toggleterm()
			end,
		})

		-- Telescope fuzzy previewer
		use({
			"nvim-telescope/telescope.nvim",
			config = function()
				require("plugins.telescope")
				require("keymaps").telescope()
			end,
			requires = {
				{ "kyazdani42/nvim-web-devicons" },
				{ "nvim-lua/plenary.nvim" },
			},
		})

		-- Telescope plugins
		use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })
		use("nvim-telescope/telescope-ui-select.nvim")
		use("nvim-telescope/telescope-file-browser.nvim")

		-- Project management
		use({
			"ahmedkhalf/project.nvim",
			config = function()
				require("plugins.project")
			end,
		})

		if PACKER_BOOTSTRAP then
			require("packer").sync()
		end
	end,

	-- Configuration
	config = {
		compile_path = packer_compile,
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
