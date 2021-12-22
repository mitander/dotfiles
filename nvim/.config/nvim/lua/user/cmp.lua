local status_ok, cmp = pcall(require, "cmp")
if not status_ok then
  print("failed to load cmp")
  return
end

cmp.setup {
	sources = cmp.config.sources({{ name = 'nvim_lsp' },{ name = 'buffer' }}),
	mapping = {
        ["<C-k>"] = cmp.mapping.select_prev_item(),
		["<C-j>"] = cmp.mapping.select_next_item(),
		['<C-u>'] = cmp.mapping.scroll_docs((-4), { 'i', 'c' }),
		['<C-d>'] = cmp.mapping.scroll_docs((4), { 'i', 'c' }),
		['<CR>'] = cmp.mapping.confirm({ select = false }),
	}
}
