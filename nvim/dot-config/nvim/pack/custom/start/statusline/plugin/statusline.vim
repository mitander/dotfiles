augroup Statusline
	autocmd!
	autocmd WinEnter,BufWinEnter * call SetStatusline()
augroup END

function! SetStatusline()
	let alt_filetypes = ['help', 'fugitive', 'gitcommit']
	if index(alt_filetypes, &filetype) != -1
		setlocal statusline=%!MinimalStatusline()
	else
		setlocal statusline=%!DefaultStatusline()
	endif
endfunction

function! DefaultStatusline()
	let statusline = "  %f %{Modifiable()}%{Modified()}%{GitBranch()}%= "
	" let statusline .= "%{Linter()}%{Longlines()}%l,%c | %p%% %{Filetype()}"
	let statusline .= "%{Longlines()}%l,%c | %p%% %{Filetype()}"
	return statusline
endfunction

function! MinimalStatusline()
	return "  %f%=%l,%c | %p%% %{Filetype()}"
endfunction

function! Modifiable()
	return &modifiable ? "" : " "
endfunctio

function! Modified()
	return &modified ? "|  modified " : ""
endfunction

function! Filetype()
	return &filetype == "" ? "| - " : "| ".&filetype." "
endfunction

function! GitBranch()
	let branch = fugitive#head()
	return branch == "" ? "" : "|  ".branch.""
endfunction

function! Longlines()
	let thresold = &textwidth ? &textwidth : 80
	let spaces = repeat(" ", &ts)
	let long_lines = []
	let i = 0
	while i <= line("$")
		let len = strlen(substitute(getline(i), "\t", spaces, "g"))
		if len > thresold | call add(long_lines, i) | endif
		let i += 1
	endwhile
	if len(long_lines) > 0
		return printf(" %d (ln %d) | ", len(long_lines), min(long_lines))
	else
		return ""
	endif
endfunction

function! Linter()
	let counts = ale#statusline#Count(bufnr(""))
	if counts.total <= 0 | return "" | endif
	let error_count = counts.error + counts.style_error
	let warning_count = counts.total - error_count
	let error_string = error_count <= 0 ? '' : "﯇ " . error_count
	let warning_string = warning_count <= 0 ? '' : "喝" . warning_count
	let delimiter = warning_count > 0 && error_count > 0 ? " " : ""
	return warning_string . delimiter . error_string . " | "
endfunction
