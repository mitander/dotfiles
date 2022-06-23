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
	return
end

-- Open float when installing
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

-- Use PackerSync when saving this file
vim.cmd([[
      augroup packer_user_config
        autocmd!
        autocmd BufWritePost packer.lua source <afile> | PackerSync
      augroup end
    ]])

-- Plugins
packer.startup({
	function(use)
		-- Packer manages itself
		use({ "wbthomason/packer.nvim" })

		-- Colorscheme
		use({ "nanotech/jellybeans.vim" })

		-- Language plugins
		use({ "fatih/vim-go" })
		use({ "ziglang/zig.vim" })
		use({ "rust-lang/rust.vim" })

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

		-- Git commands
		use({
			"tpope/vim-fugitive",
			config = function()
				require("plugins.mappings").fugitive()
			end,
		})

		-- Easier commenting
		use({
			"tpope/vim-commentary",
			config = function()
				require("plugins.mappings").commentary()
			end,
		})

		-- Show history
		use({
			"mbbill/undotree",
			config = function()
				require("plugins.mappings").undotree()
			end,
		})

		-- Overview of file symbols
		use({
			"simrat39/symbols-outline.nvim",
			config = function()
				require("plugins.symbols-outline")
				require("plugins.mappings").symbolsoutline()
			end,
			requires = { "kyazdani42/nvim-web-devicons" },
		})

		-- Fuzzy previewer
		use({
			"nvim-telescope/telescope.nvim",
			config = function()
				require("plugins.telescope")
				require("plugins.mappings").telescope()
			end,
			requires = {
				{ "kyazdani42/nvim-web-devicons" },
				{ "nvim-lua/plenary.nvim" },
			},
		})

		-- Telescope fzf
		use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })

		-- Git signcolumn
		use({
			"lewis6991/gitsigns.nvim",
			config = function()
				require("plugins.gitsigns")
				require("plugins.mappings").gitsigns()
			end,
			requires = { "nvim-lua/plenary.nvim" },
		})

		-- File navigatior
		use({
			"kyazdani42/nvim-tree.lua",
			config = function()
				require("plugins.nvim-tree")
				require("plugins.mappings").nvimtree()
			end,
			requires = { "kyazdani42/nvim-web-devicons" },
		})

		-- Toggleterm with Lazygit
		use({
			"akinsho/toggleterm.nvim",
			config = function()
				require("plugins.toggleterm")
				require("plugins.mappings").toggleterm()
			end,
		})

		-- Lsp configuration
		use({
			"neovim/nvim-lspconfig",
			config = function()
				require("plugins.lsp")
			end,
			requires = {
				{ "nvim-lua/lsp-status.nvim" },
				{ "williamboman/nvim-lsp-installer" },
			},
		})

		-- Project management
		use({
			"ahmedkhalf/project.nvim",
			config = function()
				require("plugins.project")
			end,
		})

		-- Faster load times
		use({
			"lewis6991/impatient.nvim",
			config = function()
				require("plugins.impatient")
			end,
		})

		-- Completions
		use({
			"hrsh7th/nvim-cmp",
			config = function()
				require("plugins.cmp")
			end,
			requires = {
				{ "SirVer/ultisnips" },
				{ "L3MON4D3/LuaSnip" },
				{ "hrsh7th/cmp-nvim-lsp" },
				{ "saadparwaiz1/cmp_luasnip" },
				{ "kyazdani42/nvim-web-devicons" },
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

		-- Better filetypes
		use({
			"nathom/filetype.nvim",
			config = function()
				require("plugins.filetype")
			end,
		})

		-- Statusline
		use({
			"nvim-lualine/lualine.nvim",
			config = function()
				require("plugins.lualine")
			end,
			requires = { "kyazdani42/nvim-web-devicons" },
		})

		-- Better quickfix window
		use({
			"kevinhwang91/nvim-bqf",
			config = function()
				require("plugins.bqf")
			end,
		})

		-- Syntax highlighting
		use({
			"nvim-treesitter/nvim-treesitter",
			run = ":TSUpdate",
			config = function()
				require("plugins.treesitter")
			end,
		})

		-- Tmux interaction
		use({
			"aserowy/tmux.nvim",
			config = function()
				require("plugins.tmux")
				require("plugins.mappings").tmux()
			end,
		})

		if PACKER_BOOTSTRAP then
			require("packer").sync()
		end
	end,

	-- Configuration
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
