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

local status_ok, packer = pcall(require, "packer")
if not status_ok then
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

		-- Go development
		use({ "fatih/vim-go" })

		-- Zig development
		use({ "ziglang/zig.vim" })

		-- Rust development
		use({ "rust-lang/rust.vim" })

		-- async functions
		use({ "nvim-lua/plenary.nvim" })

		-- Popup api
		use({ "nvim-lua/popup.nvim" })

		-- Lsp status api
		use({ "nvim-lua/lsp-status.nvim" })

		-- Manage language servers
		use({ "williamboman/nvim-lsp-installer" })

		-- Snippet engine
		use({ "SirVer/ultisnips" })

		-- Snippet engine for lua
		use({ "L3MON4D3/LuaSnip" })

		-- Icons
		use({ "kyazdani42/nvim-web-devicons" })

		-- Completion lsp
		use({ "hrsh7th/cmp-nvim-lsp" })

		-- Luasnip completion
		use({ "saadparwaiz1/cmp_luasnip" })

		-- Use project root as work directory
		use({
			"airblade/vim-rooter",
			config = function()
				vim.g.rooter_targets = "/,*"
				vim.g.rooter_silent_chdir = 1
			end,
		})

		-- Statusline for buffers
		use({
			"akinsho/bufferline.nvim",
			after = "nvim-web-devicons",
			config = function()
				require("plugins.bufferline")
				require("plugins.mappings").bufferline()
			end,
		})

		-- Easier commenting
		use({
			"tpope/vim-commentary",
			config = function()
				require("plugins.mappings").commentary()
			end,
		})

		-- Git commands
		use({
			"tpope/vim-fugitive",
			config = function()
				require("plugins.mappings").fugitive()
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
		})

		-- Fuzzy previewer
		use({
			"nvim-telescope/telescope.nvim",
			commit = "831f76a809d9f09724d9f3825a3660ed714470d9",
			config = function()
				require("plugins.telescope")
				require("plugins.mappings").telescope()
			end,
		})

		-- Git signcolumn
		use({
			"lewis6991/gitsigns.nvim",
			config = function()
				require("plugins.gitsigns")
				require("plugins.mappings").gitsigns()
			end,
		})

		-- File navigatior
		use({
			"kyazdani42/nvim-tree.lua",
			config = function()
				require("plugins.nvim-tree")
				require("plugins.mappings").nvimtree()
			end,
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

		-- Status line
		use({
			"nvim-lualine/lualine.nvim",
			config = function()
				require("plugins.lualine")
			end,
		})

		-- Nicer quickfix window
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
			end,
		})

		-- Indentation markings
		use({
			"lukas-reineke/indent-blankline.nvim",
			config = function()
				require("plugins.indent")
			end,
		})

		-- If packer was bootstrapped - sync.
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
