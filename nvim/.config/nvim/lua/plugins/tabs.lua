local fn = vim.fn
--require("plugins.mappings").tabline()

local options = {
	show_index = true,
	show_modify = true,
	show_filename = false,
	show_cwd = false,
	modify_indicator = "~",
	empty_name = "scratch",
	separators = { left = "", right = "" },
	index_separators = { left = " ", right = " " },
}

local winlist = {}

local function tabline(opts)
	local str = " "
	for index = 1, fn.tabpagenr("$") do
		local winnr = fn.tabpagewinnr(index)
		local blist = fn.tabpagebuflist(index)
		local bnr = blist[winnr]
		local bname = fn.bufname(bnr)
		local modified = fn.getbufvar(bnr, "&mod")

		str = str .. "%" .. index .. "T"

		if index == fn.tabpagenr() then
			str = str .. "%#TabLineSel# "
		else
			str = str .. "%#TabLine# "
		end

		if opts.show_index then
			str = str .. opts.index_separators.left .. index .. opts.index_separators.right
		end

		if opts.show_filename and not opts.show_cwd then
			if bname ~= "" then
				str = str .. opts.separators.left .. fn.fnamemodify(bname, ":t") .. opts.separators.right
			else
				str = str .. opts.empty_name
			end
			if modified == 1 and opts.show_modify and opts.modify_indicator ~= nil and bname ~= "" then
				str = str .. opts.modify_indicator
			end
		end

		if opts.show_cwd then
			if index == fn.tabpagenr() then
				local idx = 0
				local res = {}
				local cwd = fn.getcwd(winnr, index)

				for s in string.gmatch(cwd, "[^" .. "/" .. "]+") do
					res[idx] = s
					idx = idx + 1
				end

				winlist[index] = res[#res]
				str = str .. winlist[index]
			else
				if winlist[index] == nil then
					print("NULL")
				else
					str = str .. winlist[index]
				end
			end
		end
		str = str .. " "
	end

	str = str .. "%#TabLineFill#"
	return str
end

function _G.tabline()
	return tabline(options)
end

vim.o.tabline = "%!v:lua.tabline()"
vim.o.showtabline = 1
