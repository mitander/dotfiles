-- Visual fixture, in a separate editor: nvim --clean -c 'lua dofile("tests/nvim-devicons-preview.lua")'
-- Uses installed devicons and the real provider highlights, not hand-colored icon approximations.
-- Tab changes palette, ]/[ changes page. FLUME_ICON_PAGE selects a page for capture.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local plugins = vim.env.FLUME_ICON_PLUGINS or (vim.fn.stdpath("data") .. "/lazy")
vim.opt.runtimepath:prepend(root .. "/nvim/.config/nvim")
vim.opt.runtimepath:prepend(vim.env.FLUME_RUNTIME or (root .. "/themes/flume"))
vim.opt.runtimepath:append(plugins .. "/nvim-web-devicons")
local provider = require("nvim-web-devicons")
provider.setup({ variant = "dark" })
require("mitander.icon_colors").setup(provider)
local flume = require("flume")
local schemas = { "dusk", "opal", "mira", "mesa" }
local schema = vim.fn.index(schemas, vim.env.FLUME_SCHEMA or "opal") + 1
assert(schema > 0, "unknown FLUME_SCHEMA")
local page = tonumber(vim.env.FLUME_ICON_PAGE) or 1
local columns, rows = 4, 30
local page_size = columns * rows
local icons, records = provider.get_icons(), {}
local by_name = {}
local keys = vim.tbl_keys(icons)
table.sort(keys, function(a, b)
    return tostring(a) < tostring(b)
end)
for _, key in ipairs(keys) do
    local icon = icons[key]
    if not by_name[icon.name] then
        local glyph, highlight = provider.get_icon(tostring(key), tostring(key), { default = true })
        assert(glyph == icon.icon, "fixture lookup changed glyph: " .. tostring(key))
        by_name[icon.name] = { name = icon.name, glyph = glyph, highlight = highlight }
    end
end
-- Put a mixed, everyday file list before the complete alphabetical inventory.
local common = {
    "Rs",
    "Py",
    "Go",
    "Lua",
    "TypeScript",
    "Js",
    "Zig",
    "Gleam",
    "C",
    "Cpp",
    "Java",
    "Cs",
    "Swift",
    "Kotlin",
    "Rb",
    "Ex",
    "Hs",
    "Nix",
    "Jsx",
    "Tsx",
    "Html",
    "Css",
    "Sass",
    "Vue",
    "Svelte",
    "Sh",
    "Fish",
    "Toml",
    "Yaml",
    "Json",
    "Md",
    "Readme",
    "Txt",
    "Sql",
    "Db",
    "Csv",
    "Png",
    "Svg",
    "Psd",
    "Mp4",
    "MPEGAudioLayerIII",
    "Zip",
    "TrueTypeFont",
    "Dockerfile",
    "Makefile",
    "PackageJson",
    "PackageLockJson",
    "Lock",
    "Exe",
    "Dll",
}
for _, name in ipairs(common) do
    records[#records + 1] = assert(by_name[name], "missing common identity: " .. name)
    by_name[name] = nil
end
for _, name in ipairs(vim.fn.sort(vim.tbl_keys(by_name))) do
    records[#records + 1] = by_name[name]
end
local pages = math.ceil(#records / page_size)
assert(page >= 1 and page <= pages and page == math.floor(page), "invalid FLUME_ICON_PAGE")
local buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buffer)
vim.bo[buffer].buftype = "nofile"
vim.bo[buffer].bufhidden = "wipe"
vim.bo[buffer].swapfile = false
vim.o.termguicolors = true
vim.o.laststatus = 0
vim.o.showmode = false
vim.o.showcmd = false
vim.o.ruler = false
vim.wo.number = false
vim.wo.relativenumber = false
vim.wo.signcolumn = "no"
vim.wo.wrap = false
vim.wo.cursorline = true

local function render()
    flume.setup({ schema = schemas[schema], watch_sync = false, follow_sync = false, dev = false })
    local lines = {
        string.format(
            " File icon audit | %s | %d identities | page %d/%d",
            schemas[schema],
            #records,
            page,
            pages
        ),
        " Tab: palette   ]/[: page   q: quit   |   actual provider glyphs and highlights",
        "",
    }
    local spans = {}
    local width = math.floor(vim.o.columns / columns)
    for row = 1, rows do
        local line = ""
        for column = 1, columns do
            local index = (page - 1) * page_size + (column - 1) * rows + row
            local icon = records[index]
            if icon then
                local label = icon.name
                if #label > width - 5 then
                    label = label:sub(1, width - 8) .. "..."
                end
                local start = #line + 1
                local text = " " .. icon.glyph .. " " .. label
                line = line
                    .. text
                    .. string.rep(" ", math.max(0, width - vim.fn.strdisplaywidth(text)))
                spans[#spans + 1] = {
                    row = #lines,
                    start = start,
                    finish = start + #icon.glyph,
                    group = icon.highlight,
                }
            end
        end
        lines[#lines + 1] = line
    end
    vim.bo[buffer].modifiable = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(buffer, -1, 0, -1)
    for _, span in ipairs(spans) do
        vim.api.nvim_buf_add_highlight(buffer, -1, span.group, span.row, span.start, span.finish)
    end
    vim.api.nvim_buf_add_highlight(buffer, -1, "Title", 0, 0, -1)
    vim.api.nvim_buf_add_highlight(buffer, -1, "Comment", 1, 0, -1)
    vim.bo[buffer].modifiable = false
    vim.bo[buffer].modified = false
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    vim.cmd("redraw!")
end

for key, delta in pairs({ ["]"] = 1, ["["] = -1 }) do
    vim.keymap.set("n", key, function()
        page = (page - 1 + delta) % pages + 1
        render()
    end, { buffer = buffer })
end
vim.keymap.set("n", "<Tab>", function()
    schema = schema % #schemas + 1
    render()
end, { buffer = buffer })
vim.keymap.set("n", "q", "<Cmd>quit<CR>", { buffer = buffer })
render()
