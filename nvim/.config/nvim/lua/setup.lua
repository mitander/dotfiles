-- nvim-lsp
local nvim_lsp = require('lspconfig')
local cap = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local srv = { 'zls', 'rls', 'ccls', 'gopls', 'tsserver' }

for _, lsp in ipairs(srv) do
	nvim_lsp[lsp].setup {
		capabilities = cap,
    	flags = {
			debounce_text_changes = 150,
		}
	}
end

-- cmp
local cmp = require('cmp')
cmp.setup {
	snippet = { expand = function(args) vim.fn["UltiSnips#Anon"](args.body) end },
	sources = cmp.config.sources({{ name = 'nvim_lsp' },{ name = 'buffer' }}),
	mapping = {
		['<C-u>'] = cmp.mapping.scroll_docs((-4), { 'i', 'c' }),
		['<C-d>'] = cmp.mapping.scroll_docs((4), { 'i', 'c' }),
		['<CR>'] = cmp.mapping.confirm({ select = false }),
	}
}

-- treesitter
local ts = require('nvim-treesitter.configs')
ts.setup {
	ensure_installed = 'maintained',
	highlight = {enable = true}
}

-- gitsigns
local gs = require('gitsigns')
gs.setup({
	signs = {
		add          = {hl = 'GitSignsAdd'   , text = '│', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'},
		change       = {hl = 'GitSignsChange', text = '│', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
		delete       = {hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
		topdelete    = {hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
		changedelete = {hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
	},
	signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
	numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
  	linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
  	word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
  	keymaps = {
    	noremap = true,

		['n ]c'] = { expr = true, "&diff ? ']c' : '<cmd>lua require\"gitsigns.actions\".next_hunk()<CR>'"},
		['n [c'] = { expr = true, "&diff ? '[c' : '<cmd>lua require\"gitsigns.actions\".prev_hunk()<CR>'"},

		['n <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
		['v <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk({vim.fn.line("."), vim.fn.line("v")})<CR>',
		['n <leader>hu'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
		['n <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
		['v <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk({vim.fn.line("."), vim.fn.line("v")})<CR>',
		['n <leader>hR'] = '<cmd>lua require"gitsigns".reset_buffer()<CR>',
		['n <leader>hp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
		['n <leader>hb'] = '<cmd>lua require"gitsigns".blame_line(true)<CR>',
		['n <leader>hS'] = '<cmd>lua require"gitsigns".stage_buffer()<CR>',
		['n <leader>hU'] = '<cmd>lua require"gitsigns".reset_buffer_index()<CR>',

		-- Text objects
		['o ih'] = ':<C-U>lua require"gitsigns.actions".select_hunk()<CR>',
		['x ih'] = ':<C-U>lua require"gitsigns.actions".select_hunk()<CR>'
	},
	watch_gitdir = {
		interval = 1000,
		follow_files = true
	},
	attach_to_untracked = true,
	current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
	current_line_blame_opts = {
	virt_text = true,
	virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
	delay = 1000,
	},
	current_line_blame_formatter_opts = {
		relative_time = false
	},
	sign_priority = 6,
	update_debounce = 100,
	status_formatter = nil, -- Use default
	max_file_length = 40000,
	preview_config = {
	-- Options passed to nvim_open_win
	border = 'single',
	style = 'minimal',
	relative = 'cursor',
	row = 0,
	col = 1
	},
	yadm = {
		enable = false
	}
})
