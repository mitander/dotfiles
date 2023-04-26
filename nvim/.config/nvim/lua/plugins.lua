-- Plugins
local plugins = {
    "nvim-lua/plenary.nvim",

    -- Colorscheme
    {
        lazy = false,
        "nanotech/jellybeans.vim",
        init = function()
            vim.cmd [[set background=dark]]
            vim.cmd [[colorscheme jellybeans]]
            vim.cmd [[ source ~/.config/nvim/lua/colors.lua ]]
        end,
    },

    -- Language plugins
    { "fatih/vim-go", ft = "go" },
    { "ziglang/zig.vim", ft = "zig" },
    { "rust-lang/rust.vim", ft = "rust" },

    -- Easier commenting
    {
        lazy = false,
        "tpope/vim-commentary",
        init = function()
            require("keymaps").commentary()
        end,
    },

    -- Better qf
    {
        "kevinhwang91/nvim-bqf",
        ft = "qf",
        config = function()
            require "plugins.bqf"
        end,
    },

    -- Show history
    {
        lazy = false,
        "mbbill/undotree",
        config = function()
            require("keymaps").undotree()
        end,
    },

    -- Show indentation
    {
        lazy = false,
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require "plugins.indent"
        end,
    },

    -- Use project root as work directory
    {
        lazy = false,
        "airblade/vim-rooter",
        config = function()
            vim.g.rooter_targets = "/,*"
            vim.g.rooter_silent_chdir = 1
        end,
    },

    -- Git signcolumn
    {
        "lewis6991/gitsigns.nvim",
        ft = "gitcommit",
        init = function()
            -- load gitsigns only when a git file is opened
            vim.api.nvim_create_autocmd({ "BufRead" }, {
                group = vim.api.nvim_create_augroup("GitSignsLazyLoad", { clear = true }),
                callback = function()
                    vim.fn.system("git -C " .. '"' .. vim.fn.expand "%:p:h" .. '"' .. " rev-parse")
                    if vim.v.shell_error == 0 then
                        vim.api.nvim_del_augroup_by_name "GitSignsLazyLoad"
                        vim.schedule(function()
                            require("lazy").load { plugins = { "gitsigns.nvim" } }
                        end)
                    end
                end,
            })
        end,
        config = function()
            require "plugins.gitsigns"
            require("keymaps").gitsigns()
        end,
    },

    -- File navigatior
    {
        "nvim-tree/nvim-tree.lua",
        lazy = false,
        cmd = { "NvimTreeToggle", "NvimTreeFocus" },
        init = function()
            require("keymaps").nvimtree()
        end,
        opts = function()
            return require "plugins.nvim-tree"
        end,
        config = function(_, opts)
            require("nvim-tree").setup(opts)
            vim.g.nvimtree_side = opts.view.side
        end,
    },

    -- Lsp configuration
    {
        "neovim/nvim-lspconfig",
        init = function()
            require("utils").lazy_load "nvim-lspconfig"
        end,
        config = function()
            require "plugins.lsp"
        end,
        dependencies = {
            { "nvim-lua/lsp-status.nvim" },
            { "williamboman/mason.nvim" },
            { "williamboman/mason-lspconfig.nvim" },
        },
    },

    -- Completions
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            {
                "L3MON4D3/LuaSnip",
                dependencies = "rafamadriz/friendly-snippets",
                opts = { history = true, updateevents = "TextChanged,TextChangedI" },
                config = function(_, opts)
                    require("luasnip").config.set_config(opts)
                    require("luasnip.loaders.from_vscode").lazy_load()
                    require("luasnip.loaders.from_vscode").lazy_load { paths = vim.g.vscode_snippets_path or "" }
                    require("luasnip.loaders.from_snipmate").load()
                    require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.g.snipmate_snippets_path or "" }
                    require("luasnip.loaders.from_lua").load()
                    require("luasnip.loaders.from_lua").lazy_load { paths = vim.g.lua_snippets_path or "" }

                    vim.api.nvim_create_autocmd("InsertLeave", {
                        callback = function()
                            if require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
                                and not require("luasnip").session.jump_active
                            then
                                require("luasnip").unlink_current()
                            end
                        end,
                    })
                end,
            },
            {
                "windwp/nvim-autopairs",
                opts = {
                    fast_wrap = {},
                    disable_filetype = { "TelescopePrompt", "vim" },
                },
                config = function(_, opts)
                    require("nvim-autopairs").setup(opts)
                    local cmp_autopairs = require "nvim-autopairs.completion.cmp"
                    require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
                end,
            },
            {
                "saadparwaiz1/cmp_luasnip",
                "hrsh7th/cmp-nvim-lua",
                "hrsh7th/cmp-nvim-lsp",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-path",
            },
        },
        config = function()
            require "plugins.cmp"
        end,
    },

    -- Formatting
    {
        lazy = false,
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
            require "plugins.null-ls"
        end,
    },

    -- Syntax highlighting
    {
        "nvim-treesitter/nvim-treesitter",
        init = function()
            require("utils").lazy_load "nvim-treesitter"
        end,
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        build = ":TSUpdate",
        config = function()
            require "plugins.treesitter"
        end,
    },

    -- Tmux interaction
    {
        lazy = false,
        "aserowy/tmux.nvim",
        config = function()
            require "plugins.tmux"
        end,
    },

    -- Toggleterm with Lazygit
    {
        "akinsho/toggleterm.nvim",
        ft = "gitcommit",
        init = function()
            require("keymaps").toggleterm()
            -- load gitsigns only when a git file is opened
            vim.api.nvim_create_autocmd({ "BufRead" }, {
                group = vim.api.nvim_create_augroup("ToggleTermLazyLoad", { clear = true }),
                callback = function()
                    vim.fn.system("git -C " .. '"' .. vim.fn.expand "%:p:h" .. '"' .. " rev-parse")
                    if vim.v.shell_error == 0 then
                        vim.api.nvim_del_augroup_by_name "ToggleTermLazyLoad"
                        vim.schedule(function()
                            require("utils").lazy_load "toggleterm.nvim"
                            require "plugins.toggleterm"
                        end)
                    end
                end,
            })
        end,
    },

    -- Telescope fuzzy previewer
    {
        "nvim-telescope/telescope.nvim",
        lazy = false,
        cmd = "Telescope",
        init = function()
            require("keymaps").telescope()
        end,
        config = function(_, opts)
            require "plugins.telescope"
        end,
    },

    -- Project management
    {
        lazy = false,
        "ahmedkhalf/project.nvim",
        config = function()
            require "plugins.project"
        end,
    },
}

local opts = {
    defaults = { lazy = true },
    install = { colorscheme = { "nvchad" } },

    ui = {
        icons = {
            ft = "",
            lazy = "鈴 ",
            loaded = "",
            not_loaded = "",
        },
    },

    performance = {
        rtp = {
            disabled_plugins = {
                "2html_plugin",
                "tohtml",
                "getscript",
                "getscriptPlugin",
                "gzip",
                "logipat",
                "netrw",
                "netrwPlugin",
                "netrwSettings",
                "netrwFileHandlers",
                "matchit",
                "tar",
                "tarPlugin",
                "rrhelper",
                "spellfile_plugin",
                "vimball",
                "vimballPlugin",
                "zip",
                "zipPlugin",
                "tutor",
                "rplugin",
                "syntax",
                "synmenu",
                "optwin",
                "compiler",
                "bugreport",
                "ftplugin",
            },
        },
    },
}

require("lazy").setup(plugins, opts)
