" bootstrap
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  echo "hello"
  silent !curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs 
  \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" plugins
call plug#begin('~/.vim/bundle')
  Plug 'wbthomason/packer.nvim'
  Plug 'fatih/vim-go'
  Plug 'ziglang/zig.vim'
  Plug 'rust-lang/rust.vim'
  Plug 'tpope/vim-fugitive'
  Plug 'SirVer/ultisnips'
  Plug 'mbbill/undotree'
  Plug 'airblade/vim-gitgutter'
  Plug 'nanotech/jellybeans.vim'
  Plug 'airblade/vim-rooter'
  Plug 'rhysd/vim-clang-format'
  Plug 'tpope/vim-commentary'
  Plug 'kyazdani42/nvim-tree.lua'
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'lewis6991/impatient.nvim'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'neovim/nvim-lspconfig'
  Plug 'williamboman/nvim-lsp-installer'
  Plug 'saadparwaiz1/cmp_luasnip'
  Plug 'L3MON4D3/LuaSnip'
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
  Plug 'nathom/filetype.nvim'
  Plug 'nvim-lua/lsp-status.nvim'
  Plug 'kevinhwang91/nvim-bqf'
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
call plug#end()

" fzf
nnoremap <silent> <c-f> :Rg<enter>
nnoremap <silent> <c-p> :CtrlP<enter>
command! CtrlP execute (len(system('git rev-parse'))) ? ':Files' : ':GFiles --cached --others --exclude-standard'

let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%'"
let g:fzf_layout = {'window':{'width':0.8,'height':0.8}}
let g:fzf_action = {'ctrl-t':'tab split','ctrl-s':'split','ctrl-v':'vsplit' }

" commentary
map <silent> <leader>/ :Commentary<enter>

" undotree
if has("persistent_undo")
  set undodir=~/.vim/tmp/undodir
  set undofile
  nnoremap <silent> <leader>u :UndotreeToggle<enter>
endif

" git-gutter
nnoremap <silent> gp :GitGutterPreviewHunk<enter>
nnoremap <silent> g. :GitGutterToggle<enter>

let g:gitgutter_enabled = 0
let g:gitgutter_sign_added = '|'
let g:gitgutter_sign_modified = '|'
let g:gitgutter_sign_removed = '|'
let g:gitgutter_sign_removed_first_line = '|'
let g:gitgutter_sign_removed_above_and_below = '|'
let g:gitgutter_sign_modified_removed = '|'

" rooter
let g:rooter_targets = '/,*'
let g:rooter_silent_chdir = 1

" fugitive
nnoremap <silent> gs :Git<enter>
nnoremap <silent> gb :Git blame<enter>
nnoremap <silent> gl :Commits<enter>

" vim-rust
let g:rustfmt_autosave = 1
let g:rustfmt_emit_files = 1
let g:rustfmt_fail_silently = 0
let g:rust_clip_command = 'xclip -selection clipboard'

" tmux
if exists('$TMUX')
  nnoremap <silent> <leader><leader><enter> :silent !tmux clear-history -t right && tmux send-keys -t \! C-l Up Enter<cr>
endif

" nvim-lsp
nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gr <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>
inoremap <silent> <C-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> <leader>rn    <cmd>lua vim.lsp.buf.rename()<CR>
nnoremap <silent> <leader>ee    <cmd>lua vim.diagnostic.show_line_diagnostics()<CR>
nnoremap <silent> <leader>se    <cmd>lua vim.diagnostic.goto_next { wrap = true }<CR>

let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_virtual_text_prefix = ' '

lua << END
local signs = {
    { name = "DiagnosticSignError", text = "" },
    { name = "DiagnosticSignWarn", text = "" },
    { name = "DiagnosticSignHint", text = "" },
    { name = "DiagnosticSignInfo", text = "" },
  }

for _, sign in ipairs(signs) do
	vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
end

local lsp_status = require('lsp-status')
lsp_status.config({
  kind_labels = vim.g.completion_customize_lsp_label,
  current_function = false,
  spinner_frames = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' },
})
lsp_status.register_progress()

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local on_attach_vim = function(client)
    --require'completion'.on_attach(client)
    lsp_status.on_attach(client)
    capabilities = lsp_status.capabilities
end

require('nvim-lsp-installer').on_server_ready(function(server)
	local opts = {
		on_attach = on_attach_vim,
    capabilities = capabilities
	}
	server:setup(opts)
end)
END

" impatient
lua << END
local impatient = require('impatient')
impatient.enable_profile()
END

" bqf
hi BqfPreviewBorder guifg=#50a14f ctermfg=71
hi link BqfPreviewRange Search

lua << END
local status_ok, bqf = pcall(require, "nvim-tree")
if not status_ok then
  return
end

bqf.setup({
    auto_enable = true,
    auto_resize_height = true, -- highly recommended enable
    preview = {
        win_height = 12,
        win_vheight = 12,
        delay_syntax = 80,
        border_chars = {'┃', '┃', '━', '━', '┏', '┓', '┗', '┛', '█'},
        should_preview_cb = function(bufnr)
            local ret = true
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            local fsize = vim.fn.getfsize(bufname)
            if fsize > 100 * 1024 then
                -- skip file size greater than 100k
                ret = false
            elseif bufname:match('^fugitive://') then
                -- skip fugitive buffer
                ret = false
            end
            return ret
        end
    },
    -- make `drop` and `tab drop` to become preferred
    func_map = {
        drop = 'o',
        openc = '<CR>',
        split = '<C-s>',
        tabdrop = '<C-t>',
        tabc = '',
        ptogglemode = 'z,',
    },
    filter = {
        fzf = {
            action_for = {['ctrl-s'] = 'split', ['ctrl-t'] = 'tab drop'},
            extra_opts = {'--bind', 'ctrl-o:toggle-all', '--prompt', '> '}
        }
    }
})
END

" nvim-cmp
set completeopt=menu,menuone,noselect

lua <<EOF
  local cmp = require('cmp')

  kind_icons = {
    Text = "",
    Method = "",
    Function = "",
    Constructor = "",
    Field = "",
    Variable = "",
    Class = "ﴯ",
    Interface = "",
    Module = "",
    Property = "ﰠ",
    Unit = "",
    Value = "",
    Enum = "",
    Keyword = "",
    Snippet = "",
    Color = "",
    File = "",
    Reference = "",
    Folder = "",
    EnumMember = "",
    Constant = "",
    Struct = "",
    Event = "",
    Operator = "",
    TypeParameter = "",
  }

  local luasnip = require('luasnip')

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
            luasnip.lsp_expand(args.body)
      end,
    },

    formatting = {
        fields = { "abbr", "kind", "menu" },
        format = function(entry, vim_item)
          -- Kind icons
          vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
          return vim_item
        end
    },

    mapping = {
      ['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
      ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
      ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
      ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
      ['<C-e>'] = cmp.mapping({
        i = cmp.mapping.abort(),
        c = cmp.mapping.close(),
      }),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      ['<Tab>'] = cmp.mapping.select_next_item(),
      ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    },
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
      { name = 'buffer' },
    })
  })

  -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline('/', {
    sources = {
      { name = 'buffer' }
    }
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })

EOF

" filetype
lua << END
require("filetype").setup({
    overrides = {
        extensions = {
            pn = "potion",
        },
        literal = {
            MyBackupFile = "lua",
        },
        complex = {
            [".*git/config"] = "gitconfig", -- Included in the plugin
        },

        function_extensions = {
            ["cpp"] = function()
                vim.bo.filetype = "cpp"
                vim.bo.cinoptions = vim.bo.cinoptions .. "L0"
            end,
            ["pdf"] = function()
                vim.bo.filetype = "pdf"
                vim.fn.jobstart(
                    "open -a skim " .. '"' .. vim.fn.expand("%") .. '"'
                )
            end,
        },
        function_literal = {
            Brewfile = function()
                vim.cmd("syntax off")
            end,
        },
        function_complex = {
            ["*.math_notes/%w+"] = function()
                vim.cmd("iabbrev $ $$")
            end,
        },

        shebang = {
            dash = "sh",
        },
    },
})
END

" nvim-tree
nnoremap <silent> <c-n> :NvimTreeToggle<enter>
lua << END
vim.g.nvim_tree_icons = {
  default = "",
  symlink = "",
  git = {
    unstaged = "",
    staged = "S",
    unmerged = "",
    renamed = "➜",
    deleted = "",
    untracked = "U",
    ignored = "◌",
  },
  folder = {
    default = "",
    open = "",
    empty = "",
    empty_open = "",
    symlink = "",
  },
}

local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  return
end

local config_status_ok, nvim_tree_config = pcall(require, "nvim-tree.config")
if not config_status_ok then
  return
end

local tree_cb = nvim_tree_config.nvim_tree_callback

require('nvim-tree').setup {
  disable_netrw = true,
  hijack_netrw = true,
  open_on_setup = false,
  ignore_ft_on_setup = {
    "startify",
    "dashboard",
    "alpha",
  },
  auto_close = true,
  open_on_tab = false,
  hijack_cursor = false,
  update_cwd = true,
  diagnostics = {
    enable = false,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  system_open = {
    cmd = nil,
    args = {},
  },
  filters = {
    dotfiles = false,
    custom = {},
  },
  view = {
    width = 30,
    height = 30,
    hide_root_folder = false,
    side = "left",
    auto_resize = true,
    mappings = {
      custom_only = false,
      list = {
        { key = { "l", "<CR>", "o" }, cb = tree_cb "edit" },
        { key = { "h", "<BS>" }, cb = tree_cb "close_node" },
        { key = "h", cb = tree_cb "close_node" },
        { key = "<C-v>", cb = tree_cb "vsplit" },
        { key = "<C-s>", cb = tree_cb "split" },
      },
    },
    number = false,
    relativenumber = false,
  },
  trash = {
    cmd = "trash",
    require_confirm = true,
  },
  quit_on_open = 1,
  git_hl = 1,
  disable_window_picker = 1,
  root_folder_modifier = ":t",
  show_icons = {
    git = 1,
    folders = 1,
    files = 1,
    folder_arrows = 1,
    tree_width = 30,
  },
}
END
