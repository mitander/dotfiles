local nmap_cmd = require("utils").nmap_cmd

local plugins = {
    "nvim-lua/plenary.nvim",

    -- Colorscheme
    {
        "rebelot/kanagawa.nvim",
        init = function()
            require("utils").lazy_load "kanagawa.nvim"
            require("kanagawa").load "wave"
            vim.cmd [[set background=dark]]
            vim.cmd [[hi CursorLine guibg=#2a2a37]]
            vim.cmd [[hi CursorLineNr guifg=#E6C384]]
            vim.cmd [[hi StatusLine guibg=#363646]]
            vim.cmd [[hi StatusLineNC guibg=#363646]]
            vim.cmd [[hi LineNr guifg=NONE]]
            vim.cmd [[hi Todo guifg=#E6C384 guibg=#1F1F28]]
            vim.cmd [[hi IblIndent guifg=#35353d guibg=NONE]]
        end,
    },

    -- Language plugins
    { "fatih/vim-go",       ft = "go" },
    { "ziglang/zig.vim",    ft = "zig" },
    { "rust-lang/rust.vim", ft = "rust" },

    -- Notes & task management
    {
        lazy = false,
        "nvim-neorg/neorg",
        build = ":Neorg sync-parsers",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("neorg").setup {
                load = {
                    ["core.defaults"] = {},
                    ["core.concealer"] = {},
                    ["core.dirman"] = {
                        config = {
                            workspaces = {
                                notes = "~/notes",
                            },
                            default_workspace = "notes",
                        },
                    },
                },
            }

            vim.wo.foldlevel = 99
            vim.wo.conceallevel = 2
        end,
    },

    -- Better yanks
    {
        lazy = false,
        "ibhagwan/smartyank.nvim",
        init = function()
            require("smartyank").setup {
                highlight = {
                    timeout = 200,
                },
            }
        end,
    },
    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        init = function()
            require("utils").lazy_load "lualine.nvim"
        end,
        config = function()
            require "plugins.lualine"
        end,
    },

    -- Easier commenting
    {
        lazy = false,
        "tpope/vim-commentary",
        init = function()
            vim.cmd [[map <silent> <leader>/ :Commentary<enter>]]
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
            nmap_cmd { "<leader>u", "UndotreeToggle" }
        end,
    },

    -- Show indentation
    {
        lazy = false,
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        config = function()
            require "plugins.indent"
        end,
    },

    -- Git signcolumn
    {
        "lewis6991/gitsigns.nvim",
        init = function()
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
        end,
    },

    -- File navigatior
    {
        "kyazdani42/nvim-tree.lua",
        lazy = false,
        config = function()
            require "plugins.nvim-tree"
        end,
        dependencies = "kyazdani42/nvim-web-devicons",
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
            { "williamboman/mason-lspconfig.nvim" },
            {
                "williamboman/mason.nvim",
                config = function()
                    require "plugins.mason"
                end,
            },
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
                            if
                                require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
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
        "jose-elias-alvarez/null-ls.nvim",
        init = function()
            require("utils").lazy_load "null-ls.nvim"
        end,
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

    -- Lazygit
    {
        lazy = false,
        "kdheepak/lazygit.nvim",
        init = function()
            vim.api.nvim_create_autocmd({ "BufRead" }, {
                group = vim.api.nvim_create_augroup("LazyGitLazyLoad", { clear = true }),
                callback = function()
                    vim.fn.system("git -C " .. '"' .. vim.fn.expand "%:p:h" .. '"' .. " rev-parse")
                    if vim.v.shell_error == 0 then
                        vim.api.nvim_del_augroup_by_name "LazyGitLazyLoad"
                        vim.schedule(function()
                            require("utils").lazy_load "lazygit.nvim"
                        end)
                    end
                end,
            })
        end,
        config = function()
            nmap_cmd { "<leader>gg", "LazyGit" }
            vim.cmd [[hi LazyGitBorder guifg=#363646]]
            vim.cmd [[hi LazyGitFloat guifg=#dcd7ba]]
        end,
    },

    {
        "ibhagwan/fzf-lua",
        lazy = false,
        config = function()
            vim.cmd [[hi FzfLuaBorder guifg=#363646]]
            vim.cmd [[hi FzfLuaTitle guifg=#dcd7ba]]
            require "plugins.fzf"
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

    {
        "mfussenegger/nvim-dap",
        dependencies = "rcarriga/nvim-dap-ui",
        init = function()
            require "plugins.dap"
        end,
    },
}

local opts = {
    defaults = { lazy = true },

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
